//! Mapping of every way a run can end to a [`ScriptResult`].

use std::time::Duration;

use crate::globals::{Finished, JsFailure, RunFailure};
use crate::host::{STOP_CANCELLED, STOP_INTERNAL, STOP_NONE, STOP_TIMEOUT};
use crate::limits::{MAX_OUTPUT_BYTES, MEMORY_LIMIT_BYTES};
use crate::types::{ErrorKind, JsError, ScriptResult, ScriptStatus};

/// A result with no script output; `logs`, `fetch_failure` and `storage_json`
/// are added from the collector by `run_job`.
pub fn failure(status: ScriptStatus, message: impl Into<String>) -> ScriptResult {
    ScriptResult {
        status,
        output_json: String::new(),
        error_message: message.into(),
        error_kind: ErrorKind::None,
        retry_after_sec: None,
        js_error: None,
        logs: Vec::new(),
        fetch_failure: None,
        storage_json: None,
    }
}

/// The result of a script that ran: what `execute` returned or how it failed,
/// then the checks that override it (a swallowed stop, a memory overrun).
/// `stop` is the stop reason read after the script ended.
pub(super) fn settle(
    outcome: Result<Finished, RunFailure>,
    stop: u8,
    memory_hit: bool,
    budget_hit: bool,
    timeout: Duration,
) -> ScriptResult {
    let result = match outcome {
        Ok(Finished::Success { output_json }) => ScriptResult {
            output_json,
            ..failure(ScriptStatus::Ok, "")
        },
        Ok(Finished::ScriptError {
            message,
            kind,
            retry_after_sec,
        }) => ScriptResult {
            error_kind: kind,
            retry_after_sec,
            ..failure(ScriptStatus::ScriptError, message)
        },
        Err(RunFailure::Js(f)) => map_js_failure(f, stop, memory_hit, timeout),
        // A missing `execute` or a return that is not a `Response` is a bug of
        // the plugin, not a failure of a server.
        Err(RunFailure::Contract(message)) | Err(RunFailure::InvalidResponse(message)) => {
            ScriptResult {
                error_kind: ErrorKind::InvalidResponse,
                ..failure(ScriptStatus::ScriptError, message)
            }
        }
        Err(RunFailure::OutputTooLarge) => failure(
            ScriptStatus::OutputTooLarge,
            format!("the output is larger than the limit of {MAX_OUTPUT_BYTES} bytes of JSON"),
        ),
    };
    // A blocked host call (fetch, sleep) that saw the cancel or the deadline
    // throws a catchable error. If the script swallowed it and went on, the
    // call still ends as cancelled / timed out, never as a normal result.
    if stop != STOP_NONE && result.js_error.is_none() {
        let (status, message) = stop_status(stop, timeout);
        return failure(status, message);
    }
    // The Rust byte budget was overrun, or the QuickJS heap cap refused an
    // allocation, at some point: the call is `memory` even if the script
    // caught the error and returned normally.
    if (budget_hit || memory_hit)
        && !matches!(
            result.status,
            ScriptStatus::Cancelled | ScriptStatus::Timeout
        )
    {
        return ScriptResult {
            js_error: result.js_error,
            ..failure(ScriptStatus::Memory, memory_message())
        };
    }
    result
}

fn memory_message() -> String {
    format!(
        "the script used more than {} MiB of memory",
        MEMORY_LIMIT_BYTES >> 20
    )
}

/// Text of a run stopped because a host function panicked.
const INTERNAL_MESSAGE: &str = "a host function failed internally";

/// Status and text of a run stopped by cancel, deadline or an internal failure.
fn stop_status(stop: u8, timeout: Duration) -> (ScriptStatus, String) {
    if stop == STOP_CANCELLED {
        (ScriptStatus::Cancelled, "cancelled".to_owned())
    } else if stop == STOP_INTERNAL {
        (ScriptStatus::Internal, INTERNAL_MESSAGE.to_owned())
    } else {
        (
            ScriptStatus::Timeout,
            format!("the script ran longer than {} ms", timeout.as_millis()),
        )
    }
}

/// The engine's own stack-limit exception: a `RangeError` or `InternalError`
/// with its exact message. (A script can still throw one by hand; that only
/// changes its own status.)
fn is_engine_stack_overflow(f: &JsFailure) -> bool {
    matches!(f.name.as_str(), "RangeError" | "InternalError")
        && matches!(
            f.message.as_str(),
            "Maximum call stack size exceeded" | "stack overflow"
        )
}

/// Status of a run the engine ended with an exception. The interrupt reason
/// and the allocator's memory flag come first (a script cannot fake them: an
/// out-of-memory error may even reach the script as a bare `null`); then the
/// engine's own stack message.
pub(super) fn map_js_failure(
    f: JsFailure,
    stop: u8,
    memory_hit: bool,
    timeout: Duration,
) -> ScriptResult {
    let (status, error_kind, message) = match stop {
        STOP_CANCELLED => (
            ScriptStatus::Cancelled,
            ErrorKind::None,
            "cancelled".to_owned(),
        ),
        STOP_TIMEOUT => (
            ScriptStatus::Timeout,
            ErrorKind::None,
            format!("the script ran longer than {} ms", timeout.as_millis()),
        ),
        STOP_INTERNAL => (
            ScriptStatus::Internal,
            ErrorKind::None,
            INTERNAL_MESSAGE.to_owned(),
        ),
        _ if memory_hit => (ScriptStatus::Memory, ErrorKind::None, memory_message()),
        _ if is_engine_stack_overflow(&f) => (
            ScriptStatus::Stack,
            ErrorKind::None,
            "the script nested calls too deeply".to_owned(),
        ),
        // A thrown error is a bug of the plugin, not a failure of a server.
        _ => (
            ScriptStatus::ScriptError,
            ErrorKind::InvalidResponse,
            f.message.clone(),
        ),
    };
    ScriptResult {
        error_kind,
        js_error: Some(JsError {
            message: f.message,
            stack: f.stack,
        }),
        ..failure(status, message)
    }
}
