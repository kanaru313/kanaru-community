//! The call from the JS thread to whoever answers fetches and streams (the
//! app in production, a closure in tests), with a wait that honours the
//! cancel flag and the job deadline.
//!
//! The host returns a future. For the app that is a future that completes when
//! the app replies, from another thread. The JS thread polls it itself and
//! parks between polls, so no async runtime is needed and no bridge worker
//! blocks. The thread is woken by the future (via `Wake`) or after
//! [`CANCEL_POLL`], whichever comes first.
// The fetch and stream natives are the callers; until they are ported only
// the tests call `ask`.
#![cfg_attr(
    not(test),
    expect(dead_code, reason = "called by the fetch and stream natives")
)]

use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::task::{Context, Poll, Wake, Waker};
use std::thread;
use std::time::Instant;

use super::late::LateDrain;
use super::quiet::quietly;
use crate::limits::CANCEL_POLL;
use crate::types::Pending;

/// How the wait for an answer ended.
pub enum Waited<T> {
    Answer(T),
    Cancelled,
    DeadlinePassed,
    /// The call or its future panicked (the app threw): treat as `network`.
    Failed,
}

struct UnparkWaker(thread::Thread);

impl Wake for UnparkWaker {
    fn wake(self: Arc<Self>) {
        self.0.unpark();
    }
}

/// Calls `call` and blocks the calling thread until the future completes,
/// `cancel` is set or `deadline` passes. An unfinished future that was polled
/// is handed to the late-answers drain `late`, not dropped.
pub fn ask<T: Send + 'static>(
    call: impl FnOnce() -> Pending<T>,
    cancel: &AtomicBool,
    deadline: Instant,
    late: &LateDrain,
) -> Waited<T> {
    let Some(mut future) = quietly(call) else {
        return Waited::Failed;
    };
    let waker = Waker::from(Arc::new(UnparkWaker(thread::current())));
    let mut cx = Context::from_waker(&waker);
    let mut polled = false;
    loop {
        if cancel.load(Ordering::SeqCst) {
            if polled {
                late.hand_over(future);
            } else {
                // Never polled: the call has not started and no reply channel
                // exists, so dropping is safe and starts nothing.
                let _ = quietly(|| drop(future));
            }
            return Waited::Cancelled;
        }
        polled = true;
        match quietly(|| Future::poll(future.as_mut(), &mut cx)) {
            None => {
                // A future that panicked is finished; never poll it again,
                // and leak it rather than run its destructor.
                std::mem::forget(future);
                return Waited::Failed;
            }
            Some(Poll::Ready(answer)) => return Waited::Answer(answer),
            Some(Poll::Pending) => {}
        }
        let now = Instant::now();
        if now >= deadline {
            late.hand_over(future);
            return Waited::DeadlinePassed;
        }
        thread::park_timeout(CANCEL_POLL.min(deadline - now));
    }
}

#[cfg(test)]
mod tests {
    use std::pin::Pin;
    use std::sync::atomic::AtomicUsize;
    use std::time::Duration;

    use super::*;
    use crate::host::failed_response;
    use crate::types::{FetchOutcome, FetchResponse};

    fn drain() -> LateDrain {
        LateDrain::new(None)
    }

    fn ready() -> Pending<FetchResponse> {
        Box::pin(async { failed_response(FetchOutcome::Network) })
    }

    #[test]
    fn a_ready_future_answers() {
        let cancel = AtomicBool::new(false);
        match ask(
            ready,
            &cancel,
            Instant::now() + Duration::from_secs(5),
            &drain(),
        ) {
            Waited::Answer(r) => assert_eq!(r.outcome, FetchOutcome::Network),
            _ => panic!("expected an answer"),
        }
    }

    #[test]
    fn a_pending_future_ends_at_the_deadline_or_on_cancel() {
        let late = drain();
        let cancel = AtomicBool::new(false);
        let pending = || -> Pending<FetchResponse> { Box::pin(std::future::pending()) };
        let started = Instant::now();
        assert!(matches!(
            ask(
                pending,
                &cancel,
                started + Duration::from_millis(120),
                &late
            ),
            Waited::DeadlinePassed
        ));
        assert!(started.elapsed() < Duration::from_secs(5));

        cancel.store(true, Ordering::SeqCst);
        assert!(matches!(
            ask(
                pending,
                &cancel,
                Instant::now() + Duration::from_secs(60),
                &late
            ),
            Waited::Cancelled
        ));
    }

    #[test]
    fn a_cancel_before_the_first_poll_drops_the_lazy_future_unpolled() {
        struct Lazy(Arc<AtomicUsize>, Arc<AtomicBool>);
        impl Future for Lazy {
            type Output = FetchResponse;
            fn poll(self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<Self::Output> {
                self.0.fetch_add(1, Ordering::SeqCst);
                Poll::Pending
            }
        }
        impl Drop for Lazy {
            fn drop(&mut self) {
                self.1.store(true, Ordering::SeqCst);
            }
        }
        let (polls, dropped) = (
            Arc::new(AtomicUsize::new(0)),
            Arc::new(AtomicBool::new(false)),
        );
        let (p, d) = (polls.clone(), dropped.clone());
        let cancel = AtomicBool::new(true);
        let late = drain();
        assert!(matches!(
            ask(
                move || -> Pending<FetchResponse> { Box::pin(Lazy(p, d)) },
                &cancel,
                Instant::now() + Duration::from_secs(60),
                &late
            ),
            Waited::Cancelled
        ));
        assert!(dropped.load(Ordering::SeqCst), "dropped on the spot");
        thread::sleep(Duration::from_millis(300));
        assert_eq!(
            polls.load(Ordering::SeqCst),
            0,
            "never polled, not even by the drain"
        );
    }

    #[test]
    fn a_panicking_call_or_poll_is_a_failure() {
        let cancel = AtomicBool::new(false);
        let end = Instant::now() + Duration::from_secs(5);
        let late = drain();
        assert!(matches!(
            ask(
                || -> Pending<FetchResponse> { panic!("the app threw") },
                &cancel,
                end,
                &late
            ),
            Waited::Failed
        ));
        assert!(matches!(
            ask(
                || -> Pending<FetchResponse> {
                    Box::pin(async { panic!("the app threw in poll") })
                },
                &cancel,
                end,
                &late
            ),
            Waited::Failed
        ));
    }

    #[test]
    fn any_reply_type_is_answered() {
        let cancel = AtomicBool::new(false);
        let end = Instant::now() + Duration::from_secs(5);
        match ask(
            || -> Pending<u32> { Box::pin(async { 7 }) },
            &cancel,
            end,
            &drain(),
        ) {
            Waited::Answer(n) => assert_eq!(n, 7),
            _ => panic!("expected an answer"),
        }
    }

    #[test]
    fn a_future_still_pending_at_the_deadline_goes_to_the_drain_not_the_bin() {
        let cancel = AtomicBool::new(false);
        let late = drain();
        let dropped = Arc::new(AtomicBool::new(false));
        struct Forever(Arc<AtomicBool>);
        impl Future for Forever {
            type Output = u8;
            fn poll(self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<u8> {
                Poll::Pending
            }
        }
        impl Drop for Forever {
            fn drop(&mut self) {
                self.0.store(true, Ordering::SeqCst);
            }
        }
        let flag = dropped.clone();
        let outcome = ask(
            move || -> Pending<u8> { Box::pin(Forever(flag)) },
            &cancel,
            Instant::now() + Duration::from_millis(60),
            &late,
        );
        assert!(matches!(outcome, Waited::DeadlinePassed));
        thread::sleep(Duration::from_millis(150));
        assert!(!dropped.load(Ordering::SeqCst), "kept alive by the drain");
        assert!(late.close(Instant::now() + Duration::from_secs(5)));
        assert!(
            !dropped.load(Ordering::SeqCst),
            "forgotten at close, never dropped"
        );
    }
}
