//! Unit tests that need the test-only script globals (`__testLog`,
//! `__testPanic`, cargo feature `test-hooks`) or the runtime's internals.

use std::future::Future;
use std::pin::Pin;
use std::sync::atomic::AtomicBool;
use std::sync::Mutex;
use std::task::{Context, Poll, Wake, Waker};
use std::thread;

use super::*;
use crate::host::NoNetwork;
use crate::types::{ErrorKind, ScriptStatus as S, SourceFile};

struct ThreadWaker(thread::Thread);
impl Wake for ThreadWaker {
    fn wake(self: Arc<Self>) {
        self.0.unpark();
    }
}

/// Minimal executor, bounded so a bug cannot hang the run.
fn block_on<T>(fut: impl Future<Output = T>) -> T {
    let mut fut = Box::pin(fut);
    let waker = Waker::from(Arc::new(ThreadWaker(thread::current())));
    let mut cx = Context::from_waker(&waker);
    let end = Instant::now() + Duration::from_secs(60);
    loop {
        if let Poll::Ready(v) = fut.as_mut().poll(&mut cx) {
            return v;
        }
        assert!(Instant::now() < end, "future did not finish");
        thread::park_timeout(Duration::from_millis(5));
    }
}

fn runtime() -> PluginRuntime {
    PluginRuntime::new(RuntimeConfig::default())
}

fn request(job: u32, code: &str, timeout_ms: u32) -> ScriptRequest {
    ScriptRequest {
        job,
        install_id: "test-install".to_owned(),
        files: vec![SourceFile {
            name: "search.js".to_owned(),
            code: code.to_owned(),
        }],
        entry: "search.js".to_owned(),
        input_json: "{}".to_owned(),
        timeout_ms,
        config: Vec::new(),
        storage_json: String::new(),
    }
}

fn start(rt: &PluginRuntime, code: &str, timeout_ms: u32) -> Pending<ScriptResult> {
    rt.run(
        request(rt.begin_job(), code, timeout_ms),
        Arc::new(NoNetwork),
    )
}

fn run_script(rt: &PluginRuntime, code: &str, timeout_ms: u32) -> ScriptResult {
    block_on(start(rt, code, timeout_ms))
}

/// Polls `fut` once on the calling thread, so the run has claimed its id and
/// been submitted when this returns (submit order is then the call order),
/// then finishes it on its own thread so a test can act while it is pending.
fn on_thread(mut fut: Pending<ScriptResult>) -> thread::JoinHandle<ScriptResult> {
    let first = fut.as_mut().poll(&mut Context::from_waker(Waker::noop()));
    thread::spawn(move || match first {
        Poll::Ready(result) => result,
        Poll::Pending => block_on(fut),
    })
}

fn wait_until(what: &str, mut cond: impl FnMut() -> bool) {
    let end = Instant::now() + Duration::from_secs(10);
    while !cond() {
        assert!(Instant::now() < end, "timed out waiting for {what}");
        thread::sleep(Duration::from_millis(5));
    }
}

const SLEEPS_FOR_A_MINUTE: &str =
    "function execute() { sleep(60000); return Response.success(1); }";
const QUICK: &str = "function execute() { return Response.success(1); }";

/// Every failing script writes a console line first; the line must come back.
fn script_with_log(body: &str) -> String {
    format!("function execute(input) {{ __testLog('before'); {body} }}")
}

fn assert_logged(r: &ScriptResult) {
    assert_eq!(r.logs, vec!["before".to_owned()], "status {:?}", r.status);
    assert_eq!(r.fetch_failure, None);
}

#[test]
fn response_error_auth_and_quota_kinds() {
    let rt = runtime();
    let r = run_script(
        &rt,
        "function execute(i){ return Response.error('bad key', {kind: 'auth'}); }",
        0,
    );
    assert_eq!(r.status, S::ScriptError);
    assert_eq!(r.error_kind, ErrorKind::Auth);
    let r = run_script(
        &rt,
        "function execute(i){ return Response.error('used up', {kind: 'quota', retryAfterSec: 30}); }",
        0,
    );
    assert_eq!(r.error_kind, ErrorKind::Quota);
    assert_eq!(r.retry_after_sec, Some(30));
    let r = run_script(
        &rt,
        "function execute(i){ return Response.error('x', {kind: 'nope'}); }",
        0,
    );
    assert_eq!(r.error_kind, ErrorKind::Server);
}

#[test]
fn logs_survive_a_success() {
    let rt = runtime();
    let r = run_script(&rt, &script_with_log("return Response.success([1]);"), 0);
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_logged(&r);
}

#[test]
fn logs_survive_a_thrown_error_with_message_and_stack() {
    let rt = runtime();
    let r = run_script(&rt, &script_with_log("throw new Error('kaput');"), 0);
    assert_eq!(r.status, S::ScriptError);
    assert_logged(&r);
    let js = r.js_error.expect("js_error on scriptError");
    assert!(js.message.contains("kaput"), "{js:?}");
    assert!(
        js.stack.contains("search.js:"),
        "stack keeps line numbers: {js:?}"
    );
}

#[test]
fn logs_and_js_error_survive_a_timeout() {
    let rt = runtime();
    let r = run_script(&rt, &script_with_log("while (true) {}"), 200);
    assert_eq!(r.status, S::Timeout);
    assert_logged(&r);
    assert!(r.js_error.is_some(), "the interrupt exception is reported");
    assert!(r.error_message.contains("200 ms"), "{}", r.error_message);
}

#[test]
fn logs_and_js_error_survive_the_memory_limit() {
    let rt = runtime();
    let r = run_script(
        &rt,
        &script_with_log("var a = []; while (true) a.push({x: a.length});"),
        0,
    );
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_logged(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn logs_and_js_error_survive_the_stack_limit() {
    let rt = runtime();
    let r = run_script(
        &rt,
        &script_with_log("function f() { return f() + 1; } return f();"),
        0,
    );
    assert_eq!(r.status, S::Stack, "{r:?}");
    assert_logged(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn logs_survive_output_too_large_and_it_has_no_js_error() {
    let rt = runtime();
    let r = run_script(
        &rt,
        &script_with_log("return Response.success('x'.repeat(3 * 1024 * 1024));"),
        0,
    );
    assert_eq!(r.status, S::OutputTooLarge, "{r:?}");
    assert_logged(&r);
    assert_eq!(r.js_error, None, "found by the host after execute returned");
    assert!(!r.error_message.is_empty());
}

#[test]
fn logs_survive_a_response_error_and_an_invalid_response() {
    let rt = runtime();
    let r = run_script(
        &rt,
        &script_with_log(
            "return Response.error('slow down', {kind: 'rateLimited', retryAfterSec: 7});",
        ),
        0,
    );
    assert_eq!(r.status, S::ScriptError);
    assert_eq!(r.error_kind, ErrorKind::RateLimited);
    assert_eq!(r.retry_after_sec, Some(7));
    assert_logged(&r);

    let r = run_script(&rt, &script_with_log("return {ok: true, data: 1};"), 0);
    assert_eq!(r.status, S::ScriptError);
    assert_eq!(r.error_kind, ErrorKind::InvalidResponse);
    assert_logged(&r);
}

#[test]
fn logs_and_js_error_survive_a_cancel_while_running() {
    let rt = runtime();
    let id = rt.begin_job();
    let fut = rt.run(
        request(id, &script_with_log("__testReady(); while (true) {}"), 0),
        Arc::new(NoNetwork),
    );
    let runner = on_thread(fut);
    wait_until("the script to run", || rt.inner.late.ready_count() == 1);
    rt.cancel_job(id);
    let r = runner.join().expect("runner");
    assert_eq!(r.status, S::Cancelled);
    assert_logged(&r);
    assert!(r.js_error.is_some(), "the interrupt exception is reported");
}

#[test]
fn a_panic_in_a_host_function_is_internal_keeps_logs_and_the_pool_runs_on() {
    let rt = runtime();
    let r = run_script(&rt, &script_with_log("__testPanic();"), 0);
    assert_eq!(r.status, S::Internal, "{r:?}");
    assert_logged(&r);
    assert_eq!(r.js_error, None);

    // Every worker stays usable: run more jobs than there are threads.
    for n in 0..limits::WORKER_THREADS * 2 {
        let r = run_script(
            &rt,
            &format!("function execute() {{ return Response.success({n}); }}"),
            0,
        );
        assert_eq!(r.status, S::Ok, "job {n} after the panic: {r:?}");
        assert_eq!(r.output_json, n.to_string());
    }
}

#[test]
fn cancelled_before_start_has_no_js_error_but_an_explanation() {
    let rt = runtime();
    let id = rt.begin_job();
    rt.cancel_job(id);
    let r = block_on(rt.run(request(id, "function execute() {}", 0), Arc::new(NoNetwork)));
    assert_eq!(r.status, S::Cancelled);
    assert_eq!(r.js_error, None);
    assert!(!r.error_message.is_empty());
    assert!(r.logs.is_empty());
}

#[test]
fn a_heap_overflow_the_script_catches_still_ends_memory() {
    let rt = runtime();
    let r = run_script(
        &rt,
        &script_with_log(
            "var a = [];
             try { while (true) a.push({x: a.length, y: 'padding padding'}); } catch (e) {}
             a = null;
             return Response.success('recovered');",
        ),
        0,
    );
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_logged(&r);
}

#[test]
fn a_full_queue_is_busy_and_a_cancelled_queued_job_gives_its_slot_back() {
    let rt = PluginRuntime::new(RuntimeConfig {
        workers: 1,
        queue: 1,
        ..RuntimeConfig::default()
    });
    let pool = rt.inner.pool.clone().expect("pool");
    let running = on_thread(start(&rt, SLEEPS_FOR_A_MINUTE, 0));
    // `try_submit` counts idle workers as room, so the second job only waits in
    // the queue (and the third is only refused) once the worker took the first.
    wait_until("the worker to take the first job", || pool.running() == 1);
    let queued_id = rt.begin_job();
    let queued = on_thread(rt.run(
        request(queued_id, SLEEPS_FOR_A_MINUTE, 0),
        Arc::new(NoNetwork),
    ));
    wait_until("one job queued", || pool.queued() == 1);

    let r = run_script(&rt, QUICK, 0);
    assert_eq!(r.status, S::Busy, "{r:?}");

    rt.cancel_job(queued_id);
    let r = queued.join().expect("queued");
    assert_eq!(r.status, S::Cancelled);
    assert_eq!(pool.queued(), 0, "the slot is free at once");

    rt.reset();
    assert_eq!(running.join().expect("running").status, S::Cancelled);
}

#[test]
fn a_result_is_never_seen_before_its_worker_is_free() {
    let rt = PluginRuntime::new(RuntimeConfig {
        workers: 1,
        queue: 0,
        ..RuntimeConfig::default()
    });
    for n in 0..50 {
        for again in 0..2 {
            let r = run_script(&rt, QUICK, 0);
            assert_eq!(r.status, S::Ok, "run {n}.{again}: {r:?}");
        }
    }
}

#[test]
fn dropping_the_run_future_cancels_the_job() {
    let rt = PluginRuntime::new(RuntimeConfig {
        workers: 1,
        queue: 0,
        ..RuntimeConfig::default()
    });
    let mut abandoned = start(&rt, SLEEPS_FOR_A_MINUTE, 0);
    let waker = Waker::noop();
    let mut cx = Context::from_waker(waker);
    assert!(
        abandoned.as_mut().poll(&mut cx).is_pending(),
        "submitted and running"
    );
    let started = Instant::now();
    drop(abandoned);
    // With no queue the next job is `Busy` until the cancelled one is gone.
    wait_until("the worker to free up", || {
        run_script(&rt, QUICK, 0).status == S::Ok
    });
    assert!(started.elapsed() < Duration::from_secs(5));
}

// ------------------------------------------------------------- lifecycle

#[test]
fn reset_cancels_running_and_queued_jobs_and_the_workers_stay() {
    let rt = PluginRuntime::new(RuntimeConfig {
        workers: 2,
        queue: 2,
        ..RuntimeConfig::default()
    });
    let jobs: Vec<_> = (0..4)
        .map(|_| on_thread(start(&rt, SLEEPS_FOR_A_MINUTE, 0)))
        .collect();
    let pool = rt.inner.pool.clone().expect("pool");
    wait_until("two jobs queued behind two running", || pool.queued() == 2);

    let started = Instant::now();
    rt.reset();
    for job in jobs {
        assert_eq!(job.join().expect("job").status, S::Cancelled);
    }
    assert!(
        started.elapsed() < Duration::from_secs(1),
        "reset took {:?}",
        started.elapsed()
    );
    // Reset leaves the workers alive.
    for _ in 0..4 {
        assert_eq!(run_script(&rt, QUICK, 0).status, S::Ok);
    }
}

#[test]
fn reset_forgets_ids_that_were_begun_but_never_run() {
    let rt = runtime();
    let id = rt.begin_job();
    rt.reset();
    let r = block_on(rt.run(request(id, QUICK, 0), Arc::new(NoNetwork)));
    assert_eq!(r.status, S::Cancelled, "{r:?}");
    assert!(rt.begin_job() > id, "ids keep rising");
}

#[test]
fn shutdown_joins_every_thread_refuses_runs_and_is_idempotent() {
    let rt = runtime();
    let pool = rt.inner.pool.clone().expect("pool");
    let running = on_thread(start(&rt, SLEEPS_FOR_A_MINUTE, 0));
    wait_until("the job to run", || pool.running() == 1);
    let probe_dropped = Arc::new(AtomicBool::new(false));
    rt.inner
        .late
        .hand_over::<u8>(Box::pin(DropProbe(probe_dropped.clone())));

    let report = rt.inner.shutdown();
    assert_eq!(
        report,
        ShutdownReport {
            workers_left: 0,
            late_joined: true
        }
    );
    assert_eq!(running.join().expect("running").status, S::Cancelled);
    assert!(
        !probe_dropped.load(Ordering::SeqCst),
        "the late future is forgotten, never dropped"
    );

    let r = run_script(&rt, QUICK, 0);
    assert_eq!(r.status, S::Internal, "{r:?}");
    assert!(r.error_message.contains("shut down"), "{}", r.error_message);
    rt.shutdown(); // a second call does nothing
    assert_eq!(rt.inner.shutdown().workers_left, 0);
}

struct DropProbe(Arc<AtomicBool>);
impl Future for DropProbe {
    type Output = u8;
    fn poll(self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<u8> {
        Poll::Pending
    }
}
impl Drop for DropProbe {
    fn drop(&mut self) {
        self.0.store(true, Ordering::SeqCst);
    }
}

#[test]
fn dropping_the_runtime_shuts_it_down() {
    let rt = runtime();
    let inner = rt.inner.clone();
    drop(rt);
    assert!(inner.stopped.load(Ordering::SeqCst));
    // `Drop` joins the workers itself (see the `/proc` test in
    // `tests/lifecycle.rs`); here: what a future that outlives it sees.
    let r = block_on(inner.run(request(1, QUICK, 0), Arc::new(NoNetwork), None));
    assert_eq!(r.status, S::Internal, "{r:?}");
}

#[test]
fn the_thread_start_hook_runs_once_per_thread_with_its_name() {
    let names = Arc::new(Mutex::new(Vec::<(String, Option<String>)>::new()));
    let seen = names.clone();
    let hook: ThreadStartHook = Arc::new(move |name| {
        let actual = thread::current().name().map(str::to_owned);
        seen.lock().expect("lock").push((name.to_owned(), actual));
    });
    let rt = PluginRuntime::new(RuntimeConfig {
        workers: 2,
        stream_workers: 1,
        on_thread_start: Some(hook),
        ..RuntimeConfig::default()
    });
    assert_eq!(rt.check_script("a.js", "var a = 1;"), None);
    // The drain thread starts on first use.
    let hand_over_done = Arc::new(AtomicBool::new(false));
    let done = hand_over_done.clone();
    rt.inner.late.hand_over::<u8>(Box::pin(async move {
        done.store(true, Ordering::SeqCst);
        0
    }));
    wait_until("the drain to poll", || {
        hand_over_done.load(Ordering::SeqCst)
    });
    wait_until("five hooks", || names.lock().expect("lock").len() == 5);

    let mut got = names.lock().expect("lock").clone();
    got.sort();
    let expected: Vec<(String, Option<String>)> = [
        "plugin-js-0",
        "plugin-js-1",
        "plugin-js-check",
        "plugin-js-stream-0",
        "plugin-late-answers",
    ]
    .iter()
    .map(|n| ((*n).to_owned(), Some((*n).to_owned())))
    .collect();
    assert_eq!(
        got, expected,
        "each thread named itself to the hook once, on its own thread"
    );
}

#[test]
fn a_runtime_without_workers_ends_runs_internal_not_hung() {
    let rt = PluginRuntime::new(RuntimeConfig {
        workers: 0,
        stream_workers: 0,
        ..RuntimeConfig::default()
    });
    let r = run_script(&rt, QUICK, 0);
    assert_eq!(r.status, S::Internal, "{r:?}");
    assert!(
        r.error_message.contains("no JS worker thread could start"),
        "{r:?}"
    );
}

#[test]
fn an_empty_install_id_ends_internal() {
    let rt = runtime();
    let mut req = request(rt.begin_job(), QUICK, 0);
    req.install_id.clear();
    let r = block_on(rt.run(req, Arc::new(NoNetwork)));
    assert_eq!(r.status, S::Internal, "{r:?}");
    assert!(
        r.error_message.contains("install_id"),
        "{}",
        r.error_message
    );
}

#[test]
fn duplicate_files_and_a_missing_entry_end_internal() {
    let rt = runtime();
    let mut req = request(rt.begin_job(), QUICK, 0);
    req.files.push(SourceFile {
        name: "search.js".to_owned(),
        code: "dup".to_owned(),
    });
    let r = block_on(rt.run(req, Arc::new(NoNetwork)));
    assert_eq!(r.status, S::Internal, "{r:?}");
    assert!(r.error_message.contains("share a name"));

    let mut req = request(rt.begin_job(), QUICK, 0);
    req.entry = "missing.js".to_owned();
    let r = block_on(rt.run(req, Arc::new(NoNetwork)));
    assert_eq!(r.status, S::Internal, "{r:?}");
    assert!(r.error_message.contains("missing.js"));
}

#[test]
fn a_small_configured_stack_is_raised_and_deep_recursion_still_ends_stack() {
    let rt = PluginRuntime::new(RuntimeConfig {
        stack_bytes: 64 * 1024,
        ..RuntimeConfig::default()
    });
    assert_eq!(rt.inner.stack_bytes, limits::THREAD_STACK_BYTES);
    let r = run_script(
        &rt,
        &script_with_log("function f() { return f() + 1; } return f();"),
        0,
    );
    assert_eq!(r.status, S::Stack, "{r:?}");
    assert_eq!(rt.check_script("a.js", "var a = 1;"), None);
}

#[test]
fn a_larger_configured_stack_is_kept() {
    let big = limits::THREAD_STACK_BYTES * 2;
    let rt = PluginRuntime::new(RuntimeConfig {
        stack_bytes: big,
        workers: 1,
        stream_workers: 0,
        ..RuntimeConfig::default()
    });
    assert_eq!(rt.inner.stack_bytes, big);
}
