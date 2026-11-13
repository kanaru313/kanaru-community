//! The late-answers drain of one runtime: a thread that polls the futures of
//! host calls a script stopped waiting for (cancel, deadline), so the host
//! can finish and release what it holds. The answers are discarded.
//!
//! A future is never dropped here once it has been polled: dropping a future
//! the app's side still drives could run its destructor on the wrong thread.
//! A future the drain gives up on (cap, age, shutdown, panic) is forgotten.

use std::future::Future;
use std::mem;
use std::pin::Pin;
use std::sync::mpsc::{self, RecvTimeoutError, Sender};
use std::sync::{Mutex, MutexGuard};
use std::task::{Context, Poll, Waker};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};

use super::quiet::quietly;
use crate::limits::{MAX_OP_GRACE, MAX_STREAM_IDLE, MAX_WALL_TIME};
use crate::pool::{join_until, run_thread_start, ThreadStartHook};
use crate::types::Pending;

/// Most abandoned futures the drain thread waits on at once.
pub const MAX_LATE: usize = 256;
/// Longest the drain thread waits for one abandoned future. A fetch deadline
/// is at most the job's remaining wall time, so at most `MAX_WALL_TIME`
/// (90 s) plus the grace of a streaming run (`MAX_OP_GRACE`); a stream read
/// waits at most `MAX_STREAM_IDLE` plus the same grace. Both are below this,
/// and a reply after this is not expected.
pub const MAX_LATE_AGE: Duration = Duration::from_secs(120);
const _: () = assert!(
    MAX_LATE_AGE.as_secs() > MAX_WALL_TIME.as_secs() + MAX_OP_GRACE.as_secs()
        && MAX_LATE_AGE.as_secs() > MAX_STREAM_IDLE.as_secs() + MAX_OP_GRACE.as_secs()
);
const LATE_POLL: Duration = Duration::from_millis(50);
/// Name of the drain thread.
pub const THREAD_NAME: &str = "plugin-late-answers";

/// An abandoned future with its answer type erased: the drain only needs to
/// know when it finishes.
type Erased = Pin<Box<dyn Future<Output = ()> + Send>>;

/// Maps the output of the wrapped future to `()`. Hand-written (no `async`
/// block) so that a panic in the inner poll unwinds straight through
/// `Discard::poll` into the drain's `quietly`, and the drain can forget the
/// wrapper without dropping the inner future.
struct Discard<T>(Pending<T>);

impl<T> Future for Discard<T> {
    type Output = ();

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<()> {
        match self.0.as_mut().poll(cx) {
            Poll::Ready(_) => Poll::Ready(()),
            Poll::Pending => Poll::Pending,
        }
    }
}

struct Late {
    future: Erased,
    since: Instant,
}

enum State {
    /// No future was handed over yet; the thread starts on the first one.
    Idle,
    Running {
        tx: Sender<Late>,
        thread: JoinHandle<()>,
    },
    /// Closed for good: every future handed over is forgotten.
    Closed,
}

/// Owns the drain thread. Dropping it, or [`LateDrain::close`], ends the
/// thread, which forgets whatever it still waits on.
pub struct LateDrain {
    max_late: usize,
    max_age: Duration,
    on_start: Option<ThreadStartHook>,
    state: Mutex<State>,
    /// Test hook: how often a script called `__testReady()`, so a test can
    /// wait until a script is really running instead of sleeping.
    #[cfg(feature = "test-hooks")]
    ready: std::sync::atomic::AtomicUsize,
}

impl LateDrain {
    /// Test hook behind the script global `__testReady`.
    #[cfg(feature = "test-hooks")]
    pub fn mark_ready(&self) {
        self.ready.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
    }

    /// Scripts that called `__testReady()` so far.
    #[cfg(test)]
    pub fn ready_count(&self) -> usize {
        self.ready.load(std::sync::atomic::Ordering::SeqCst)
    }

    /// A drain with the documented caps; its thread starts on first use.
    pub fn new(on_start: Option<ThreadStartHook>) -> Self {
        Self::with_limits(MAX_LATE, MAX_LATE_AGE, on_start)
    }

    /// A drain with its own caps (tests shorten them).
    pub fn with_limits(
        max_late: usize,
        max_age: Duration,
        on_start: Option<ThreadStartHook>,
    ) -> Self {
        Self {
            max_late,
            max_age,
            on_start,
            state: Mutex::new(State::Idle),
            #[cfg(feature = "test-hooks")]
            ready: std::sync::atomic::AtomicUsize::new(0),
        }
    }

    fn lock(&self) -> MutexGuard<'_, State> {
        self.state.lock().unwrap_or_else(|e| e.into_inner())
    }

    /// Gives an unfinished future to the drain thread. When the drain is
    /// closed or its thread cannot run, the future is forgotten.
    pub fn hand_over<T: Send + 'static>(&self, future: Pending<T>) {
        let late = Late {
            future: Box::pin(Discard(future)),
            since: Instant::now(),
        };
        let mut state = self.lock();
        if matches!(*state, State::Idle) {
            let (tx, rx) = mpsc::channel::<Late>();
            let (max_late, max_age) = (self.max_late, self.max_age);
            let on_start = self.on_start.clone();
            let spawned = thread::Builder::new()
                .name(THREAD_NAME.to_owned())
                .spawn(move || {
                    run_thread_start(&on_start, THREAD_NAME);
                    drain_late(rx, max_late, max_age);
                });
            if let Ok(thread) = spawned {
                *state = State::Running { tx, thread };
            }
        }
        match &*state {
            State::Running { tx, .. } => {
                if let Err(mpsc::SendError(late)) = tx.send(late) {
                    mem::forget(late.future);
                }
            }
            _ => mem::forget(late.future),
        }
    }

    /// Closes the drain and waits for its thread until `deadline`: the thread
    /// forgets every future it still holds, then ends. Unfinished at the
    /// deadline, the thread is left to end on its own; false then.
    pub fn close(&self, deadline: Instant) -> bool {
        let previous = mem::replace(&mut *self.lock(), State::Closed);
        match previous {
            State::Running { tx, thread } => {
                drop(tx);
                join_until(thread, deadline)
            }
            _ => true,
        }
    }
}

impl Drop for LateDrain {
    fn drop(&mut self) {
        // Dropping the sender is enough: the thread sees the closed channel,
        // forgets what it holds and ends. No join in a destructor.
        *self.lock() = State::Closed;
    }
}

/// Polls abandoned futures until they finish; the answers are discarded.
fn drain_late(rx: mpsc::Receiver<Late>, max_late: usize, max_age: Duration) {
    let waker = Waker::noop();
    let mut cx = Context::from_waker(waker);
    let mut waiting: Vec<Late> = Vec::new();
    let accept = |waiting: &mut Vec<Late>, late: Late| {
        if waiting.len() >= max_late {
            mem::forget(late.future);
        } else {
            waiting.push(late);
        }
    };
    loop {
        let wait = if waiting.is_empty() {
            Duration::from_secs(3600)
        } else {
            LATE_POLL
        };
        match rx.recv_timeout(wait) {
            Ok(late) => {
                accept(&mut waiting, late);
                while let Ok(late) = rx.try_recv() {
                    accept(&mut waiting, late);
                }
            }
            Err(RecvTimeoutError::Timeout) => {}
            Err(RecvTimeoutError::Disconnected) => {
                // Closed: never drop a future that may still be driven.
                for late in waiting {
                    mem::forget(late.future);
                }
                return;
            }
        }
        let mut still = Vec::with_capacity(waiting.len());
        for mut late in waiting.drain(..) {
            match quietly(|| Future::poll(late.future.as_mut(), &mut cx)) {
                Some(Poll::Pending) if late.since.elapsed() < max_age => still.push(late),
                Some(Poll::Pending) => mem::forget(late.future),
                // Finished: drop the answer. Panicked: never touch it again.
                Some(Poll::Ready(())) => {}
                None => mem::forget(late.future),
            }
        }
        waiting = still;
    }
}

#[cfg(test)]
mod tests {
    use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
    use std::sync::Arc;

    use super::*;

    /// A future that never finishes and records its polls and its drop.
    struct Probe {
        polls: Arc<AtomicUsize>,
        dropped: Arc<AtomicBool>,
    }

    impl Future for Probe {
        type Output = u8;
        fn poll(self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<u8> {
            self.polls.fetch_add(1, Ordering::SeqCst);
            Poll::Pending
        }
    }

    impl Drop for Probe {
        fn drop(&mut self) {
            self.dropped.store(true, Ordering::SeqCst);
        }
    }

    fn probe() -> (Pending<u8>, Arc<AtomicUsize>, Arc<AtomicBool>) {
        let polls = Arc::new(AtomicUsize::new(0));
        let dropped = Arc::new(AtomicBool::new(false));
        let future = Box::pin(Probe {
            polls: polls.clone(),
            dropped: dropped.clone(),
        });
        (future, polls, dropped)
    }

    fn wait_until(what: &str, mut cond: impl FnMut() -> bool) {
        let end = Instant::now() + Duration::from_secs(5);
        while !cond() {
            assert!(Instant::now() < end, "timed out waiting for {what}");
            thread::sleep(Duration::from_millis(5));
        }
    }

    fn soon() -> Instant {
        Instant::now() + Duration::from_secs(5)
    }

    #[test]
    fn a_finished_future_is_polled_to_the_end_and_dropped() {
        let drain = LateDrain::new(None);
        let done = Arc::new(AtomicBool::new(false));
        let flag = done.clone();
        let future: Pending<u8> = Box::pin(async move {
            flag.store(true, Ordering::SeqCst);
            1
        });
        drain.hand_over(future);
        wait_until("the future to run", || done.load(Ordering::SeqCst));
        assert!(drain.close(soon()));
    }

    #[test]
    fn the_257th_future_is_forgotten_not_polled_and_not_dropped() {
        let drain = LateDrain::new(None);
        let mut probes = Vec::new();
        for _ in 0..MAX_LATE + 1 {
            let (future, polls, dropped) = probe();
            drain.hand_over(future);
            probes.push((polls, dropped));
        }
        wait_until("the first futures to be polled", || {
            probes[..MAX_LATE]
                .iter()
                .all(|(polls, _)| polls.load(Ordering::SeqCst) >= 2)
        });
        thread::sleep(3 * LATE_POLL);
        let (over_polls, over_dropped) = &probes[MAX_LATE];
        assert_eq!(
            over_polls.load(Ordering::SeqCst),
            0,
            "over the cap: never polled"
        );
        assert!(
            !over_dropped.load(Ordering::SeqCst),
            "over the cap: forgotten, not dropped"
        );
        assert!(probes[..MAX_LATE]
            .iter()
            .all(|(_, d)| !d.load(Ordering::SeqCst)));
        assert!(drain.close(soon()));
    }

    #[test]
    fn a_future_older_than_the_limit_is_forgotten_not_dropped() {
        let drain = LateDrain::with_limits(4, Duration::from_millis(200), None);
        let (future, polls, dropped) = probe();
        drain.hand_over(future);
        wait_until("the first poll", || polls.load(Ordering::SeqCst) >= 1);
        thread::sleep(Duration::from_millis(400));
        let after_expiry = polls.load(Ordering::SeqCst);
        thread::sleep(3 * LATE_POLL);
        assert_eq!(
            polls.load(Ordering::SeqCst),
            after_expiry,
            "no polls after expiry"
        );
        assert!(!dropped.load(Ordering::SeqCst));
        assert!(drain.close(soon()));
    }

    #[test]
    fn closing_forgets_pending_futures_and_the_thread_ends() {
        let drain = LateDrain::new(None);
        let (future, polls, dropped) = probe();
        drain.hand_over(future);
        wait_until("the first poll", || polls.load(Ordering::SeqCst) >= 1);
        assert!(drain.close(soon()), "the thread joined");
        assert!(
            !dropped.load(Ordering::SeqCst),
            "forgotten on shutdown, never dropped"
        );
        let after_close = polls.load(Ordering::SeqCst);
        thread::sleep(3 * LATE_POLL);
        assert_eq!(polls.load(Ordering::SeqCst), after_close);
    }

    #[test]
    fn a_closed_drain_forgets_what_it_is_given() {
        let drain = LateDrain::new(None);
        assert!(drain.close(soon()));
        let (future, polls, dropped) = probe();
        drain.hand_over(future);
        thread::sleep(2 * LATE_POLL);
        assert_eq!(polls.load(Ordering::SeqCst), 0);
        assert!(!dropped.load(Ordering::SeqCst));
    }

    #[test]
    fn a_future_that_panics_when_polled_is_forgotten_not_dropped() {
        struct Boom(Arc<AtomicBool>, Arc<AtomicBool>);
        impl Future for Boom {
            type Output = u32;
            fn poll(self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<u32> {
                self.1.store(true, Ordering::SeqCst);
                panic!("the app threw in a late poll");
            }
        }
        impl Drop for Boom {
            fn drop(&mut self) {
                self.0.store(true, Ordering::SeqCst);
            }
        }
        let drain = LateDrain::new(None);
        let dropped = Arc::new(AtomicBool::new(false));
        let polled = Arc::new(AtomicBool::new(false));
        drain.hand_over::<u32>(Box::pin(Boom(dropped.clone(), polled.clone())));
        wait_until("the poll", || polled.load(Ordering::SeqCst));
        thread::sleep(Duration::from_millis(100));
        assert!(!dropped.load(Ordering::SeqCst), "forgotten, not dropped");
    }

    #[test]
    fn the_drain_thread_runs_the_start_hook_with_its_name() {
        let names = Arc::new(Mutex::new(Vec::<String>::new()));
        let seen = names.clone();
        let hook: ThreadStartHook = Arc::new(move |name| {
            seen.lock().expect("lock").push(name.to_owned());
        });
        let drain = LateDrain::new(Some(hook));
        assert!(
            names.lock().expect("lock").is_empty(),
            "the thread starts on first use"
        );
        let (future, polls, _dropped) = probe();
        drain.hand_over(future);
        wait_until("the first poll", || polls.load(Ordering::SeqCst) >= 1);
        assert_eq!(*names.lock().expect("lock"), vec![THREAD_NAME.to_owned()]);
        assert!(drain.close(soon()));
    }
}
