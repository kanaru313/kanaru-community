//! Helpers shared by the integration tests: a tiny executor, request builders
//! and one lazily built [`PluginRuntime`] per test binary.
//!
//! Every test starts with `let _t = common::test();`. That takes the binary's
//! serial lock (tests that fill the worker pool must not overlap others),
//! resets the shared runtime, and on drop resets it again so a job a failed
//! test left blocked is cancelled before the next test starts.

#![allow(dead_code, clippy::unwrap_used)]

use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, MutexGuard, OnceLock};
use std::task::{Context, Poll, Wake, Waker};
use std::thread;
use std::time::{Duration, Instant};

use kanaru_plugin_runtime::{
    failed_response, failed_stream_reply, Emitter, FetchOutcome, FetchRequest, FetchResponse,
    NoNetwork, Pending, PluginHost, PluginRuntime, RuntimeConfig, ScriptRequest, ScriptResult,
    SourceFile, StreamCall, StreamOp, StreamOptions, StreamReply,
};

struct ThreadWaker(thread::Thread);
impl Wake for ThreadWaker {
    fn wake(self: Arc<Self>) {
        self.0.unpark();
    }
}

/// Minimal executor, bounded so a bug cannot hang the run.
pub fn block_on<T>(fut: impl Future<Output = T>) -> T {
    let mut fut = Box::pin(fut);
    let waker = Waker::from(Arc::new(ThreadWaker(thread::current())));
    let mut cx = Context::from_waker(&waker);
    let end = Instant::now() + Duration::from_secs(120);
    loop {
        if let Poll::Ready(v) = fut.as_mut().poll(&mut cx) {
            return v;
        }
        assert!(Instant::now() < end, "future did not finish in time");
        thread::park_timeout(Duration::from_millis(5));
    }
}

/// The runtime every test of this binary shares.
pub fn runtime() -> &'static PluginRuntime {
    static RUNTIME: OnceLock<PluginRuntime> = OnceLock::new();
    RUNTIME.get_or_init(|| PluginRuntime::new(RuntimeConfig::default()))
}

/// Holds the serial lock of a test; resets the runtime when the test ends.
pub struct TestGuard {
    _lock: MutexGuard<'static, ()>,
}

impl Drop for TestGuard {
    fn drop(&mut self) {
        // Cancels jobs a failed test left blocked; the lock is still held.
        runtime().reset();
        let missing = MISSING_INSTALL_ID.swap(false, Ordering::SeqCst);
        assert!(
            thread::panicking() || !missing,
            "the host got a call without an install_id"
        );
    }
}

/// Starts a test: serial lock, then a clean runtime.
pub fn test() -> TestGuard {
    static LOCK: Mutex<()> = Mutex::new(());
    let lock = LOCK.lock().unwrap_or_else(|e| e.into_inner());
    runtime().reset();
    TestGuard { _lock: lock }
}

/// The shared runtime as free functions, so a test reads `rt::run(..)`.
pub mod rt {
    use super::*;

    pub fn begin_job() -> u32 {
        runtime().begin_job()
    }

    pub fn cancel_job(id: u32) {
        runtime().cancel_job(id);
    }

    /// Runs `request` with a host that has no network.
    pub fn run(request: ScriptRequest) -> Pending<ScriptResult> {
        runtime().run(request, Arc::new(NoNetwork))
    }

    /// Starts a streaming run on the shared runtime (events not attached).
    pub fn run_streaming(
        request: ScriptRequest,
        idle_timeout_ms: u32,
        host: Arc<dyn PluginHost>,
        emitter: Option<Emitter>,
    ) -> Pending<ScriptResult> {
        let options = StreamOptions {
            idle_timeout_ms,
            events: false,
        };
        runtime().run_streaming(request, options, host, emitter)
    }
}

pub fn file(name: &str, code: &str) -> SourceFile {
    SourceFile {
        name: name.to_owned(),
        code: code.to_owned(),
    }
}

pub fn request_with(
    job: u32,
    files: Vec<SourceFile>,
    input_json: &str,
    timeout_ms: u32,
) -> ScriptRequest {
    ScriptRequest {
        job,
        install_id: "test-install".to_owned(),
        files,
        entry: "search.js".to_owned(),
        input_json: input_json.to_owned(),
        timeout_ms,
        config: Vec::new(),
        storage_json: String::new(),
    }
}

/// Runs `code` as `search.js` with input `{}` as a new job.
pub fn run_script(code: &str, timeout_ms: u32) -> ScriptResult {
    let job = rt::begin_job();
    block_on(rt::run(request_with(
        job,
        vec![file("search.js", code)],
        "{}",
        timeout_ms,
    )))
}

/// Runs several files; `search.js` is the entry.
pub fn run_files(files: Vec<SourceFile>, input_json: &str) -> ScriptResult {
    let job = rt::begin_job();
    block_on(rt::run(request_with(job, files, input_json, 0)))
}

/// Runs `code` as `search.js` with `localConfig` entries and stored map.
pub fn run_with_state(
    code: &str,
    config: &[(&str, &str)],
    storage_json: &str,
    timeout_ms: u32,
) -> ScriptResult {
    let job = rt::begin_job();
    let mut request = request_with(job, vec![file("search.js", code)], "{}", timeout_ms);
    request.config = config
        .iter()
        .map(|(k, v)| ((*k).to_owned(), (*v).to_owned()))
        .collect();
    request.storage_json = storage_json.to_owned();
    block_on(rt::run(request))
}

/// Set by [`FakeHost`] when a call reaches it with an empty `install_id`; the
/// test guard fails the test at its end (a panic inside the host call would
/// only be turned into a network failure by the runtime).
static MISSING_INSTALL_ID: AtomicBool = AtomicBool::new(false);

/// Fails now if a [`FakeHost`] got a call without an `install_id`, and clears
/// the flag. For tests that run under their own lock instead of [`test`].
pub fn assert_no_missing_install_id() {
    let missing = MISSING_INSTALL_ID.swap(false, Ordering::SeqCst);
    assert!(!missing, "the host got a call without an install_id");
}

/// An `ok` answer with `body`, one send.
pub fn ok_response(status: u16, body: &[u8]) -> FetchResponse {
    FetchResponse {
        status,
        body: body.to_vec(),
        url: "https://example.test/final".to_owned(),
        sends: 1,
        ..failed_response(FetchOutcome::Ok)
    }
}

/// An answer that is not `ok`.
pub fn outcome_response(outcome: FetchOutcome) -> FetchResponse {
    failed_response(outcome)
}

/// A future that is completed from another thread (or never), like the
/// app's reply arriving later.
pub struct Delayed<T> {
    slot: Arc<Mutex<(Option<T>, Option<std::task::Waker>)>>,
}

impl<T: Send + 'static> Delayed<T> {
    /// A future that is ready with `value` after `delay`, set by a helper thread.
    pub fn after(delay: Duration, value: T) -> Self {
        let slot: Arc<Mutex<(Option<T>, Option<std::task::Waker>)>> =
            Arc::new(Mutex::new((None, None)));
        let writer = slot.clone();
        thread::spawn(move || {
            thread::sleep(delay);
            let mut guard = writer.lock().unwrap();
            guard.0 = Some(value);
            if let Some(waker) = guard.1.take() {
                waker.wake();
            }
        });
        Self { slot }
    }
}

impl<T> Future for Delayed<T> {
    type Output = T;
    fn poll(self: std::pin::Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<T> {
        let mut guard = self.slot.lock().unwrap();
        match guard.0.take() {
            Some(value) => Poll::Ready(value),
            None => {
                guard.1 = Some(cx.waker().clone());
                Poll::Pending
            }
        }
    }
}

type FetchHandler = Box<dyn Fn(FetchRequest) -> Pending<FetchResponse> + Send + Sync>;
/// Answers the stream calls of a [`FakeHost`].
pub type StreamFn = Arc<dyn Fn(StreamCall) -> Pending<StreamReply> + Send + Sync>;

/// A scripted [`PluginHost`]: records every request and stream call, checks
/// each carries an `install_id`, and answers fetches the way the test says.
/// Stream calls are answered with the no-network failure unless the host was
/// made with [`FakeHost::streaming`] or [`FakeHost::streams`].
pub struct FakeHost {
    handler: FetchHandler,
    stream_handler: StreamFn,
    requests: Mutex<Vec<FetchRequest>>,
    stream_calls: Mutex<Vec<StreamCall>>,
}

impl FakeHost {
    /// Fully custom futures (panics, lazy futures, drop tracking).
    pub fn with_futures(
        handler: impl Fn(FetchRequest) -> Pending<FetchResponse> + Send + Sync + 'static,
    ) -> Arc<Self> {
        Arc::new(Self {
            handler: Box::new(handler),
            stream_handler: Arc::new(|_| {
                Box::pin(async { failed_stream_reply(FetchOutcome::Network) })
            }),
            requests: Mutex::default(),
            stream_calls: Mutex::default(),
        })
    }

    /// Answers every fetch at once with `reply(&request)`.
    pub fn answering(
        reply: impl Fn(&FetchRequest) -> FetchResponse + Send + Sync + 'static,
    ) -> Arc<Self> {
        Self::with_futures(move |request| {
            let answer = reply(&request);
            Box::pin(async move { answer })
        })
    }

    /// Answers every fetch from another thread after `delay`.
    pub fn answering_after(
        delay: Duration,
        reply: impl Fn(&FetchRequest) -> FetchResponse + Send + Sync + 'static,
    ) -> Arc<Self> {
        Self::with_futures(move |request| {
            let answer = reply(&request);
            Box::pin(Delayed::after(delay, answer))
        })
    }

    /// Fetches answered at once with `fetch(&request)`, stream calls by `stream`.
    pub fn streaming(
        fetch: impl Fn(&FetchRequest) -> FetchResponse + Send + Sync + 'static,
        stream: StreamFn,
    ) -> Arc<Self> {
        Arc::new(Self {
            handler: Box::new(move |request| {
                let answer = fetch(&request);
                Box::pin(async move { answer })
            }),
            stream_handler: stream,
            requests: Mutex::default(),
            stream_calls: Mutex::default(),
        })
    }

    /// Stream calls answered by `stream`; every fetch fails with `Network`.
    pub fn streams(stream: StreamFn) -> Arc<Self> {
        Self::streaming(|_| failed_response(FetchOutcome::Network), stream)
    }

    /// A host whose futures never complete (the app never replies).
    pub fn never_answering() -> Arc<Self> {
        Self::with_futures(|_| Box::pin(std::future::pending()))
    }

    /// Every request received so far, in order.
    pub fn requests(&self) -> Vec<FetchRequest> {
        self.requests.lock().unwrap().clone()
    }

    /// Every stream call received so far, in order.
    pub fn stream_calls(&self) -> Vec<StreamCall> {
        self.stream_calls.lock().unwrap().clone()
    }
}

impl PluginHost for FakeHost {
    fn fetch(&self, request: FetchRequest) -> Pending<FetchResponse> {
        if request.install_id.is_empty() {
            MISSING_INSTALL_ID.store(true, Ordering::SeqCst);
        }
        self.requests.lock().unwrap().push(request.clone());
        (self.handler)(request)
    }

    fn stream(&self, call: StreamCall) -> Pending<StreamReply> {
        let missing = call.install_id.is_empty()
            || call
                .request
                .as_ref()
                .is_some_and(|r| r.install_id.is_empty());
        if missing {
            MISSING_INSTALL_ID.store(true, Ordering::SeqCst);
        }
        self.stream_calls.lock().unwrap().push(call.clone());
        (self.stream_handler)(call)
    }
}

/// How many recorded stream calls of `host` are `op`.
pub fn count_ops(host: &FakeHost, op: StreamOp) -> usize {
    host.stream_calls().iter().filter(|c| c.op == op).count()
}

/// A stream answerer from a plain function; the answer is ready at once.
pub fn stream_answer_with(
    f: impl Fn(&StreamCall) -> StreamReply + Send + Sync + 'static,
) -> StreamFn {
    Arc::new(move |call| {
        let answer = f(&call);
        Box::pin(async move { answer })
    })
}

/// An `ok` answer to an `Open`.
pub fn stream_opened() -> StreamReply {
    StreamReply {
        status: 200,
        url: "https://example.test/stream".to_owned(),
        headers: vec![("Content-Type".to_owned(), "text/event-stream".to_owned())],
        sends: 1,
        ..failed_stream_reply(FetchOutcome::Ok)
    }
}

/// An `ok` answer to a `Read`.
pub fn stream_chunk(bytes: &[u8], done: bool) -> StreamReply {
    StreamReply {
        chunk: bytes.to_vec(),
        done,
        ..failed_stream_reply(FetchOutcome::Ok)
    }
}

/// A failed answer.
pub fn stream_failed(outcome: FetchOutcome) -> StreamReply {
    failed_stream_reply(outcome)
}

/// A stream answerer that opens, then serves `chunks` one per `Read`, then the
/// end (`done`), and answers `Close` with `ok`. `then` may replace an answer:
/// it gets the call and the default answer.
pub fn scripted_stream(
    chunks: Vec<Vec<u8>>,
    then: impl Fn(&StreamCall, StreamReply) -> StreamReply + Send + Sync + 'static,
) -> StreamFn {
    let queue = Mutex::new(std::collections::VecDeque::from(chunks));
    stream_answer_with(move |call| {
        let default = match call.op {
            StreamOp::Open => stream_opened(),
            StreamOp::Read => match queue.lock().unwrap().pop_front() {
                Some(chunk) => stream_chunk(&chunk, false),
                None => stream_chunk(b"", true),
            },
            _ => stream_chunk(b"", false),
        };
        then(call, default)
    })
}

/// [`scripted_stream`] with the default answers.
pub fn plain_stream(chunks: &[&[u8]]) -> StreamFn {
    scripted_stream(chunks.iter().map(|c| c.to_vec()).collect(), |_, reply| {
        reply
    })
}

/// An emitter that records every event text, and the record.
pub fn collecting_emitter() -> (Emitter, Arc<Mutex<Vec<String>>>) {
    let events = Arc::new(Mutex::new(Vec::new()));
    let log = events.clone();
    let emitter: Emitter = Arc::new(move |text| {
        log.lock().unwrap().push(text);
        true
    });
    (emitter, events)
}

/// Runs `code` as `search.js` in a streaming run (read idle `idle_ms`, 0 is
/// the default) on the shared runtime; events go to `emitter`.
pub fn run_streaming_idle(
    code: &str,
    host: Arc<dyn PluginHost>,
    options: RunOptions,
    idle_ms: u32,
    emitter: Option<Emitter>,
) -> ScriptResult {
    let job = rt::begin_job();
    let mut request = request_with(job, vec![file("search.js", code)], "{}", options.timeout_ms);
    request.config = options.config;
    request.storage_json = options.storage_json;
    block_on(rt::run_streaming(request, idle_ms, host, emitter))
}

/// [`run_streaming_idle`] with the default idle time.
pub fn run_streaming(
    code: &str,
    host: Arc<dyn PluginHost>,
    options: RunOptions,
    emitter: Option<Emitter>,
) -> ScriptResult {
    run_streaming_idle(code, host, options, 0, emitter)
}

/// Everything a run can be given besides the code.
#[derive(Default)]
pub struct RunOptions {
    pub config: Vec<(String, String)>,
    pub storage_json: String,
    pub timeout_ms: u32,
}

/// Runs `code` as `search.js` with `host` answering its fetches.
pub fn run_with_host(code: &str, host: Arc<dyn PluginHost>, options: RunOptions) -> ScriptResult {
    let job = rt::begin_job();
    let mut request = request_with(job, vec![file("search.js", code)], "{}", options.timeout_ms);
    request.config = options.config;
    request.storage_json = options.storage_json;
    block_on(runtime().run(request, host))
}
