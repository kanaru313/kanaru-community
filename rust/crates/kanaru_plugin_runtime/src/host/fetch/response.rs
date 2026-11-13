//! The answer side of `fetch`: the named errors a failed outcome becomes, the
//! sticky failure kept for the result, send accounting and header shaping.

use std::cell::RefCell;
use std::sync::atomic::Ordering;

use rquickjs::{Ctx, Object};

use super::FetchState;
use crate::host::{HostEnv, STOP_CANCELLED};
use crate::types::{FetchFailure, FetchFailureKind as Kind, FetchOutcome as Outcome};

/// Script-visible error name and runtime-made message of a failure kind.
fn describe(kind: Kind) -> (&'static str, &'static str) {
    match kind {
        Kind::Network => ("NetworkError", "the network request failed"),
        Kind::BlockedHost => (
            "BlockedHostError",
            "the host is not allowed for this plugin",
        ),
        Kind::NotConsented => (
            "NotConsentedError",
            "the user has not allowed this plugin to use the network",
        ),
        Kind::Abandoned => ("AbortError", "the request was abandoned"),
        Kind::InvalidRequest => ("InvalidRequestError", "the request was refused"),
        Kind::InvalidResponse => ("InvalidResponseError", "the response was refused"),
        Kind::RateLimited => ("RateLimitedError", "the server asked to slow down"),
    }
}

/// Records the sticky failure and returns the `{error, message}` object the
/// prelude turns into a thrown `Error`.
pub fn failure<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    kind: Kind,
    name: &str,
    message: &str,
    retry_after_sec: Option<u32>,
) -> rquickjs::Result<Object<'js>> {
    env.collector.set_fetch_failure_once(FetchFailure {
        kind,
        retry_after_sec,
        message: message.to_owned(),
    });
    let object = Object::new(ctx.clone())?;
    object.set("error", name)?;
    object.set("message", message)?;
    if let Some(sec) = retry_after_sec {
        object.set("retryAfterSec", sec)?;
    }
    Ok(object)
}

pub fn failure_of_kind<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    kind: Kind,
    retry_after_sec: Option<u32>,
) -> rquickjs::Result<Object<'js>> {
    let (name, message) = describe(kind);
    failure(ctx, env, kind, name, message, retry_after_sec)
}

fn kind_of(outcome: Outcome) -> Option<Kind> {
    Some(match outcome {
        Outcome::Ok => return None,
        Outcome::Network => Kind::Network,
        Outcome::BlockedHost => Kind::BlockedHost,
        Outcome::NotConsented => Kind::NotConsented,
        Outcome::Abandoned => Kind::Abandoned,
        Outcome::InvalidRequest => Kind::InvalidRequest,
        Outcome::InvalidResponse => Kind::InvalidResponse,
        Outcome::RateLimited => Kind::RateLimited,
    })
}

/// The error object for a non-ok `outcome` (sticky failure recorded); `None` for `Ok`.
pub fn fail_outcome<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    outcome: Outcome,
    retry_after_sec: Option<u32>,
) -> rquickjs::Result<Option<Object<'js>>> {
    let Some(kind) = kind_of(outcome) else {
        return Ok(None);
    };
    let retry = (kind == Kind::RateLimited)
        .then_some(retry_after_sec)
        .flatten();
    let object = failure_of_kind(ctx, env, kind, retry)?;
    if kind == Kind::Abandoned {
        // The user walked away: the whole job ends `cancelled`, even if the
        // script catches this error.
        env.cancel.store(true, Ordering::SeqCst);
        env.mark_stopped(STOP_CANCELLED);
    }
    Ok(Some(object))
}

/// Adds the sends of one answer to the call's total, capped at `max_sends`.
pub fn record_sends(state: &RefCell<FetchState>, outcome: Outcome, reported: u32, max_sends: u32) {
    // An HTTP exchange happened for these even if the host forgot to count.
    let at_least_one = matches!(
        outcome,
        Outcome::Ok | Outcome::Network | Outcome::RateLimited | Outcome::InvalidResponse
    );
    let reported = if at_least_one {
        reported.max(1)
    } else {
        reported
    };
    let mut st = state.borrow_mut();
    st.sends = st.sends.saturating_add(reported.min(max_sends));
}

/// Lower-case names, repeated ones joined with ", "; flat name, value, ... list.
pub fn flat_headers(raw: Vec<(String, String)>) -> Vec<String> {
    let mut headers: Vec<(String, String)> = Vec::new();
    for (name, value) in raw {
        let name = name.to_ascii_lowercase();
        match headers.iter_mut().find(|(k, _)| *k == name) {
            Some((_, existing)) => {
                existing.push_str(", ");
                existing.push_str(&value);
            }
            None => headers.push((name, value)),
        }
    }
    headers.into_iter().flat_map(|(k, v)| [k, v]).collect()
}
