//! [`PluginHost`] backed by the Dart callbacks of one run.

use std::sync::Arc;

use flutter_rust_bridge::DartFnFuture;
use kanaru_plugin_runtime::{
    failed_stream_reply, FetchOutcome, FetchRequest, FetchResponse, Pending, PluginHost,
    StreamCall, StreamReply,
};

use crate::api::plugin_runtime::{PluginFetchRequest, PluginFetchResponse};
use crate::api::plugin_stream::{PluginStreamCall, PluginStreamReply};

pub type FetchCallback =
    Arc<dyn Fn(PluginFetchRequest) -> DartFnFuture<PluginFetchResponse> + Send + Sync>;
pub type StreamCallback =
    Arc<dyn Fn(PluginStreamCall) -> DartFnFuture<PluginStreamReply> + Send + Sync>;

/// Forwards the runtime's host calls to Dart. A Dart callback that throws
/// panics inside frb's future; the runtime catches that and reports a
/// `network` outcome.
pub struct DartHost {
    fetch: FetchCallback,
    /// `None` for runs without streaming: stream calls then fail `Network`.
    stream: Option<StreamCallback>,
}

impl DartHost {
    pub fn new(fetch: FetchCallback, stream: Option<StreamCallback>) -> Self {
        Self { fetch, stream }
    }
}

impl PluginHost for DartHost {
    fn fetch(&self, request: FetchRequest) -> Pending<FetchResponse> {
        // `DartFnFuture` and `Pending` are the same boxed future type.
        let answer = (self.fetch)(request.into());
        Box::pin(async move { answer.await.into() })
    }

    fn stream(&self, call: StreamCall) -> Pending<StreamReply> {
        match &self.stream {
            Some(stream) => match PluginStreamCall::from_runtime(call) {
                Some(dto) => {
                    let answer = stream(dto);
                    Box::pin(async move { answer.await.into() })
                }
                // An operation this bridge does not know is refused, never
                // sent to Dart.
                None => Box::pin(async { failed_stream_reply(FetchOutcome::InvalidRequest) }),
            },
            None => Box::pin(async { failed_stream_reply(FetchOutcome::Network) }),
        }
    }
}
