//! Life of a runtime instance: `reset` frees every worker at once, `shutdown`
//! and `Drop` join the threads. Each test builds its own runtime (it is torn
//! down in the test), so they take a lock: the thread counts below must not
//! see the threads of another test.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::fs;
use std::sync::{Mutex, MutexGuard};
use std::task::{Context, Poll, Waker};
use std::thread;
use std::time::{Duration, Instant};

use common::{block_on, file, request_with, FakeHost};
use kanaru_plugin_runtime::limits::{CANCEL_POLL, QUEUE_CAPACITY, WORKER_THREADS};
use kanaru_plugin_runtime::{
    NoNetwork, PluginRuntime, RuntimeConfig, ScriptResult, ScriptStatus as S,
};
use std::sync::Arc;

fn serial() -> MutexGuard<'static, ()> {
    static LOCK: Mutex<()> = Mutex::new(());
    LOCK.lock().unwrap_or_else(|e| e.into_inner())
}

const SLEEPS: &str = "function execute() { sleep(60000); return Response.success(1); }";
const OK: &str = "function execute() { return Response.success('fine'); }";

/// Starts `code` as a job on its own thread. The future is polled once here
/// first, so the job has claimed its id and been submitted when this returns:
/// submit order is call order and a later `reset`/`shutdown` sees the job.
fn start(rt: &Arc<PluginRuntime>, code: &str) -> thread::JoinHandle<ScriptResult> {
    let job = rt.begin_job();
    let request = request_with(job, vec![file("search.js", code)], "{}", 0);
    let mut fut = rt.run(request, Arc::new(NoNetwork));
    let first = fut.as_mut().poll(&mut Context::from_waker(Waker::noop()));
    thread::spawn(move || match first {
        Poll::Ready(result) => result,
        Poll::Pending => block_on(fut),
    })
}

/// Like [`start`], for a job whose fetches go to `host`.
fn start_with_host(
    rt: &Arc<PluginRuntime>,
    code: &str,
    host: Arc<FakeHost>,
) -> thread::JoinHandle<ScriptResult> {
    let job = rt.begin_job();
    let request = request_with(job, vec![file("search.js", code)], "{}", 0);
    let mut fut = rt.run(request, host);
    let first = fut.as_mut().poll(&mut Context::from_waker(Waker::noop()));
    thread::spawn(move || match first {
        Poll::Ready(result) => result,
        Poll::Pending => block_on(fut),
    })
}

/// Names of this process's threads (Linux `comm`, cut at 15 characters) that
/// belong to a plugin runtime.
#[cfg(target_os = "linux")]
fn runtime_threads() -> Vec<String> {
    let mut names = Vec::new();
    for entry in fs::read_dir("/proc/self/task").expect("read /proc/self/task") {
        let path = entry.expect("task entry").path().join("comm");
        // A thread can exit between the listing and the read.
        if let Ok(name) = fs::read_to_string(path) {
            let name = name.trim().to_owned();
            if name.starts_with("plugin-") {
                names.push(name);
            }
        }
    }
    names
}

/// Waits (bounded) for the runtime threads to be gone. A joined thread is
/// still listed in `/proc/self/task` for a moment after `join` returns (the
/// kernel reaps the task after it wakes the joiner), so the threads of the
/// runtime a previous test just dropped can show up at the start of the next
/// one. A thread that never leaves is returned after the bound.
#[cfg(target_os = "linux")]
fn runtime_threads_after_join() -> Vec<String> {
    let end = Instant::now() + Duration::from_secs(5);
    loop {
        let left = runtime_threads();
        if left.is_empty() || Instant::now() >= end {
            return left;
        }
        thread::sleep(Duration::from_millis(5));
    }
}

#[test]
fn reset_frees_every_worker_and_queued_job_within_two_cancel_polls() {
    let _s = serial();
    let rt = Arc::new(PluginRuntime::new(RuntimeConfig::default()));
    // All workers waiting in `sleep`, and some jobs queued behind them.
    let jobs: Vec<_> = (0..WORKER_THREADS + 3)
        .map(|_| start(&rt, SLEEPS))
        .collect();

    let started = Instant::now();
    rt.reset();
    let results: Vec<_> = jobs.into_iter().map(|h| h.join().unwrap()).collect();
    let took = started.elapsed();
    for r in &results {
        assert_eq!(r.status, S::Cancelled, "{r:?}");
    }
    // A sleeping worker looks at its cancel flag every `CANCEL_POLL`; the extra
    // 100 ms is scheduling slack for a loaded machine.
    assert!(
        took < CANCEL_POLL * 2 + Duration::from_millis(100),
        "workers freed after {took:?}"
    );

    // The runtime stays usable after a reset, and its queue is empty again.
    let after = block_on(rt.run(
        request_with(rt.begin_job(), vec![file("search.js", OK)], "{}", 0),
        Arc::new(NoNetwork),
    ));
    assert_eq!(after.status, S::Ok, "{after:?}");
}

#[test]
fn reset_ends_jobs_waiting_for_a_host_that_never_answers() {
    let _s = serial();
    let rt = Arc::new(PluginRuntime::new(RuntimeConfig::default()));
    let host = FakeHost::never_answering();
    let code = "function execute() { console.log('asked'); fetch('https://t.test/'); return Response.success(1); }";
    let jobs: Vec<_> = (0..WORKER_THREADS)
        .map(|_| start_with_host(&rt, code, host.clone()))
        .collect();
    // Wait (bounded) until every worker has sent its request and waits.
    let end = Instant::now() + Duration::from_secs(5);
    while host.requests().len() < WORKER_THREADS && Instant::now() < end {
        thread::sleep(Duration::from_millis(5));
    }
    assert_eq!(host.requests().len(), WORKER_THREADS, "all are waiting");

    let started = Instant::now();
    rt.reset();
    for h in jobs {
        let r = h.join().unwrap();
        assert_eq!(r.status, S::Cancelled, "{r:?}");
        assert_eq!(r.logs, vec!["asked".to_owned()]);
    }
    assert!(
        started.elapsed() < CANCEL_POLL * 2 + Duration::from_millis(100),
        "workers freed after {:?}",
        started.elapsed()
    );
    // The runtime is usable again.
    let after = block_on(rt.run(
        request_with(rt.begin_job(), vec![file("search.js", OK)], "{}", 0),
        Arc::new(NoNetwork),
    ));
    assert_eq!(after.status, S::Ok, "{after:?}");
    common::assert_no_missing_install_id();
}

#[test]
fn reset_forgets_ids_that_have_not_started() {
    let _s = serial();
    let rt = PluginRuntime::new(RuntimeConfig::default());
    let id = rt.begin_job();
    rt.reset();
    let r = block_on(rt.run(
        request_with(id, vec![file("search.js", OK)], "{}", 0),
        Arc::new(NoNetwork),
    ));
    assert_eq!(r.status, S::Cancelled, "{r:?}");
}

#[cfg(target_os = "linux")]
#[test]
fn shutdown_joins_every_thread_even_while_jobs_run() {
    let _s = serial();
    assert_eq!(
        runtime_threads_after_join(),
        Vec::<String>::new(),
        "stray threads"
    );
    let rt = Arc::new(PluginRuntime::new(RuntimeConfig::default()));
    let jobs: Vec<_> = (0..WORKER_THREADS + QUEUE_CAPACITY.min(2))
        .map(|_| start(&rt, SLEEPS))
        .collect();
    // A thread names itself (its `comm`) a moment after `spawn` returns, so
    // wait (bounded) for all of them instead of listing once.
    let end = Instant::now() + Duration::from_secs(5);
    let mut running = runtime_threads();
    while running.len() <= WORKER_THREADS && Instant::now() < end {
        thread::sleep(Duration::from_millis(5));
        running = runtime_threads();
    }
    assert!(
        running.len() > WORKER_THREADS,
        "workers and the streaming worker run: {running:?}"
    );

    let started = Instant::now();
    rt.shutdown();
    assert!(started.elapsed() < Duration::from_secs(2), "slow shutdown");
    for h in jobs {
        let r = h.join().unwrap();
        assert_eq!(r.status, S::Cancelled, "{r:?}");
    }
    assert_eq!(
        runtime_threads_after_join(),
        Vec::<String>::new(),
        "threads left after shutdown"
    );

    // A shut-down runtime refuses work and shutdown can be repeated.
    let r = block_on(rt.run(
        request_with(rt.begin_job(), vec![file("search.js", OK)], "{}", 0),
        Arc::new(NoNetwork),
    ));
    assert_eq!(r.status, S::Internal, "{r:?}");
    rt.shutdown();
}

#[cfg(target_os = "linux")]
#[test]
fn dropping_the_runtime_joins_its_threads() {
    let _s = serial();
    assert_eq!(
        runtime_threads_after_join(),
        Vec::<String>::new(),
        "stray threads"
    );
    let rt = PluginRuntime::new(RuntimeConfig::default());
    let ok = block_on(rt.run(
        request_with(rt.begin_job(), vec![file("search.js", OK)], "{}", 0),
        Arc::new(NoNetwork),
    ));
    assert_eq!(ok.status, S::Ok, "{ok:?}");
    assert!(!runtime_threads().is_empty());
    drop(rt);
    assert_eq!(runtime_threads_after_join(), Vec::<String>::new());
}
