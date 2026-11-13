//! The data that crosses the runtime boundary: what a caller asks to run, what
//! the host is asked to fetch, and how a run ended.
//!
//! Flat and plain on purpose: the bridge maps each type one to one onto its
//! own FFI types. Enums are `#[non_exhaustive]`, so a variant added later does
//! not break callers that match on them.

use std::future::Future;
use std::pin::Pin;

/// A boxed future the host answers with. Same shape as the bridge's own
/// callback future, without depending on the bridge.
pub type Pending<T> = Pin<Box<dyn Future<Output = T> + Send + 'static>>;

/// One file of the plugin's `src/` folder, already read and size-checked.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourceFile {
    /// File name without a folder, e.g. `search.js` or `util.js`.
    pub name: String,
    pub code: String,
}

/// What to run.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScriptRequest {
    /// Id from `PluginRuntime::begin_job`.
    pub job: u32,
    /// Identity of the installed plugin; copied into every fetch and stream
    /// call the run makes, so the host can keep per-plugin state (cookies).
    pub install_id: String,
    /// All files of the package's `src/` folder; `load()` can only reach these.
    pub files: Vec<SourceFile>,
    /// Name of the file to run first; must be in `files`.
    pub entry: String,
    /// JSON text that becomes the argument of the global `execute(input)`.
    pub input_json: String,
    /// Wall-time limit in milliseconds. 0 means 15 000; more than 90 000
    /// means 90 000. The clock starts when a worker begins the job: time spent
    /// waiting in the queue is not counted, so the caller keeps its own outer
    /// deadline.
    pub timeout_ms: u32,
    /// The plugin's configuration, readable by the script as
    /// `localConfig.getItem(key)`. Each value is JSON text. Secrets included;
    /// the runtime never puts these values in a log line or an error text.
    pub config: Vec<(String, String)>,
    /// The plugin's stored map as a JSON object of strings (`localStorage`).
    /// Empty text means nothing stored.
    pub storage_json: String,
}

/// One `fetch` of the script, handed to the host.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FetchRequest {
    /// Identity of the plugin that asked (see [`ScriptRequest::install_id`]).
    pub install_id: String,
    /// `GET` or `POST`.
    pub method: String,
    /// The script's URL with its `queries` already appended and encoded.
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
    /// What is left of the call's wall time (15 s by default, at most 90 s).
    pub deadline_ms: u32,
    /// HTTP sends still allowed for this call (10 minus the sends used so
    /// far), at least 1. The host must not make more, retries included.
    pub max_sends: u32,
}

/// How the host answered a [`FetchRequest`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum FetchOutcome {
    /// A response arrived; `status`, `url`, `headers` and `body` are set.
    Ok,
    /// Connection, TLS, timeout or similar.
    Network,
    /// The host is not on the plugin's allowlist.
    BlockedHost,
    /// The user has not allowed this plugin to use the network.
    NotConsented,
    /// The user stopped the lookup; the job ends `Cancelled`.
    Abandoned,
    /// The host refused the request (method, header or body).
    InvalidRequest,
    /// The host refused the answer (e.g. a body over 4 MiB).
    InvalidResponse,
    /// The server asked to slow down; see `retry_after_sec`.
    RateLimited,
}

/// The host's answer to a [`FetchRequest`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FetchResponse {
    pub outcome: FetchOutcome,
    /// HTTP status; 0 unless `outcome` is `Ok`.
    pub status: u16,
    /// The final URL after redirects.
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
    /// For `RateLimited`: the server's `Retry-After` in seconds, if it gave one.
    pub retry_after_sec: Option<u32>,
    /// HTTP sends made for this request, retries counted. The runtime adds
    /// them up and refuses further fetches after 10 in one call.
    pub sends: u32,
}

/// How a run ended.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum ScriptStatus {
    /// `execute` returned `Response.success`; `output_json` holds its data.
    Ok,
    /// The script threw, failed to compile, broke the contract (no `execute`,
    /// not a `Response`, bad `load()`), or returned `Response.error`.
    ScriptError,
    /// The wall-time limit passed (15 s by default, at most 90 s).
    Timeout,
    /// The 32 MiB heap limit (or the Rust byte budget) was hit.
    Memory,
    /// The script stack limit (1 MiB) was hit.
    Stack,
    /// The job was cancelled (or its id was unknown or already cancelled).
    Cancelled,
    /// The returned data is larger than 2 MiB as JSON.
    OutputTooLarge,
    /// The runtime failed (a worker panicked, the request was malformed).
    /// Not the script's fault.
    Internal,
    /// All workers were busy and the queue was full. Nothing ran.
    Busy,
}

/// Kind of a script-reported failure.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum ErrorKind {
    /// Not a script-reported failure.
    None,
    /// The source asked to slow down; see `retry_after_sec`.
    RateLimited,
    /// The script returned something that is not a `Response`, threw an
    /// error, or has no `execute`.
    InvalidResponse,
    /// Default kind of `Response.error`.
    Server,
    /// The source refused the credentials (bad or missing key).
    Auth,
    /// The account's quota is used up; see `retry_after_sec`.
    Quota,
}

/// A JavaScript exception: its message and stack (file names and line numbers kept).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct JsError {
    pub message: String,
    /// Empty when the engine gave no stack.
    pub stack: String,
}

/// Why the first failing host `fetch` of a call failed (same names as
/// [`FetchOutcome`]). A call that used up its 10 sends reports `InvalidRequest`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum FetchFailureKind {
    Network,
    BlockedHost,
    NotConsented,
    Abandoned,
    InvalidRequest,
    InvalidResponse,
    RateLimited,
}

/// The first failing `fetch` of a call, kept even when the script caught the error.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FetchFailure {
    pub kind: FetchFailureKind,
    pub retry_after_sec: Option<u32>,
    /// Runtime-made text; never contains configuration values.
    pub message: String,
}

/// Result of one run. Every field is filled on every status: `logs`,
/// `js_error` and `fetch_failure` are returned even when the run failed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScriptResult {
    pub status: ScriptStatus,
    /// JSON of the `data` given to `Response.success`. Empty unless `Ok`.
    pub output_json: String,
    /// Human text for every status except `Ok`: the `Response.error` message,
    /// the exception message, or what the runtime enforced.
    pub error_message: String,
    /// Set for `Response.error`, `InvalidResponse` and thrown exceptions.
    pub error_kind: ErrorKind,
    /// From `Response.error(message, {retryAfterSec})`.
    pub retry_after_sec: Option<u32>,
    /// The JavaScript exception that ended the run, when the engine had one.
    /// `None` when no script code was running (cancelled before start, busy,
    /// internal) or the failure was found by the host after `execute` returned.
    pub js_error: Option<JsError>,
    /// Console lines captured before the run ended, whatever the status.
    pub logs: Vec<String>,
    /// First failing host `fetch`, whatever the status.
    pub fetch_failure: Option<FetchFailure>,
    /// The plugin's whole new storage map as JSON, only when the script
    /// changed it and finished on its own (`Ok` or `ScriptError`).
    pub storage_json: Option<String>,
}

/// A syntax error found by the compile-only check.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScriptProblem {
    pub message: String,
    /// 1-based line; 0 when unknown.
    pub line: u32,
}

/// What a [`StreamCall`] asks for.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum StreamOp {
    /// Send `request` and answer once the headers arrived.
    Open,
    /// Wait up to `wait_ms` for bytes and return at most `max_bytes` of them.
    Read,
    /// Close the connection of the stream. Answered with outcome `Ok`.
    Close,
}

/// One call from the runtime to the host about a stream.
///
/// The host owns cleanup: it keeps one stream table per run and closes every
/// stream still open when the run ends or is cancelled (Rust sends no `Close`
/// for them). An `Open` answered after the run ended closes at once; a
/// `Close` can arrive while that stream's `Open` is pending.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StreamCall {
    /// Identity of the plugin that asked (see [`ScriptRequest::install_id`]).
    pub install_id: String,
    /// Stream id, made by the runtime and unique within the run.
    pub stream: u32,
    pub op: StreamOp,
    /// For `Open` only.
    pub request: Option<FetchRequest>,
    /// For `Read`: most bytes to return; 0 otherwise.
    pub max_bytes: u32,
    /// For `Read`: longest wait for bytes, milliseconds; 0 otherwise.
    pub wait_ms: u32,
    /// For `Open`: what is left of the run's wall time, milliseconds; the host
    /// closes the stream by itself when it has passed. 0 otherwise.
    pub lifetime_ms: u32,
}

/// The host's answer to a [`StreamCall`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StreamReply {
    /// `Ok`, or the reason the call failed (`Network` also stands for idle).
    pub outcome: FetchOutcome,
    /// For `Open`: HTTP status; 0 otherwise.
    pub status: u16,
    /// For `Open`: the final URL after redirects.
    pub url: String,
    /// For `Open`: the response headers.
    pub headers: Vec<(String, String)>,
    /// For `Open` with `RateLimited`: the server's `Retry-After` in seconds.
    pub retry_after_sec: Option<u32>,
    /// For `Read`: the bytes that arrived, at most `max_bytes`. Never empty
    /// unless `done`.
    pub chunk: Vec<u8>,
    /// For `Read`: the body ended; an empty `chunk` with `done` is the end.
    pub done: bool,
    /// For `Open`: HTTP sends made, retries counted (shared with `fetch`).
    pub sends: u32,
}

/// How a streaming run behaves.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StreamOptions {
    /// Longest wait for data in one stream read, milliseconds; 0 is the
    /// default (60 s). Values are clamped to 1 to 90 s.
    pub idle_timeout_ms: u32,
    /// True: the run sends `emit` events to the receiver attached to the job.
    pub events: bool,
}
