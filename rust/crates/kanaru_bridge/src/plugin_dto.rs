//! Conversions between the plugin DTOs Dart sees (`api::plugin_runtime`,
//! `api::plugin_stream`) and the runtime's own types. Kept outside `api/` so
//! codegen does not see them.
//!
//! The runtime's enums are `#[non_exhaustive]`: a variant this bridge does not
//! know maps to the nearest failure (`Internal` for a status, `Server` for an
//! error kind, `Network` for a fetch outcome or failure kind), never a panic.
//! A stream call with an unknown operation is not mapped at all: the host
//! answers it `InvalidRequest` without calling Dart. The coverage tests
//! iterate the runtime's `ALL` lists, so a new variant fails them until it is
//! mapped.

use kanaru_plugin_runtime as rt;

use crate::api::plugin_runtime::{
    PluginErrorKind, PluginFetchFailure, PluginFetchFailureKind, PluginFetchOutcome,
    PluginFetchRequest, PluginFetchResponse, PluginJsError, PluginScriptProblem,
    PluginScriptRequest, PluginScriptResult, PluginScriptStatus, PluginSourceFile,
};
use crate::api::plugin_stream::{
    PluginStreamCall, PluginStreamOp, PluginStreamOptions, PluginStreamReply,
};

impl From<PluginSourceFile> for rt::SourceFile {
    fn from(f: PluginSourceFile) -> Self {
        Self {
            name: f.name,
            code: f.code,
        }
    }
}

impl From<PluginScriptRequest> for rt::ScriptRequest {
    fn from(r: PluginScriptRequest) -> Self {
        Self {
            job: r.job,
            install_id: r.install_id,
            files: r.files.into_iter().map(Into::into).collect(),
            entry: r.entry,
            input_json: r.input_json,
            timeout_ms: r.timeout_ms,
            config: r.config,
            storage_json: r.storage_json,
        }
    }
}

impl From<rt::FetchRequest> for PluginFetchRequest {
    fn from(r: rt::FetchRequest) -> Self {
        Self {
            install_id: r.install_id,
            method: r.method,
            url: r.url,
            headers: r.headers,
            body: r.body,
            deadline_ms: r.deadline_ms,
            max_sends: r.max_sends,
        }
    }
}

impl From<PluginFetchOutcome> for rt::FetchOutcome {
    fn from(o: PluginFetchOutcome) -> Self {
        match o {
            PluginFetchOutcome::Ok => Self::Ok,
            PluginFetchOutcome::Network => Self::Network,
            PluginFetchOutcome::BlockedHost => Self::BlockedHost,
            PluginFetchOutcome::NotConsented => Self::NotConsented,
            PluginFetchOutcome::Abandoned => Self::Abandoned,
            PluginFetchOutcome::InvalidRequest => Self::InvalidRequest,
            PluginFetchOutcome::InvalidResponse => Self::InvalidResponse,
            PluginFetchOutcome::RateLimited => Self::RateLimited,
        }
    }
}

impl From<PluginFetchResponse> for rt::FetchResponse {
    fn from(r: PluginFetchResponse) -> Self {
        Self {
            outcome: r.outcome.into(),
            status: r.status,
            url: r.url,
            headers: r.headers,
            body: r.body,
            retry_after_sec: r.retry_after_sec,
            sends: r.sends,
        }
    }
}

impl PluginStreamOp {
    /// `None` for an operation this bridge does not know: it must not reach
    /// Dart, which would act on it as some other operation.
    fn from_runtime(o: rt::StreamOp) -> Option<Self> {
        match o {
            rt::StreamOp::Open => Some(Self::Open),
            rt::StreamOp::Read => Some(Self::Read),
            rt::StreamOp::Close => Some(Self::Close),
            _ => None,
        }
    }
}

impl PluginStreamCall {
    /// `None` when the call's operation is unknown to this bridge.
    pub(crate) fn from_runtime(c: rt::StreamCall) -> Option<Self> {
        Some(Self {
            op: PluginStreamOp::from_runtime(c.op)?,
            install_id: c.install_id,
            stream: c.stream,
            request: c.request.map(Into::into),
            max_bytes: c.max_bytes,
            wait_ms: c.wait_ms,
            lifetime_ms: c.lifetime_ms,
        })
    }
}

impl From<PluginStreamReply> for rt::StreamReply {
    fn from(r: PluginStreamReply) -> Self {
        Self {
            outcome: r.outcome.into(),
            status: r.status,
            url: r.url,
            headers: r.headers,
            retry_after_sec: r.retry_after_sec,
            chunk: r.chunk,
            done: r.done,
            sends: r.sends,
        }
    }
}

impl From<PluginStreamOptions> for rt::StreamOptions {
    fn from(o: PluginStreamOptions) -> Self {
        Self {
            idle_timeout_ms: o.idle_timeout_ms,
            events: o.events,
        }
    }
}

impl From<rt::ScriptStatus> for PluginScriptStatus {
    fn from(s: rt::ScriptStatus) -> Self {
        match s {
            rt::ScriptStatus::Ok => Self::Ok,
            rt::ScriptStatus::ScriptError => Self::ScriptError,
            rt::ScriptStatus::Timeout => Self::Timeout,
            rt::ScriptStatus::Memory => Self::Memory,
            rt::ScriptStatus::Stack => Self::Stack,
            rt::ScriptStatus::Cancelled => Self::Cancelled,
            rt::ScriptStatus::OutputTooLarge => Self::OutputTooLarge,
            rt::ScriptStatus::Internal => Self::Internal,
            rt::ScriptStatus::Busy => Self::Busy,
            _ => Self::Internal,
        }
    }
}

impl From<rt::ErrorKind> for PluginErrorKind {
    fn from(k: rt::ErrorKind) -> Self {
        match k {
            rt::ErrorKind::None => Self::None,
            rt::ErrorKind::RateLimited => Self::RateLimited,
            rt::ErrorKind::InvalidResponse => Self::InvalidResponse,
            rt::ErrorKind::Server => Self::Server,
            rt::ErrorKind::Auth => Self::Auth,
            rt::ErrorKind::Quota => Self::Quota,
            _ => Self::Server,
        }
    }
}

impl From<rt::FetchFailureKind> for PluginFetchFailureKind {
    fn from(k: rt::FetchFailureKind) -> Self {
        match k {
            rt::FetchFailureKind::Network => Self::Network,
            rt::FetchFailureKind::BlockedHost => Self::BlockedHost,
            rt::FetchFailureKind::NotConsented => Self::NotConsented,
            rt::FetchFailureKind::Abandoned => Self::Abandoned,
            rt::FetchFailureKind::InvalidRequest => Self::InvalidRequest,
            rt::FetchFailureKind::InvalidResponse => Self::InvalidResponse,
            rt::FetchFailureKind::RateLimited => Self::RateLimited,
            _ => Self::Network,
        }
    }
}

impl From<rt::FetchFailure> for PluginFetchFailure {
    fn from(f: rt::FetchFailure) -> Self {
        Self {
            kind: f.kind.into(),
            retry_after_sec: f.retry_after_sec,
            message: f.message,
        }
    }
}

impl From<rt::JsError> for PluginJsError {
    fn from(e: rt::JsError) -> Self {
        Self {
            message: e.message,
            stack: e.stack,
        }
    }
}

impl From<rt::ScriptResult> for PluginScriptResult {
    fn from(r: rt::ScriptResult) -> Self {
        Self {
            status: r.status.into(),
            output_json: r.output_json,
            error_message: r.error_message,
            error_kind: r.error_kind.into(),
            retry_after_sec: r.retry_after_sec,
            js_error: r.js_error.map(Into::into),
            logs: r.logs,
            fetch_failure: r.fetch_failure.map(Into::into),
            storage_json: r.storage_json,
        }
    }
}

impl From<rt::ScriptProblem> for PluginScriptProblem {
    fn from(p: rt::ScriptProblem) -> Self {
        Self {
            message: p.message,
            line: p.line,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_fetch_outcome_survives_the_trip() {
        use rt::FetchOutcome as R;
        use PluginFetchOutcome as P;
        let pairs = [
            (P::Ok, R::Ok),
            (P::Network, R::Network),
            (P::BlockedHost, R::BlockedHost),
            (P::NotConsented, R::NotConsented),
            (P::Abandoned, R::Abandoned),
            (P::InvalidRequest, R::InvalidRequest),
            (P::InvalidResponse, R::InvalidResponse),
            (P::RateLimited, R::RateLimited),
        ];
        assert_eq!(pairs.len(), R::ALL.len(), "a runtime variant has no pair");
        for runtime in R::ALL {
            let (dto, _) = pairs.iter().find(|(_, r)| r == runtime).expect("pair");
            assert_eq!(R::from(*dto), *runtime);
        }
    }

    #[test]
    fn every_script_status_maps_to_its_own_variant() {
        use rt::ScriptStatus as R;
        use PluginScriptStatus as P;
        let pairs = [
            (R::Ok, P::Ok),
            (R::ScriptError, P::ScriptError),
            (R::Timeout, P::Timeout),
            (R::Memory, P::Memory),
            (R::Stack, P::Stack),
            (R::Cancelled, P::Cancelled),
            (R::OutputTooLarge, P::OutputTooLarge),
            (R::Internal, P::Internal),
            (R::Busy, P::Busy),
        ];
        assert_eq!(pairs.len(), R::ALL.len(), "a runtime variant has no pair");
        for runtime in R::ALL {
            let (_, dto) = pairs.iter().find(|(r, _)| r == runtime).expect("pair");
            assert_eq!(P::from(*runtime), *dto);
        }
    }

    #[test]
    fn every_error_kind_maps_to_its_own_variant() {
        use rt::ErrorKind as R;
        use PluginErrorKind as P;
        let pairs = [
            (R::None, P::None),
            (R::RateLimited, P::RateLimited),
            (R::InvalidResponse, P::InvalidResponse),
            (R::Server, P::Server),
            (R::Auth, P::Auth),
            (R::Quota, P::Quota),
        ];
        assert_eq!(pairs.len(), R::ALL.len(), "a runtime variant has no pair");
        for runtime in R::ALL {
            let (_, dto) = pairs.iter().find(|(r, _)| r == runtime).expect("pair");
            assert_eq!(P::from(*runtime), *dto);
        }
    }

    #[test]
    fn every_fetch_failure_kind_maps_to_its_own_variant() {
        use rt::FetchFailureKind as R;
        use PluginFetchFailureKind as P;
        let pairs = [
            (R::Network, P::Network),
            (R::BlockedHost, P::BlockedHost),
            (R::NotConsented, P::NotConsented),
            (R::Abandoned, P::Abandoned),
            (R::InvalidRequest, P::InvalidRequest),
            (R::InvalidResponse, P::InvalidResponse),
            (R::RateLimited, P::RateLimited),
        ];
        assert_eq!(pairs.len(), R::ALL.len(), "a runtime variant has no pair");
        for runtime in R::ALL {
            let (_, dto) = pairs.iter().find(|(r, _)| r == runtime).expect("pair");
            assert_eq!(P::from(*runtime), *dto);
        }
    }

    #[test]
    fn every_stream_op_maps_to_its_own_variant() {
        use rt::StreamOp as R;
        use PluginStreamOp as P;
        let pairs = [(R::Open, P::Open), (R::Read, P::Read), (R::Close, P::Close)];
        assert_eq!(pairs.len(), R::ALL.len(), "a runtime variant has no pair");
        for runtime in R::ALL {
            let (_, dto) = pairs.iter().find(|(r, _)| r == runtime).expect("pair");
            assert_eq!(PluginStreamOp::from_runtime(*runtime), Some(*dto));
        }
    }

    #[test]
    fn a_stream_call_keeps_its_fields_and_nested_request() {
        let call = rt::StreamCall {
            install_id: "p1".into(),
            stream: 7,
            op: rt::StreamOp::Open,
            request: Some(rt::FetchRequest {
                install_id: "p1".into(),
                method: "GET".into(),
                url: "https://a.test/".into(),
                headers: vec![("k".into(), "v".into())],
                body: vec![1, 2],
                deadline_ms: 900,
                max_sends: 3,
            }),
            max_bytes: 4,
            wait_ms: 5,
            lifetime_ms: 6,
        };
        let dto = PluginStreamCall::from_runtime(call).expect("known op");
        assert_eq!(
            (dto.install_id.as_str(), dto.stream, dto.op),
            ("p1", 7, PluginStreamOp::Open)
        );
        let req = dto.request.expect("request");
        assert_eq!(
            (req.url.as_str(), req.deadline_ms, req.max_sends),
            ("https://a.test/", 900, 3)
        );
        assert_eq!((dto.max_bytes, dto.wait_ms, dto.lifetime_ms), (4, 5, 6));
    }
}
