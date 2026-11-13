//! Streaming plugin runs for Dart: the stream callback types (how the runtime
//! asks Dart to open, read and close the body of a streamed `fetch`) and the
//! two functions [`plugin_job_events`] and [`run_plugin_stream_script`].
//!
//! A streaming run is: `begin_plugin_job`, then `plugin_job_events` (sync, so
//! the sink is attached before the run starts), then
//! `run_plugin_stream_script` with `events: true`. `emit` events flow into the
//! sink; it closes when the run ends.

use std::sync::Arc;

use flutter_rust_bridge::DartFnFuture;

use super::plugin_runtime::{
    PluginFetchOutcome, PluginFetchRequest, PluginFetchResponse, PluginScriptRequest,
    PluginScriptResult,
};
use crate::frb_generated::StreamSink;
use crate::host_dart::DartHost;
use crate::runtime_holder::runtime;

/// What a [`PluginStreamCall`] asks for.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum PluginStreamOp {
    /// Send `request` and answer once the headers arrived.
    Open,
    /// Wait up to `wait_ms` for bytes, return at most `max_bytes`.
    Read,
    /// Close the connection; answered with outcome `Ok`.
    Close,
}

/// One call from the runtime to Dart about a stream.
///
/// Dart keeps one stream table per run and closes every stream still open
/// when the run ends or is cancelled. During a run Rust sends `Close` when the
/// script calls `close()`, after a stream failed, and when an `Open` was
/// answered too late; it sends no `Close` for streams still open when the run
/// ends or is cancelled, and a cancel can stop a `Close` before it is sent.
/// An `Open` answered after
/// the run ended is closed at once. A `Close` can arrive while that stream's
/// `Open` is still pending. Callbacks must not throw (a throw is a network
/// failure) and Dart keeps its own outer deadline.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginStreamCall {
    /// Plugin that asked.
    pub install_id: String,
    /// Stream id, unique within the run.
    pub stream: u32,
    pub op: PluginStreamOp,
    /// For `Open` only.
    pub request: Option<PluginFetchRequest>,
    /// For `Read`: most bytes to return; 0 otherwise.
    pub max_bytes: u32,
    /// For `Read`: longest wait for bytes, ms; 0 otherwise.
    pub wait_ms: u32,
    /// For `Open`: wall time left for the run, ms; Dart closes the stream by
    /// itself once it has passed. 0 otherwise.
    pub lifetime_ms: u32,
}

/// Dart's answer to a [`PluginStreamCall`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PluginStreamReply {
    /// `Ok`, or why the call failed (`Network` also stands for idle).
    pub outcome: PluginFetchOutcome,
    /// For `Open`: HTTP status; 0 otherwise.
    pub status: u16,
    /// For `Open`: final URL after redirects.
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub retry_after_sec: Option<u32>,
    /// For `Read`: bytes that arrived, at most `max_bytes`. Never empty unless
    /// `done`: an `Ok` reply with an empty chunk and `done == false` is
    /// refused and the stream is dead. Idle with no bytes, or a dropped
    /// connection, is outcome `Network`.
    pub chunk: Vec<u8>,
    /// For `Read`: the body ended (Dart has closed the stream); an empty
    /// `chunk` with `done` is the end.
    pub done: bool,
    /// For `Open`: HTTP sends made, retries counted.
    pub sends: u32,
}

/// How a streaming run behaves.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PluginStreamOptions {
    /// Longest wait for data in one read, ms; 0 is 60 s, clamped to 1..90 s.
    pub idle_timeout_ms: u32,
    /// True: `emit` events go to the sink attached with [`plugin_job_events`];
    /// none attached ends the run `Internal`.
    pub events: bool,
}

/// Attaches `sink` to job `job`, which must be begun and not yet running.
/// Events of `emit` arrive as JSON texts; the stream closes when the run
/// ends. For an unknown, running, cancelled or already attached id the sink
/// is dropped at once, so the Dart stream closes empty. A failed `add` (Dart
/// side gone, e.g. hot restart) only drops the event.
///
/// Sync on purpose: it has run when the Dart call returns, so it is attached
/// before [`run_plugin_stream_script`] starts.
#[flutter_rust_bridge::frb(sync)]
pub fn plugin_job_events(job: u32, sink: StreamSink<String>) {
    runtime().attach_job_events(job, Arc::new(move |json| sink.add(json).is_ok()));
}

/// Streaming run: like [`super::plugin_runtime::run_plugin_script`] (same
/// rules for `fetch`, cancel and the outer deadline), plus `emit` events and
/// streamed fetch bodies through `stream`, with a hard cap of 300 s. When the
/// stream worker is busy the result status is `Busy`.
///
/// `fetch` answers plain `fetch` calls, `stream` the open, read and close
/// calls of streamed ones; both run on the JS thread and must not throw.
pub async fn run_plugin_stream_script(
    request: PluginScriptRequest,
    options: PluginStreamOptions,
    fetch: impl Fn(PluginFetchRequest) -> DartFnFuture<PluginFetchResponse> + Send + Sync + 'static,
    stream: impl Fn(PluginStreamCall) -> DartFnFuture<PluginStreamReply> + Send + Sync + 'static,
) -> PluginScriptResult {
    let host = Arc::new(DartHost::new(Arc::new(fetch), Some(Arc::new(stream))));
    runtime()
        .run_streaming(request.into(), options.into(), host, None)
        .await
        .into()
}
