//! The script's `fetch`: builds the request, hands it to the host on the JS
//! thread, waits (cancel and deadline aware) and turns the answer into data
//! the script-side wrapper (`js/host_prelude.js`) shapes into a response
//! object or a named error.
//!
//! Rust checks only what must not cross the boundary: the method and the
//! request body size. URLs, hosts, consent, headers and the response size are
//! judged by the host. Error texts made here never contain the URL, the
//! headers, the body or any configuration value.

mod body;
mod options;
mod response;

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::time::{Duration, Instant};

use rquickjs::function::Opt;
use rquickjs::{Ctx, Exception, Function, Object, Value};

use super::callback::{ask, Waited};
use super::stream::{self, StreamState};
use super::{failed_response, HostEnv, STOP_CANCELLED, STOP_TIMEOUT};
use crate::limits::{op_grace, MAX_FETCH_REQUEST_BODY_BYTES, MAX_FETCH_SENDS, MAX_WALL_TIME};
use crate::types::{
    FetchFailureKind as Kind, FetchOutcome as Outcome, FetchRequest, FetchResponse,
};
use body::Body;
use options::{parse_options, type_error, with_queries};
pub(super) use response::{fail_outcome, failure, failure_of_kind, flat_headers, record_sends};

/// Counters and unread bodies of one call.
#[derive(Default)]
pub struct FetchState {
    /// HTTP sends the host reported so far, retries included.
    sends: u32,
    next_id: u32,
    bodies: HashMap<u32, Body>,
}

fn fetch<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    state: &RefCell<FetchState>,
    streams: &RefCell<StreamState>,
    url: String,
    options: Option<Object<'js>>,
) -> rquickjs::Result<Object<'js>> {
    let parsed = parse_options(ctx, options)?;
    env.check_alive(ctx)?;
    if parsed.body.len() > MAX_FETCH_REQUEST_BODY_BYTES {
        return failure(
            ctx,
            env,
            Kind::InvalidRequest,
            "InvalidRequestError",
            "the request body is larger than 256 KiB",
            None,
        );
    }
    if state.borrow().sends >= MAX_FETCH_SENDS {
        return failure(
            ctx,
            env,
            Kind::InvalidRequest,
            "TooManyRequestsError",
            "too many requests in one call (limit 10, retries included)",
            None,
        );
    }

    let mut deadline_ms = u32::try_from(env.remaining().as_millis()).unwrap_or(u32::MAX);
    if let Some(t) = parsed.timeout_ms.filter(|t| t.is_finite() && *t >= 1.0) {
        deadline_ms = deadline_ms.min(t.min(f64::from(u32::MAX)) as u32);
    }
    let streaming = env.streaming.is_some();
    if streaming {
        // A streaming run lasts minutes; one call still gets 90 s at most.
        let cap = u32::try_from(MAX_WALL_TIME.as_millis()).unwrap_or(u32::MAX);
        deadline_ms = deadline_ms.min(cap);
    }
    // Sends still allowed for this call; at least 1 because the cap check above passed.
    let max_sends = MAX_FETCH_SENDS - state.borrow().sends;
    // A streaming run can last minutes, so a single wait must not: Rust stops
    // waiting a little after the deadline it gave the host (its isolate may
    // be busy for a moment).
    let wait_until = if streaming {
        let asked = Duration::from_millis(u64::from(deadline_ms.max(1)));
        env.deadline.min(Instant::now() + asked + op_grace(asked))
    } else {
        env.deadline
    };
    let parsed_stream = parsed.stream;
    let request = FetchRequest {
        install_id: env.install_id.clone(),
        method: parsed.method.to_owned(),
        url: with_queries(&url, &parsed.queries),
        headers: parsed.headers,
        body: parsed.body,
        deadline_ms: deadline_ms.max(1),
        max_sends,
    };
    if parsed_stream && streaming {
        return stream::open(ctx, env, state, streams, request, max_sends, wait_until);
    }
    // On this JS thread, never on a bridge worker or the app's isolate.
    let response = match ask(
        || env.host.fetch(request),
        &env.cancel,
        wait_until,
        &env.late,
    ) {
        Waited::Answer(r) => r,
        // The app threw: answered as a network failure, like any other.
        Waited::Failed => failed_response(Outcome::Network),
        Waited::Cancelled => return Err(env.stop_error(ctx, STOP_CANCELLED)),
        // The run's own deadline ended the wait.
        Waited::DeadlinePassed if wait_until >= env.deadline => {
            return Err(env.stop_error(ctx, STOP_TIMEOUT))
        }
        // Only the single wait ran out (streaming runs): a network failure.
        // The host may have sent already, so the call is charged every send
        // it was allowed.
        Waited::DeadlinePassed => FetchResponse {
            sends: max_sends,
            ..failed_response(Outcome::Network)
        },
    };
    answer_object(ctx, env, state, response, max_sends)
}

/// The `{id, status, url, headers}` object of an answer, or its error object.
fn answer_object<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    state: &RefCell<FetchState>,
    response: FetchResponse,
    max_sends: u32,
) -> rquickjs::Result<Object<'js>> {
    record_sends(state, response.outcome, response.sends, max_sends);
    if let Some(object) = fail_outcome(ctx, env, response.outcome, response.retry_after_sec)? {
        return Ok(object);
    }
    let id = {
        let mut st = state.borrow_mut();
        if !env.budget.try_charge(response.body.len()) {
            return Err(Exception::throw_range(
                ctx,
                "fetch: the response bodies kept in memory exceed the limit",
            ));
        }
        st.next_id += 1;
        let id = st.next_id;
        let content_type = response
            .headers
            .iter()
            .find(|(k, _)| k.eq_ignore_ascii_case("content-type"))
            .map(|(_, v)| v.clone());
        st.bodies.insert(
            id,
            Body {
                bytes: response.body,
                content_type,
            },
        );
        id
    };
    let object = Object::new(ctx.clone())?;
    object.set("id", id)?;
    object.set("status", response.status)?;
    object.set("url", response.url)?;
    object.set("headers", flat_headers(response.headers))?;
    Ok(object)
}

/// Native `fetch`, `bodyText` and `bodyBase64`.
pub fn register<'js>(
    ctx: &Ctx<'js>,
    natives: &Object<'js>,
    env: &Rc<HostEnv>,
) -> rquickjs::Result<()> {
    let state = Rc::new(RefCell::new(FetchState::default()));
    let streams = Rc::new(RefCell::new(StreamState::default()));
    if env.streaming.is_some() {
        stream::register(ctx, natives, env, &streams)?;
    }
    let (e, s, st) = (env.clone(), state.clone(), streams);
    natives.set(
        "fetch",
        Function::new(
            ctx.clone(),
            move |ctx: Ctx<'js>, url: String, options: Opt<Value<'js>>| {
                let options = match options.0 {
                    None => None,
                    Some(v) if v.is_undefined() || v.is_null() => None,
                    Some(v) => match v.into_object() {
                        Some(o) => Some(o),
                        None => return Err(type_error(&ctx, "fetch: options must be an object")),
                    },
                };
                fetch(&ctx, &e, &s, &st, url, options)
            },
        )?,
    )?;
    body::register(ctx, natives, env, &state)
}
