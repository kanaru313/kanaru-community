//! A fixed set of worker threads with a bounded queue, and a one-shot result
//! channel an `async fn` can await without any executor dependency.
//!
//! The queue holds only jobs that wait for a worker. A job a free worker is
//! about to take does not count, so a burst never gets `Busy` while workers
//! sit idle. A pool can be stopped: workers leave after the job they run, and
//! the owner joins them with a bound.

use std::collections::VecDeque;
use std::future::Future;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::pin::Pin;
use std::sync::{Arc, Condvar, Mutex, MutexGuard};
use std::task::{Context, Poll, Waker};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};

/// Called first on every thread the runtime starts, with the thread's name, so
/// the owner can set priorities or register the thread.
pub type ThreadStartHook = Arc<dyn Fn(&str) + Send + Sync>;

/// Runs the hook for the current thread. A panicking hook must not take the
/// thread down: its panic is dropped.
pub fn run_thread_start(hook: &Option<ThreadStartHook>, name: &str) {
    if let Some(hook) = hook {
        let _ = catch_unwind(AssertUnwindSafe(|| hook(name)));
    }
}

/// Waits for `handle` to finish until `deadline`; true when it did (and was
/// joined). An unfinished thread is left to end on its own.
pub fn join_until(handle: JoinHandle<()>, deadline: Instant) -> bool {
    while !handle.is_finished() {
        if Instant::now() >= deadline {
            return false;
        }
        thread::sleep(Duration::from_millis(2));
    }
    let _ = handle.join();
    true
}

struct State<J> {
    queue: VecDeque<J>,
    /// Workers currently inside the handler.
    running: usize,
    /// Workers actually started (fewer than asked when a spawn failed).
    threads: usize,
    /// Set by [`Pool::stop`]: workers leave and nothing more is accepted.
    stopped: bool,
}

pub struct Pool<J> {
    state: Mutex<State<J>>,
    wake: Condvar,
    capacity: usize,
    handles: Mutex<Vec<JoinHandle<()>>>,
}

impl<J: Send + 'static> Pool<J> {
    /// Starts `threads` workers named `{name}-{n}` with `stack_bytes` of stack,
    /// each calling `on_start` once and then running `handler` for the jobs it
    /// takes. The handler returns a delivery closure; the worker lowers its
    /// running count first and only then calls it, so a caller that submits
    /// right after seeing a result is never refused for a worker that is about
    /// to be free. A panic in `handler` or in the delivery is caught so the
    /// worker survives. Errors only when no thread could be spawned.
    pub fn start<D: FnOnce()>(
        threads: usize,
        capacity: usize,
        name: &str,
        stack_bytes: usize,
        on_start: Option<ThreadStartHook>,
        handler: impl Fn(J) -> D + Send + Sync + 'static,
    ) -> std::io::Result<Arc<Self>> {
        let pool = Arc::new(Self {
            state: Mutex::new(State {
                queue: VecDeque::new(),
                running: 0,
                threads: 0,
                stopped: false,
            }),
            wake: Condvar::new(),
            capacity,
            handles: Mutex::new(Vec::new()),
        });
        let handler = Arc::new(handler);
        let mut last_error = None;
        for n in 0..threads {
            let (worker_pool, handler, on_start) =
                (pool.clone(), handler.clone(), on_start.clone());
            let thread_name = format!("{name}-{n}");
            let announced = thread_name.clone();
            let result = thread::Builder::new()
                .name(thread_name)
                .stack_size(stack_bytes)
                .spawn(move || {
                    run_thread_start(&on_start, &announced);
                    worker_pool.worker_loop(&*handler);
                });
            match result {
                Ok(handle) => {
                    pool.lock().threads += 1;
                    pool.handles
                        .lock()
                        .unwrap_or_else(|e| e.into_inner())
                        .push(handle);
                }
                Err(e) => last_error = Some(e),
            }
        }
        let spawned = pool.lock().threads;
        match (spawned, last_error) {
            (0, Some(e)) => Err(e),
            _ => Ok(pool),
        }
    }

    fn lock(&self) -> MutexGuard<'_, State<J>> {
        self.state.lock().unwrap_or_else(|e| e.into_inner())
    }

    /// Queues `job`; gives it back when the queue is full or the pool stopped.
    pub fn try_submit(&self, job: J) -> Result<(), J> {
        let mut state = self.lock();
        let idle = state.threads.saturating_sub(state.running);
        if state.stopped || state.queue.len() >= self.capacity + idle {
            return Err(job);
        }
        state.queue.push_back(job);
        self.wake.notify_one();
        Ok(())
    }

    /// Removes and returns every waiting job for which `pred` is true, in
    /// queue order, so cancelled jobs free their slots at once.
    pub fn take_where(&self, mut pred: impl FnMut(&J) -> bool) -> Vec<J> {
        let mut state = self.lock();
        let mut taken = Vec::new();
        let mut kept = VecDeque::with_capacity(state.queue.len());
        for job in state.queue.drain(..) {
            if pred(&job) {
                taken.push(job);
            } else {
                kept.push_back(job);
            }
        }
        state.queue = kept;
        taken
    }

    /// Stops the pool: nothing more is accepted, idle workers wake and leave,
    /// busy ones leave after their job. Returns the jobs that were still
    /// waiting, for the caller to finish.
    pub fn stop(&self) -> Vec<J> {
        let mut state = self.lock();
        state.stopped = true;
        let waiting = state.queue.drain(..).collect();
        self.wake.notify_all();
        waiting
    }

    /// Joins the workers until `deadline`; returns how many did not end in
    /// time (they are left running, detached).
    pub fn join_until(&self, deadline: Instant) -> usize {
        let handles = std::mem::take(&mut *self.handles.lock().unwrap_or_else(|e| e.into_inner()));
        handles
            .into_iter()
            .map(|handle| join_until(handle, deadline))
            .filter(|joined| !joined)
            .count()
    }

    fn worker_loop<D: FnOnce()>(&self, handler: &(impl Fn(J) -> D + ?Sized)) {
        loop {
            let job = {
                let mut state = self.lock();
                loop {
                    if state.stopped {
                        return;
                    }
                    if let Some(job) = state.queue.pop_front() {
                        state.running += 1;
                        break job;
                    }
                    state = self.wake.wait(state).unwrap_or_else(|e| e.into_inner());
                }
            };
            // The handler reports its own panics; this only keeps the thread alive.
            let deliver = catch_unwind(AssertUnwindSafe(|| handler(job)));
            self.lock().running -= 1;
            if let Ok(deliver) = deliver {
                let _ = catch_unwind(AssertUnwindSafe(deliver));
            }
        }
    }

    #[cfg(test)]
    pub fn running(&self) -> usize {
        self.lock().running
    }

    #[cfg(test)]
    pub fn queued(&self) -> usize {
        self.lock().queue.len()
    }
}

// ------------------------------------------------------------- one-shot

struct OneshotState<T> {
    value: Option<T>,
    closed: bool,
    waker: Option<Waker>,
}

/// Sending half; dropping it unsent closes the waiter.
pub struct Completer<T>(Arc<Mutex<OneshotState<T>>>);
/// Awaitable half; resolves to `None` when the sender died without sending.
pub struct Waiter<T>(Arc<Mutex<OneshotState<T>>>);

pub fn completion<T>() -> (Completer<T>, Waiter<T>) {
    let state = Arc::new(Mutex::new(OneshotState {
        value: None,
        closed: false,
        waker: None,
    }));
    (Completer(state.clone()), Waiter(state))
}

impl<T> Completer<T> {
    pub fn send(self, value: T) {
        let mut state = self.0.lock().unwrap_or_else(|e| e.into_inner());
        state.value = Some(value);
        // Drop of `self` wakes the waiter.
    }
}

impl<T> Drop for Completer<T> {
    fn drop(&mut self) {
        let mut state = self.0.lock().unwrap_or_else(|e| e.into_inner());
        state.closed = true;
        if let Some(w) = state.waker.take() {
            w.wake();
        }
    }
}

impl<T> Future for Waiter<T> {
    type Output = Option<T>;
    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<T>> {
        let mut state = self.0.lock().unwrap_or_else(|e| e.into_inner());
        if let Some(v) = state.value.take() {
            return Poll::Ready(Some(v));
        }
        if state.closed {
            return Poll::Ready(None);
        }
        state.waker = Some(cx.waker().clone());
        Poll::Pending
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::mpsc;
    use std::time::{Duration, Instant};

    fn wait_until(what: &str, mut cond: impl FnMut() -> bool) {
        let end = Instant::now() + Duration::from_secs(5);
        while !cond() {
            assert!(Instant::now() < end, "timed out waiting for {what}");
            thread::sleep(Duration::from_millis(2));
        }
    }

    /// Jobs that block until the test releases them.
    fn gated_pool(
        threads: usize,
        capacity: usize,
    ) -> (Arc<Pool<mpsc::Receiver<()>>>, Arc<AtomicUsize>) {
        let started = Arc::new(AtomicUsize::new(0));
        let s = started.clone();
        let pool = Pool::start(
            threads,
            capacity,
            "pool-test",
            1 << 20,
            None,
            move |gate: mpsc::Receiver<()>| {
                s.fetch_add(1, Ordering::SeqCst);
                let _ = gate.recv();
                || {}
            },
        )
        .unwrap();
        (pool, started)
    }

    #[test]
    fn queue_full_gives_the_job_back() {
        let (pool, started) = gated_pool(2, 3);
        let mut gates = Vec::new();
        let mut submit = |pool: &Pool<mpsc::Receiver<()>>| {
            let (tx, rx) = mpsc::channel();
            gates.push(tx);
            pool.try_submit(rx).is_ok()
        };
        assert!(submit(&pool));
        assert!(submit(&pool));
        wait_until("both workers busy", || started.load(Ordering::SeqCst) == 2);
        for _ in 0..3 {
            assert!(submit(&pool), "queue has room");
        }
        assert_eq!(pool.queued(), 3);
        assert!(!submit(&pool), "one over the capacity is refused");
        gates.clear(); // releases every job
    }

    #[test]
    fn take_where_frees_queue_slots() {
        let (pool, started) = gated_pool(1, 2);
        let (tx0, rx0) = mpsc::channel();
        assert!(pool.try_submit(rx0).is_ok());
        wait_until("worker busy", || started.load(Ordering::SeqCst) == 1);
        let (tx1, rx1) = mpsc::channel();
        let (tx2, rx2) = mpsc::channel();
        assert!(pool.try_submit(rx1).is_ok());
        assert!(pool.try_submit(rx2).is_ok());
        let (_tx3, rx3) = mpsc::channel();
        assert!(pool.try_submit(rx3).is_err(), "full");
        let taken = pool.take_where(|_| true);
        assert_eq!(taken.len(), 2);
        assert_eq!(pool.queued(), 0);
        let (_tx4, rx4) = mpsc::channel();
        assert!(pool.try_submit(rx4).is_ok(), "slots are free again");
        drop((tx0, tx1, tx2));
    }

    #[test]
    fn burst_is_not_refused_while_workers_are_idle() {
        let (pool, _started) = gated_pool(4, 16);
        let mut gates = Vec::new();
        for n in 0..20 {
            let (tx, rx) = mpsc::channel();
            gates.push(tx);
            assert!(pool.try_submit(rx).is_ok(), "job {n} refused");
        }
    }

    #[test]
    fn worker_survives_a_panicking_handler() {
        let done = Arc::new(AtomicUsize::new(0));
        let d = done.clone();
        let pool = Pool::start(1, 4, "pool-test", 1 << 20, None, move |job: bool| {
            if job {
                panic!("boom");
            }
            d.fetch_add(1, Ordering::SeqCst);
            || {}
        })
        .unwrap();
        assert!(pool.try_submit(true).is_ok());
        assert!(pool.try_submit(false).is_ok());
        wait_until("the job after the panic", || {
            done.load(Ordering::SeqCst) == 1
        });
    }

    #[test]
    fn a_result_is_never_seen_before_its_worker_is_free() {
        let pool = Pool::start(1, 0, "pool-test", 1 << 20, None, |tx: mpsc::Sender<()>| {
            move || {
                let _ = tx.send(());
            }
        })
        .unwrap();
        for n in 0..200 {
            let (tx, rx) = mpsc::channel();
            assert!(pool.try_submit(tx.clone()).is_ok(), "submit {n} refused");
            rx.recv_timeout(Duration::from_secs(5)).unwrap();
            let (tx2, rx2) = mpsc::channel();
            assert!(pool.try_submit(tx2).is_ok(), "resubmit {n} refused");
            rx2.recv_timeout(Duration::from_secs(5)).unwrap();
        }
    }

    #[test]
    fn dropped_completer_resolves_none() {
        let (tx, rx) = completion::<u8>();
        drop(tx);
        let waker = Waker::noop();
        let mut cx = Context::from_waker(waker);
        let mut rx = Box::pin(rx);
        assert_eq!(rx.as_mut().poll(&mut cx), Poll::Ready(None));
    }

    #[test]
    fn sent_value_is_delivered() {
        let (tx, rx) = completion::<u8>();
        let waker = Waker::noop();
        let mut cx = Context::from_waker(waker);
        let mut rx = Box::pin(rx);
        assert_eq!(rx.as_mut().poll(&mut cx), Poll::Pending);
        tx.send(7);
        assert_eq!(rx.as_mut().poll(&mut cx), Poll::Ready(Some(7)));
    }

    #[test]
    fn stop_hands_back_waiting_jobs_wakes_workers_and_refuses_more() {
        let (pool, started) = gated_pool(1, 4);
        let (tx0, rx0) = mpsc::channel();
        assert!(pool.try_submit(rx0).is_ok());
        wait_until("worker busy", || started.load(Ordering::SeqCst) == 1);
        let (_tx1, rx1) = mpsc::channel();
        assert!(pool.try_submit(rx1).is_ok());
        let waiting = pool.stop();
        assert_eq!(waiting.len(), 1, "the queued job comes back");
        let (_tx2, rx2) = mpsc::channel();
        assert!(pool.try_submit(rx2).is_err(), "a stopped pool refuses");
        // The busy worker is still inside its job: the join times out.
        assert_eq!(
            pool.join_until(Instant::now() + Duration::from_millis(50)),
            1
        );
        drop(tx0);
    }

    #[test]
    fn idle_workers_leave_on_stop_and_join() {
        let (pool, _started) = gated_pool(3, 4);
        assert!(pool.stop().is_empty());
        assert_eq!(pool.join_until(Instant::now() + Duration::from_secs(5)), 0);
    }

    #[test]
    fn every_worker_runs_the_start_hook_once_with_its_name() {
        let names = Arc::new(Mutex::new(Vec::<String>::new()));
        let seen = names.clone();
        let hook: ThreadStartHook = Arc::new(move |name| {
            seen.lock()
                .expect("lock")
                .push(format!("{name}|{:?}", thread::current().name()));
        });
        let pool = Pool::start(3, 1, "hooked", 1 << 20, Some(hook), |_: ()| || {}).expect("start");
        wait_until("three hooks", || names.lock().expect("lock").len() == 3);
        let mut got = names.lock().expect("lock").clone();
        got.sort();
        assert_eq!(
            got,
            vec![
                "hooked-0|Some(\"hooked-0\")".to_owned(),
                "hooked-1|Some(\"hooked-1\")".to_owned(),
                "hooked-2|Some(\"hooked-2\")".to_owned(),
            ]
        );
        pool.stop();
        assert_eq!(pool.join_until(Instant::now() + Duration::from_secs(5)), 0);
    }

    #[test]
    fn a_panicking_start_hook_does_not_kill_the_worker() {
        let hook: ThreadStartHook = Arc::new(|_| panic!("hook bug"));
        let done = Arc::new(AtomicUsize::new(0));
        let d = done.clone();
        let pool = Pool::start(1, 1, "hooked", 1 << 20, Some(hook), move |_: ()| {
            d.fetch_add(1, Ordering::SeqCst);
            || {}
        })
        .expect("start");
        assert!(pool.try_submit(()).is_ok());
        wait_until("the job after the hook panic", || {
            done.load(Ordering::SeqCst) == 1
        });
    }
}
