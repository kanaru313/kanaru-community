//! The call of the global `execute(input)` and the check of what it returned.

use rquickjs::{Ctx, Object, Value};

use super::{describe_error, Helpers, JsFailure};
use crate::limits::{MAX_ERROR_MESSAGE_CHARS, MAX_OUTPUT_BYTES};
use crate::types::ErrorKind;

/// Why a run did not end in a `Response`.
#[derive(Debug)]
pub enum RunFailure {
    /// The engine threw: an exception, a limit, an interrupt.
    Js(JsFailure),
    /// The script broke the contract (no `execute`, bad `load()` name found
    /// by the host, ...); text made by the runtime.
    Contract(String),
    /// `execute` did not return a `Response`.
    InvalidResponse(String),
    /// The data is larger than the output cap.
    OutputTooLarge,
}

/// A `Response` the script returned.
#[derive(Debug)]
pub enum Finished {
    Success {
        output_json: String,
    },
    ScriptError {
        message: String,
        kind: ErrorKind,
        retry_after_sec: Option<u32>,
    },
}

/// Calls the global `execute(input)` and checks what it returned.
pub fn call_execute<'js>(
    ctx: &Ctx<'js>,
    input: Value<'js>,
    helpers: &Helpers<'js>,
) -> Result<Finished, RunFailure> {
    let execute: Value = ctx
        .globals()
        .get("execute")
        .map_err(|e| RunFailure::Js(describe_error(ctx, e)))?;
    let Some(execute) = execute.as_function() else {
        return Err(RunFailure::Contract(
            "the entry script must define a global function execute(input)".to_owned(),
        ));
    };
    let returned: Value = execute
        .call((input,))
        .map_err(|e| RunFailure::Js(describe_error(ctx, e)))?;
    let branded: bool = helpers
        .is_response
        .call((returned.clone(),))
        .map_err(|e| RunFailure::Js(describe_error(ctx, e)))?;
    if !branded {
        return Err(RunFailure::InvalidResponse(
            "execute must return Response.success or Response.error".to_owned(),
        ));
    }
    let response: Object = returned
        .into_object()
        .ok_or_else(|| RunFailure::Contract("response is not an object".to_owned()))?;
    read_response(ctx, &response, helpers)
}

fn read_response<'js>(
    ctx: &Ctx<'js>,
    response: &Object<'js>,
    helpers: &Helpers<'js>,
) -> Result<Finished, RunFailure> {
    let js = |e| RunFailure::Js(describe_error(ctx, e));
    let ok: bool = response.get("ok").map_err(js)?;
    if ok {
        let data: Value = response.get("data").map_err(js)?;
        let json = match ctx.json_stringify(data).map_err(js)? {
            Some(s) => {
                // UTF-8 is never shorter than the UTF-16 length QuickJS keeps,
                // so a longer string is refused before it is copied.
                let units: usize = helpers.length_of.call((s.clone(),)).map_err(js)?;
                if units > MAX_OUTPUT_BYTES {
                    return Err(RunFailure::OutputTooLarge);
                }
                s.to_string().map_err(js)?
            }
            None => "null".to_owned(), // `undefined` data
        };
        if json.len() > MAX_OUTPUT_BYTES {
            return Err(RunFailure::OutputTooLarge);
        }
        return Ok(Finished::Success { output_json: json });
    }
    let message: String = response.get("message").map_err(js)?;
    let kind: String = response.get("kind").map_err(js)?;
    let retry: Option<f64> = response.get("retryAfterSec").map_err(js)?;
    Ok(Finished::ScriptError {
        message: message.chars().take(MAX_ERROR_MESSAGE_CHARS).collect(),
        kind: match kind.as_str() {
            "rateLimited" => ErrorKind::RateLimited,
            "invalidResponse" => ErrorKind::InvalidResponse,
            "auth" => ErrorKind::Auth,
            "quota" => ErrorKind::Quota,
            _ => ErrorKind::Server,
        },
        retry_after_sec: retry.map(|r| r.min(f64::from(u32::MAX)) as u32),
    })
}
