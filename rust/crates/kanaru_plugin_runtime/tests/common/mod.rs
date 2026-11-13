//! Helpers shared by the integration tests: a tiny executor, request builders
//! and one lazily built [`PluginRuntime`] per test binary.
//!
//! Every test starts with `let _t = common::test();`. That takes the binary's
//! serial lock (tests that fill the worker pool must not overlap others),
//! resets the shared runtime, and on drop resets it again so a job a failed
//! test left blocked is cancelled before the next test starts.

#![allow(dead_code, clippy::unwrap_used)]

use std::future::Future;
use std::sync::{Arc, Mutex, MutexGuard, OnceLock};
use std::task::{Context, Poll, Wake, Waker};
use std::thread;
use std::time::{Duration, Instant};

use kanaru_plugin_runtime::{
    NoNetwork, Pending, PluginRuntime, RuntimeConfig, ScriptRequest, ScriptResult, SourceFile,
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
