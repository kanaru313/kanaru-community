//! The plugin API functions Dart calls, driven directly with closures in
//! place of the Dart callbacks. They share the process's one runtime, so each
//! test holds `serial()`, resets the runtime first, and frees its blocked jobs
//! with a drop guard even when an assertion fails.

// Test helpers may unwrap.
#![allow(clippy::unwrap_used)]

use std::future::Future;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc::channel;
use std::sync::{Arc, Mutex, MutexGuard, Once};
use std::task::{Context, Poll, Wake, Waker};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};

use flutter_rust_bridge::DartFnFuture;
use kanaru_bridge::api::plugin_runtime::*;
use kanaru_bridge::api::plugin_stream::*;
use kanaru_bridge::pools::config;
use kanaru_bridge::runtime_holder::runtime;

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
        assert!(Instant::now() < end, "future did not finish in time");
        thread::park_timeout(Duration::from_millis(5));
    }
}

/// Panics seen by the hook that was installed before the runtime started.
static PANICS_SEEN: AtomicUsize = AtomicUsize::new(0);

/// Holds the lock for the whole test and resets the runtime. The first call
/// of the process installs a counting panic hook, then starts the runtime
/// (which chains its quiet hook onto it).
fn serial() -> MutexGuard<'static, ()> {
    static LOCK: Mutex<()> = Mutex::new(());
    static SETUP: Once = Once::new();
    let guard = LOCK.lock().unwrap_or_else(|e| e.into_inner());
    SETUP.call_once(|| {
        let default = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            PANICS_SEEN.fetch_add(1, Ordering::SeqCst);
            default(info);
        }));
        let _ = runtime();
    });
    reset_plugin_runtime();
    guard
}

/// Cancels its job when dropped, so a failed assertion cannot leave a worker
/// blocked on a callback that never answers.
struct CancelOnDrop(u32);
impl Drop for CancelOnDrop {
    fn drop(&mut self) {
        cancel_plugin_job(self.0);
    }
}

fn request(job: u32, code: &str) -> PluginScriptRequest {
    PluginScriptRequest {
        job,
        install_id: "plugin-1".into(),
        files: vec![PluginSourceFile {
            name: "main.js".into(),
            code: code.into(),
        }],
        entry: "main.js".into(),
        input_json: "null".into(),
        timeout_ms: 0,
        config: Vec::new(),
        storage_json: String::new(),
    }
}

fn answer(status: u16, body: &[u8]) -> PluginFetchResponse {
    PluginFetchResponse {
        outcome: PluginFetchOutcome::Ok,
        status,
        url: "https://t.test/".into(),
        headers: Vec::new(),
        body: body.to_vec(),
        retry_after_sec: None,
        sends: 1,
    }
}

fn no_stream_reply() -> PluginStreamReply {
    PluginStreamReply {
        outcome: PluginFetchOutcome::Network,
        status: 0,
        url: String::new(),
        headers: Vec::new(),
        retry_after_sec: None,
        chunk: Vec::new(),
        done: false,
        sends: 0,
    }
}

/// A fetch callback that never answers.
fn never(_: PluginFetchRequest) -> DartFnFuture<PluginFetchResponse> {
    Box::pin(std::future::pending())
}

/// Starts a run on its own thread; the handle yields the result.
fn spawn_run(
    request: PluginScriptRequest,
    fetch: impl Fn(PluginFetchRequest) -> DartFnFuture<PluginFetchResponse> + Send + Sync + 'static,
) -> JoinHandle<PluginScriptResult> {
    thread::spawn(move || block_on(run_plugin_script(request, fetch)))
}

const OK_SCRIPT: &str = "function execute() { return Response.success('fine'); }";
const FETCHES: &str =
    "function execute() { fetch('https://t.test/a'); return Response.success(1); }";

#[test]
fn a_script_runs_and_returns_its_output() {
    let _t = serial();
    let job = begin_plugin_job();
    let r = block_on(run_plugin_script(request(job, OK_SCRIPT), never));
    assert_eq!(r.status, PluginScriptStatus::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#""fine""#);
    assert_eq!(r.error_kind, PluginErrorKind::None);
}

#[test]
fn an_unknown_response_error_kind_is_server() {
    let _t = serial();
    let job = begin_plugin_job();
    let code = "function execute() { return Response.error('nope', {kind: 'martian'}); }";
    let r = block_on(run_plugin_script(request(job, code), never));
    assert_eq!(r.status, PluginScriptStatus::ScriptError);
    assert_eq!(r.error_kind, PluginErrorKind::Server);
    assert_eq!(r.error_message, "nope");
}

#[test]
fn a_fetch_reaches_dart_with_the_install_id_and_its_answer_returns() {
    let _t = serial();
    let seen = Arc::new(Mutex::new(Vec::<PluginFetchRequest>::new()));
    let log = seen.clone();
    let job = begin_plugin_job();
    let code = "function execute() { return Response.success(fetch('https://t.test/a').text()); }";
    let r = block_on(run_plugin_script(request(job, code), move |req| {
        log.lock().unwrap().push(req);
        Box::pin(async { answer(200, b"hello") })
    }));
    assert_eq!(r.status, PluginScriptStatus::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#""hello""#);
    let seen = seen.lock().unwrap();
    assert_eq!(seen.len(), 1);
    assert_eq!(seen[0].install_id, "plugin-1");
    assert_eq!(seen[0].url, "https://t.test/a");
    assert_eq!(seen[0].method, "GET");
}

#[test]
fn a_failed_fetch_is_reported_with_its_kind() {
    let _t = serial();
    let job = begin_plugin_job();
    let r = block_on(run_plugin_script(request(job, FETCHES), |_| {
        Box::pin(async {
            PluginFetchResponse {
                outcome: PluginFetchOutcome::BlockedHost,
                ..answer(0, b"")
            }
        })
    }));
    let failure = r.fetch_failure.expect("the first failing fetch is kept");
    assert_eq!(failure.kind, PluginFetchFailureKind::BlockedHost);
}

#[test]
fn cancelling_during_a_fetch_ends_the_run_cancelled() {
    let _t = serial();
    let job = begin_plugin_job();
    let _free = CancelOnDrop(job);
    let (reached_tx, reached) = channel();
    let run = spawn_run(request(job, FETCHES), move |req| {
        let _ = reached_tx.send(req.install_id.clone());
        never(req)
    });
    reached
        .recv_timeout(Duration::from_secs(10))
        .expect("the fetch reached the callback");
    cancel_plugin_job(job);
    let r = run.join().unwrap();
    assert_eq!(
        r.status,
        PluginScriptStatus::Cancelled,
        "{}",
        r.error_message
    );
}

#[test]
fn the_twenty_first_concurrent_job_is_busy() {
    let _t = serial();
    let total = config::PLUGIN_WORKERS + config::PLUGIN_QUEUE + 1;
    let (done_tx, done) = channel();
    let mut guards = Vec::new();
    let mut runs = Vec::new();
    for _ in 0..total {
        let job = begin_plugin_job();
        guards.push(CancelOnDrop(job));
        let tx = done_tx.clone();
        runs.push(thread::spawn(move || {
            let r = block_on(run_plugin_script(request(job, FETCHES), never));
            let _ = tx.send(r.status);
            r.status
        }));
    }
    // Only the job that found no room ends while every callback is blocked.
    let first = done
        .recv_timeout(Duration::from_secs(10))
        .expect("a result");
    assert_eq!(first, PluginScriptStatus::Busy);
    drop(guards);
    let statuses: Vec<_> = runs.into_iter().map(|h| h.join().unwrap()).collect();
    let busy = statuses
        .iter()
        .filter(|s| **s == PluginScriptStatus::Busy)
        .count();
    let cancelled = statuses
        .iter()
        .filter(|s| **s == PluginScriptStatus::Cancelled)
        .count();
    assert_eq!((busy, cancelled), (1, total - 1), "{statuses:?}");
}

#[test]
fn reset_frees_every_worker_held_by_unanswered_callbacks() {
    let _t = serial();
    let held = config::PLUGIN_WORKERS + 2;
    let (reached_tx, reached) = channel();
    let mut guards = Vec::new();
    let mut runs = Vec::new();
    for _ in 0..held {
        let job = begin_plugin_job();
        guards.push(CancelOnDrop(job));
        let tx = reached_tx.clone();
        runs.push(spawn_run(request(job, FETCHES), move |req| {
            let _ = tx.send(());
            never(req)
        }));
    }
    for _ in 0..config::PLUGIN_WORKERS {
        reached
            .recv_timeout(Duration::from_secs(10))
            .expect("every worker is inside a fetch");
    }
    reset_plugin_runtime();
    for run in runs {
        let r = run.join().unwrap();
        assert_eq!(
            r.status,
            PluginScriptStatus::Cancelled,
            "{}",
            r.error_message
        );
    }
    // Every worker is free again: as many runs as workers all succeed.
    let again: Vec<_> = (0..config::PLUGIN_WORKERS)
        .map(|_| spawn_run(request(begin_plugin_job(), OK_SCRIPT), never))
        .collect();
    for run in again {
        assert_eq!(run.join().unwrap().status, PluginScriptStatus::Ok);
    }
}

#[test]
fn a_streaming_run_delivers_its_events_to_the_attached_receiver() {
    let _t = serial();
    let job = begin_plugin_job();
    let events = Arc::new(Mutex::new(Vec::<String>::new()));
    let sink = events.clone();
    // `StreamSink` is made by generated code for a live Dart port, so the test
    // attaches the plain closure `plugin_job_events` wraps around it.
    assert!(runtime().attach_job_events(
        job,
        Arc::new(move |json| {
            sink.lock().unwrap().push(json);
            true
        })
    ));
    let code = "function execute() { emit({a: 1}); emit('x'); return Response.success(1); }";
    let options = PluginStreamOptions {
        idle_timeout_ms: 0,
        events: true,
    };
    let r = block_on(run_plugin_stream_script(
        request(job, code),
        options,
        never,
        |_| Box::pin(async { no_stream_reply() }),
    ));
    assert_eq!(r.status, PluginScriptStatus::Ok, "{}", r.error_message);
    assert_eq!(*events.lock().unwrap(), vec![r#"{"a":1}"#, r#""x""#]);
}

#[test]
fn a_streamed_fetch_goes_through_the_stream_callback_with_the_install_id() {
    let _t = serial();
    let job = begin_plugin_job();
    let calls = Arc::new(Mutex::new(Vec::<PluginStreamCall>::new()));
    let log = calls.clone();
    let code = "function execute() { var r = fetch('https://t.test/s', {stream: true}), l = r.readLine(); return Response.success(l); }";
    let options = PluginStreamOptions {
        idle_timeout_ms: 0,
        events: false,
    };
    let r = block_on(run_plugin_stream_script(
        request(job, code),
        options,
        never,
        move |call| {
            log.lock().unwrap().push(call.clone());
            let reply = match call.op {
                PluginStreamOp::Read => PluginStreamReply {
                    outcome: PluginFetchOutcome::Ok,
                    chunk: b"line\n".to_vec(),
                    ..no_stream_reply()
                },
                _ => PluginStreamReply {
                    outcome: PluginFetchOutcome::Ok,
                    status: 200,
                    ..no_stream_reply()
                },
            };
            Box::pin(async move { reply })
        },
    ));
    assert_eq!(r.status, PluginScriptStatus::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#""line""#);
    let calls = calls.lock().unwrap();
    assert_eq!(calls[0].op, PluginStreamOp::Open);
    assert!(calls.iter().all(|c| c.install_id == "plugin-1"));
    assert_eq!(
        calls[0].request.as_ref().map(|q| q.url.as_str()),
        Some("https://t.test/s")
    );
}

#[test]
fn a_syntax_error_reports_its_line() {
    let _t = serial();
    let problem = check_plugin_script(
        "search.js".into(),
        "var a = 1;\nvar b = 2;\nvar c = ;\n".into(),
    )
    .expect("a problem");
    assert_eq!(problem.line, 3, "{problem:?}");
    assert!(!problem.message.is_empty());
    assert_eq!(check_plugin_script("ok.js".into(), OK_SCRIPT.into()), None);
}

#[test]
fn the_panic_hook_chains_to_the_previous_hook_but_is_quiet_for_dart_callbacks() {
    let _t = serial();
    // An ordinary panic still reaches the hook installed before the runtime.
    let before = PANICS_SEEN.load(Ordering::SeqCst);
    let _ = catch_unwind(AssertUnwindSafe(|| panic!("ordinary panic")));
    assert_eq!(PANICS_SEEN.load(Ordering::SeqCst), before + 1);

    // A Dart callback that throws is an expected failure: no hook call, and
    // the script sees a failed fetch.
    let before = PANICS_SEEN.load(Ordering::SeqCst);
    let job = begin_plugin_job();
    let r = block_on(run_plugin_script(request(job, FETCHES), |_| {
        panic!("dart callback threw")
    }));
    assert_eq!(PANICS_SEEN.load(Ordering::SeqCst), before);
    let failure = r
        .fetch_failure
        .expect("the throwing callback is a failed fetch");
    assert_eq!(failure.kind, PluginFetchFailureKind::Network);

    // The same when the panic happens inside the returned future, which is
    // where frb panics for a Dart throw.
    let before = PANICS_SEEN.load(Ordering::SeqCst);
    let job = begin_plugin_job();
    let r = block_on(run_plugin_script(request(job, FETCHES), |_| {
        Box::pin(async { panic!("dart callback threw") })
    }));
    assert_eq!(PANICS_SEEN.load(Ordering::SeqCst), before);
    let failure = r
        .fetch_failure
        .expect("a callback panicking in its future is a failed fetch");
    assert_eq!(failure.kind, PluginFetchFailureKind::Network);
}
