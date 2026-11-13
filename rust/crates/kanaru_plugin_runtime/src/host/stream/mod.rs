//! Streamed `fetch` responses of a streaming run: `fetch(url, {stream: true})`
//! opens a stream through the host, and the response's `readLine()`,
//! `read()`, `text()` and `close()` read it blocking, one refill (a `Read`
//! call) at a time.
//!
//! Rust decodes (UTF-8 only), splits lines and keeps the budget: the text it
//! holds is charged to the run's byte budget and released as the script
//! consumes it. A stream turns **dead** on any failure (the host's error, a
//! give-up, a limit); Rust then sends `Close` and later reads return `null`.
//! A dead stream keeps its slot of the per-run cap until its `Close` was
//! answered. Error texts are fixed: no payload or URL appears in them. Every
//! call to the host carries the run's `install_id`.

mod buffer;

use std::cell::RefCell;
use std::rc::Rc;
use std::time::Instant;

use rquickjs::{Ctx, Exception, Function, Object, Value};

use super::callback::{ask, Waited};
use super::fetch::{
    fail_outcome, failure, failure_of_kind, flat_headers, record_sends, FetchState,
};
use super::{failed_stream_reply, HostEnv, StreamingEnv, STOP_CANCELLED, STOP_TIMEOUT};
use crate::limits::{op_grace, MAX_OPEN_STREAMS, MAX_STREAM_READ_BYTES, MIN_OP_GRACE};
use crate::types::{
    FetchFailureKind as Kind, FetchOutcome as Outcome, FetchRequest, StreamCall, StreamOp,
};
pub use buffer::StreamState;
use buffer::{apply, serve, Applied, Served};

/// What `streamRead` serves: the mode a script method maps to.
const MODE_LINE: u8 = 0;
const MODE_CHUNK: u8 = 1;

/// Sends `Close` for `id`, waiting at most [`MIN_OP_GRACE`]; an answer frees
/// the stream's slot, otherwise the late-answers drain keeps the call.
fn send_close(env: &HostEnv, state: &RefCell<StreamState>, id: u32) {
    if env.streaming.is_none() {
        return;
    }
    let call = StreamCall {
        install_id: env.install_id.clone(),
        stream: id,
        op: StreamOp::Close,
        request: None,
        max_bytes: 0,
        wait_ms: 0,
        lifetime_ms: 0,
    };
    let until = (Instant::now() + MIN_OP_GRACE).min(env.deadline);
    // A reply, or a host error: nothing more can be done for this stream.
    if matches!(
        ask(|| env.host.stream(call), &env.cancel, until, &env.late),
        Waited::Answer(_) | Waited::Failed
    ) {
        if let Some(s) = state.borrow_mut().streams.get_mut(&id) {
            s.holds_slot = false;
        }
    }
}

/// Ends a stream that is not finished yet: drops its text and sends `Close`
/// unless the body had ended (the app closed it then).
fn end_stream(env: &HostEnv, state: &RefCell<StreamState>, id: u32) {
    let needs_close = {
        let mut st = state.borrow_mut();
        let Some(s) = st.streams.get_mut(&id).filter(|s| !s.finished) else {
            return;
        };
        s.discard(&env.budget);
        s.holds_slot
    };
    if needs_close {
        send_close(env, state, id);
    }
}

/// Opens a stream for a `fetch(..., {stream: true})` whose request and wait
/// limit `fetch` has already worked out. Sends count on the same counter as
/// plain fetches.
pub fn open<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    fetch_state: &RefCell<FetchState>,
    state: &RefCell<StreamState>,
    request: FetchRequest,
    max_sends: u32,
    wait_until: Instant,
) -> rquickjs::Result<Object<'js>> {
    if env.streaming.is_none() {
        return failure_of_kind(ctx, env, Kind::InvalidRequest, None);
    }
    if state.borrow().slots_used() >= MAX_OPEN_STREAMS {
        return failure(
            ctx,
            env,
            Kind::InvalidRequest,
            "TooManyStreamsError",
            "too many open streams in one call (limit 2)",
            None,
        );
    }
    let id = {
        let mut st = state.borrow_mut();
        st.next_id += 1;
        st.next_id
    };
    let call = StreamCall {
        install_id: env.install_id.clone(),
        stream: id,
        op: StreamOp::Open,
        request: Some(request),
        max_bytes: 0,
        wait_ms: 0,
        lifetime_ms: u32::try_from(env.remaining().as_millis()).unwrap_or(u32::MAX),
    };
    let reply = match ask(|| env.host.stream(call), &env.cancel, wait_until, &env.late) {
        Waited::Answer(r) => r,
        Waited::Failed => failed_stream_reply(Outcome::Network),
        Waited::Cancelled => return Err(env.stop_error(ctx, STOP_CANCELLED)),
        Waited::DeadlinePassed if wait_until >= env.deadline => {
            return Err(env.stop_error(ctx, STOP_TIMEOUT))
        }
        // The app is too slow: a network failure that is charged every send
        // it was allowed (it may have sent), and its stream, which it may
        // still be opening, is closed.
        Waited::DeadlinePassed => {
            record_sends(fetch_state, Outcome::Network, max_sends, max_sends);
            state.borrow_mut().insert(id, true);
            send_close(env, state, id);
            return failure_of_kind(ctx, env, Kind::Network, None);
        }
    };
    record_sends(fetch_state, reply.outcome, reply.sends, max_sends);
    if let Some(object) = fail_outcome(ctx, env, reply.outcome, reply.retry_after_sec)? {
        return Ok(object);
    }
    state.borrow_mut().insert(id, false);
    let object = Object::new(ctx.clone())?;
    object.set("stream", true)?;
    object.set("id", id)?;
    object.set("status", reply.status)?;
    object.set("url", reply.url)?;
    object.set("headers", flat_headers(reply.headers))?;
    Ok(object)
}

/// One `Read` call. `Some(error object)` when the stream failed (it is dead
/// and closed by then); `None` when the buffer grew or the body ended.
fn refill<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    streaming: &StreamingEnv,
    state: &RefCell<StreamState>,
    id: u32,
) -> rquickjs::Result<Option<Object<'js>>> {
    let wait = streaming.idle.min(env.remaining());
    let call = StreamCall {
        install_id: env.install_id.clone(),
        stream: id,
        op: StreamOp::Read,
        request: None,
        max_bytes: MAX_STREAM_READ_BYTES as u32,
        wait_ms: u32::try_from(wait.as_millis()).unwrap_or(u32::MAX).max(1),
        lifetime_ms: 0,
    };
    // The app answers within `wait`; Rust stops waiting a little later.
    let until = (Instant::now() + wait + op_grace(wait)).min(env.deadline);
    let reply = match ask(|| env.host.stream(call), &env.cancel, until, &env.late) {
        Waited::Answer(r) => r,
        Waited::Failed => failed_stream_reply(Outcome::Network),
        Waited::Cancelled => return Err(env.stop_error(ctx, STOP_CANCELLED)),
        Waited::DeadlinePassed if until >= env.deadline => {
            return Err(env.stop_error(ctx, STOP_TIMEOUT))
        }
        Waited::DeadlinePassed => failed_stream_reply(Outcome::Network),
    };
    if reply.outcome != Outcome::Ok {
        let object = fail_outcome(ctx, env, reply.outcome, None)?;
        end_stream(env, state, id);
        return Ok(object);
    }
    match apply(&env.budget, state, id, reply) {
        Applied::Fine => Ok(None),
        Applied::Bad => {
            let object = failure_of_kind(ctx, env, Kind::InvalidResponse, None)?;
            end_stream(env, state, id);
            Ok(Some(object))
        }
        Applied::OverBudget => {
            end_stream(env, state, id);
            Err(Exception::throw_range(
                ctx,
                "stream: the text kept in memory exceeds the limit",
            ))
        }
    }
}

fn stream_read<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    state: &RefCell<StreamState>,
    id: u32,
    mode: u8,
) -> rquickjs::Result<Value<'js>> {
    let Some(streaming) = &env.streaming else {
        return Ok(Value::new_null(ctx.clone()));
    };
    let string = |text: &str| -> rquickjs::Result<Value<'js>> {
        Ok(rquickjs::String::from_str(ctx.clone(), text)?.into_value())
    };
    let end = |mode: u8| {
        if mode == MODE_LINE || mode == MODE_CHUNK {
            Ok(Value::new_null(ctx.clone()))
        } else {
            string("")
        }
    };
    loop {
        env.check_alive(ctx)?;
        let served = {
            let mut st = state.borrow_mut();
            let Some(s) = st.streams.get_mut(&id) else {
                return end(mode);
            };
            let served = serve(s, mode);
            s.sync_budget(&env.budget);
            served
        };
        match served {
            Served::Text(text) => return string(&text),
            Served::End => return end(mode),
            Served::TooLong => {
                end_stream(env, state, id);
                return Err(Exception::throw_range(
                    ctx,
                    if mode == MODE_LINE {
                        "readLine: the line is longer than 1 MiB"
                    } else {
                        "text: the stream text is longer than 4 MiB"
                    },
                ));
            }
            Served::Wait => {}
        }
        if let Some(object) = refill(ctx, env, streaming, state, id)? {
            return Ok(object.into_value());
        }
    }
}

/// Native `streamRead` and `streamClose`; registered for streaming runs only.
pub fn register<'js>(
    ctx: &Ctx<'js>,
    natives: &Object<'js>,
    env: &Rc<HostEnv>,
    state: &Rc<RefCell<StreamState>>,
) -> rquickjs::Result<()> {
    let (e, s) = (env.clone(), state.clone());
    natives.set(
        "streamRead",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, id: u32, mode: u8| {
            stream_read(&ctx, &e, &s, id, mode)
        })?,
    )?;
    let (e, s) = (env.clone(), state.clone());
    natives.set(
        "streamClose",
        Function::new(ctx.clone(), move |id: u32| end_stream(&e, &s, id))?,
    )
}
