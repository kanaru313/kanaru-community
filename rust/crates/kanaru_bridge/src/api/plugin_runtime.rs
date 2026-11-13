//! Plugin runtime API for Dart: runs a plugin's JavaScript (`search.js`,
//! `lyrics.js`, ...) in the sandboxed QuickJS runtime.
//!
//! A run is: [`begin_plugin_job`] hands out a job id, [`run_plugin_script`]
//! runs the script under it, [`cancel_plugin_job`] (from another call) stops
//! it. [`check_plugin_script`] only compiles, to report syntax errors at
//! install time. [`reset_plugin_runtime`] frees every worker; Dart calls it
//! once at startup so a hot restart does not leave workers held by a dead
//! isolate.
//!
//! DTOs are flat and explicit; conversions live in `crate::plugin_dto`. After
//! the runtime gains an enum variant, regenerate the bindings: exhaustive Dart
//! `switch`es then flag the new variant.
//!
//! Only `///` comments reach the generated Dart, so the rules Dart must keep
//! are written on the items below.

use std::sync::Arc;

use flutter_rust_bridge::DartFnFuture;

use crate::host_dart::DartHost;
use crate::runtime_holder::{existing, runtime};

/// One file of the plugin's `src/` folder, already read and size-checked.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginSourceFile {
    /// File name without a folder, e.g. `search.js`.
    pub name: String,
    pub code: String,
}

/// What to run.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginScriptRequest {
    /// Id from [`begin_plugin_job`].
    pub job: u32,
    /// Identity of the installed plugin; copied into every fetch and stream
    /// call of the run so Dart can keep per-plugin state (cookies). Must not
    /// be empty: an empty id ends the run `Internal` without running the script.
    pub install_id: String,
    /// All files of the package's `src/` folder; `load()` reaches only these.
    pub files: Vec<PluginSourceFile>,
    /// File to run first; must be in `files`.
    pub entry: String,
    /// JSON text passed to the global `execute(input)`.
    pub input_json: String,
    /// Wall-time limit in ms: 0 means 15 000, above 90 000 means 90 000. The
    /// clock starts when a worker begins the job, not while it queues, so the
    /// caller keeps its own outer deadline.
    pub timeout_ms: u32,
    /// Plugin configuration for `localConfig.getItem(key)`; values are JSON
    /// text. Secrets included: never logged by the runtime.
    pub config: Vec<(String, String)>,
    /// The plugin's stored map (`localStorage`) as a JSON object of strings;
    /// empty text means nothing stored.
    pub storage_json: String,
}

/// One `fetch` of the script, handed to Dart.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginFetchRequest {
    /// Plugin that asked (see [`PluginScriptRequest::install_id`]).
    pub install_id: String,
    /// `GET` or `POST`.
    pub method: String,
    /// The script's URL with its queries already appended and encoded.
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
    /// Wall time left for this call, ms (15 s by default, at most 90 s). Dart
    /// uses the smaller of this and 30 s as the overall timeout.
    pub deadline_ms: u32,
    /// HTTP sends still allowed for this call (10 minus the sends used so
    /// far), at least 1. Dart must not make more, retries included; a larger
    /// `sends` in the answer is counted as this value.
    pub max_sends: u32,
}

/// How Dart answered a fetch (or a stream call).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum PluginFetchOutcome {
    /// A response arrived; `status`, `url`, `headers`, `body` are set.
    Ok,
    Network,
    /// The host is not on the plugin's allowlist.
    BlockedHost,
    /// The user has not allowed this plugin to use the network.
    NotConsented,
    /// The user stopped the lookup; the job ends `Cancelled`.
    Abandoned,
    InvalidRequest,
    InvalidResponse,
    /// The server asked to slow down; see `retry_after_sec`.
    RateLimited,
}

/// Dart's answer to a [`PluginFetchRequest`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginFetchResponse {
    pub outcome: PluginFetchOutcome,
    /// HTTP status; 0 unless `outcome` is `Ok`.
    pub status: u16,
    /// Final URL after redirects.
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
    /// For `RateLimited`: the server's `Retry-After` in seconds, if given.
    pub retry_after_sec: Option<u32>,
    /// HTTP sends made for this request, retries counted. The runtime adds
    /// them up and refuses further fetches after 10 in one call.
    pub sends: u32,
}

/// How a run ended.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum PluginScriptStatus {
    Ok,
    /// Threw, failed to compile, broke the contract, or `Response.error`.
    ScriptError,
    Timeout,
    Memory,
    Stack,
    Cancelled,
    OutputTooLarge,
    /// The runtime failed; not the script's fault.
    Internal,
    /// All workers busy and the queue full. Nothing ran: skip the source for
    /// this lookup, record no failure and start no pause.
    Busy,
}

/// Kind of a script-reported failure.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum PluginErrorKind {
    None,
    RateLimited,
    InvalidResponse,
    Server,
    Auth,
    Quota,
}

/// A JavaScript exception.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginJsError {
    pub message: String,
    /// Empty when the engine gave no stack.
    pub stack: String,
}

/// Why the first failing host `fetch` of a run failed.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum PluginFetchFailureKind {
    Network,
    BlockedHost,
    NotConsented,
    Abandoned,
    InvalidRequest,
    InvalidResponse,
    RateLimited,
}

/// The first failing `fetch` of a run, kept even when the script caught it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginFetchFailure {
    pub kind: PluginFetchFailureKind,
    pub retry_after_sec: Option<u32>,
    /// Runtime-made text; never contains configuration values.
    pub message: String,
}

/// Result of one run. Every field is filled whatever the status.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginScriptResult {
    pub status: PluginScriptStatus,
    /// JSON of the data given to `Response.success`; empty unless `Ok`.
    pub output_json: String,
    /// Human text for every status except `Ok`.
    pub error_message: String,
    pub error_kind: PluginErrorKind,
    pub retry_after_sec: Option<u32>,
    pub js_error: Option<PluginJsError>,
    /// Console lines captured before the run ended.
    pub logs: Vec<String>,
    pub fetch_failure: Option<PluginFetchFailure>,
    /// The new storage map as JSON, only when the script changed it and
    /// finished on its own (`Ok` or `ScriptError`).
    pub storage_json: Option<String>,
}

/// A syntax error found by the compile-only check.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginScriptProblem {
    pub message: String,
    /// 1-based line; 0 when unknown.
    pub line: u32,
}

/// Registers a job and returns its id. Pass every begun id to a run, or call
/// [`cancel_plugin_job`] / [`reset_plugin_runtime`]; an id that is never run
/// stays registered until then.
#[flutter_rust_bridge::frb(sync)]
pub fn begin_plugin_job() -> u32 {
    runtime().begin_job()
}

/// Cancels a job: queued ends `Cancelled` at once, running stops at its next
/// interrupt. An unknown or finished id does nothing.
#[flutter_rust_bridge::frb(sync)]
pub fn cancel_plugin_job(job: u32) {
    if let Some(runtime) = existing() {
        runtime.cancel_job(job);
    }
}

/// Cancels every job (running, queued, streaming) and forgets unstarted ids.
///
/// Call it once at startup, from the main isolate, so a hot restart does not
/// leave workers held by a dead isolate. It cancels the jobs of every isolate
/// in the process, so never call it from a second one. Does nothing (and
/// starts no threads) when no plugin ran yet.
#[flutter_rust_bridge::frb(sync)]
pub fn reset_plugin_runtime() {
    if let Some(runtime) = existing() {
        runtime.reset();
    }
}

/// Runs the script on the runtime's workers; never blocks a sync call.
///
/// `fetch` is Dart's HTTP, called on a JS thread with a [`PluginFetchRequest`].
/// It must not throw: a throw is reported to the script as a network failure.
/// Answer every failure with the matching [`PluginFetchOutcome`] instead.
///
/// Only [`cancel_plugin_job`] cancels the job; the returned Future cannot be
/// dropped to cancel it. The wall-time limit does not count the queue wait, so
/// keep an outer deadline of your own. An all-busy runtime answers `Busy`.
///
/// A script that throws (or returns something that is not a `Response`) ends
/// `ScriptError` with kind `InvalidResponse`; an empty `install_id` ends
/// `Internal`.
pub async fn run_plugin_script(
    request: PluginScriptRequest,
    fetch: impl Fn(PluginFetchRequest) -> DartFnFuture<PluginFetchResponse> + Send + Sync + 'static,
) -> PluginScriptResult {
    let host = Arc::new(DartHost::new(Arc::new(fetch), None));
    runtime().run(request.into(), host).await.into()
}

/// Compiles `code` only; `None` when it parses.
pub fn check_plugin_script(name: String, code: String) -> Option<PluginScriptProblem> {
    runtime().check_script(&name, &code).map(Into::into)
}
