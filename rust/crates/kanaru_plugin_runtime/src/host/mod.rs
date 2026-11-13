//! The host API a script sees besides `Response` and `load`: `sleep`,
//! `localConfig`, `localStorage` and `console` / `Log` (and, as their natives
//! arrive, `fetch`, `emit` and `Html`).
//!
//! Rust provides small natives (`console.rs`, `sleep.rs`, `storage.rs`, ...);
//! `js/host_prelude.js` wraps them into the script-facing objects and errors.
//! The natives are handed to the prelude as an argument and never become
//! globals, so a script cannot reach them directly. A native the prelude
//! expects but the runtime does not install yet is simply absent: the script
//! gets the prelude's own error when it calls the function.

pub mod budget;
pub mod callback;
pub mod console;
pub mod emit;
pub mod fetch;
pub mod late;
pub mod quiet;
pub mod sleep;
pub mod storage;
pub mod stream;

use std::collections::HashMap;
use std::rc::Rc;
use std::sync::atomic::{AtomicBool, AtomicU8, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

use rquickjs::{Ctx, Exception, Function, Object};

use crate::collector::Collector;
use crate::globals::eval_classic;
use crate::types::{FetchOutcome, FetchRequest, FetchResponse, Pending, StreamCall, StreamReply};
use budget::ByteBudget;
use late::LateDrain;

/// Why a run was stopped (set by the interrupt handler or a blocked host call).
pub const STOP_NONE: u8 = 0;
pub const STOP_CANCELLED: u8 = 1;
pub const STOP_TIMEOUT: u8 = 2;
/// A host function panicked; the run ends `internal`.
pub const STOP_INTERNAL: u8 = 3;

const HOST_PRELUDE: &str = include_str!("../js/host_prelude.js");

/// What answers the I/O a script asks for. The bridge implements it on top of
/// the app's HTTP client; the runtime calls it on a JS worker thread, which
/// then waits for the returned future (until the job is cancelled or its
/// deadline passes), so the implementation returns quickly with a future.
pub trait PluginHost: Send + Sync {
    /// Answers one `fetch` of a script.
    fn fetch(&self, request: FetchRequest) -> Pending<FetchResponse>;
    /// Answers one open, read or close call of a streamed response.
    ///
    /// Host contract (the old app's Dart `closeAll()`): keep one stream table
    /// per run; close every stream still open when the run ends or is
    /// cancelled (Rust never sends `Close` for them, and a cancel can stop a
    /// `Close` before it is sent); close at once an `Open` answered after the
    /// run ended; expect a `Close` while that stream's `Open` is pending.
    fn stream(&self, call: StreamCall) -> Pending<StreamReply>;
}

/// The host of a run that has no network: every call fails with `Network`.
#[derive(Debug, Clone, Copy, Default)]
pub struct NoNetwork;

impl PluginHost for NoNetwork {
    fn fetch(&self, _request: FetchRequest) -> Pending<FetchResponse> {
        Box::pin(async { failed_response(FetchOutcome::Network) })
    }

    fn stream(&self, _call: StreamCall) -> Pending<StreamReply> {
        Box::pin(async { failed_stream_reply(FetchOutcome::Network) })
    }
}

/// A response with no data for a failed outcome.
pub fn failed_response(outcome: FetchOutcome) -> FetchResponse {
    FetchResponse {
        outcome,
        status: 0,
        url: String::new(),
        headers: Vec::new(),
        body: Vec::new(),
        retry_after_sec: None,
        sends: 0,
    }
}

/// A stream reply with no data for a failed outcome.
pub fn failed_stream_reply(outcome: FetchOutcome) -> StreamReply {
    StreamReply {
        outcome,
        status: 0,
        url: String::new(),
        headers: Vec::new(),
        retry_after_sec: None,
        chunk: Vec::new(),
        done: false,
        sends: 0,
    }
}

/// What a streaming run adds to its host environment.
#[derive(Clone)]
pub struct StreamingEnv {
    /// Receives `emit` events; `None` counts and drops them.
    pub emitter: Option<emit::Emitter>,
    /// How long a stream read waits for data.
    pub idle: Duration,
}

/// What the host functions of one job share.
pub struct HostEnv {
    pub deadline: Instant,
    /// The job's cancel flag.
    pub cancel: Arc<AtomicBool>,
    /// Why the run was stopped; the first reason wins.
    pub stop: Arc<AtomicU8>,
    /// Rust-side bytes the host holds for the script (shared by every holder).
    pub budget: ByteBudget,
    pub collector: Collector,
    /// Answers the fetch and stream calls of the script.
    pub host: Arc<dyn PluginHost>,
    /// Identity of the plugin, copied into every call to `host`.
    pub install_id: String,
    /// Takes the futures of calls the script stopped waiting for.
    pub late: Arc<LateDrain>,
    /// Read-only `localConfig`; values are JSON texts.
    pub config: HashMap<String, String>,
    /// The plugin's stored map as JSON (empty text: nothing stored).
    pub storage_json: String,
    /// Set for a streaming run only.
    pub streaming: Option<StreamingEnv>,
}

impl HostEnv {
    /// Time left until the deadline.
    pub fn remaining(&self) -> Duration {
        self.deadline.saturating_duration_since(Instant::now())
    }

    /// Records why the run stops, unless a reason is already recorded.
    pub fn mark_stopped(&self, why: u8) {
        let _ = self
            .stop
            .compare_exchange(STOP_NONE, why, Ordering::SeqCst, Ordering::SeqCst);
    }

    /// Marks the run stopped and gives the exception that unwinds the script.
    /// A script can catch it, but the stop reason makes the result
    /// `cancelled` / `timeout` anyway, and every further host call throws again.
    pub fn stop_error<'js>(&self, ctx: &Ctx<'js>, why: u8) -> rquickjs::Error {
        self.mark_stopped(why);
        let message = if why == STOP_CANCELLED {
            "the call was cancelled"
        } else if why == STOP_INTERNAL {
            "internal error in a host function"
        } else {
            "the call ran out of time"
        };
        Exception::throw_message(ctx, message)
    }

    /// Why the call should stop now (cancelled, or out of time), without
    /// throwing: for code that holds a borrow and must not throw inside it.
    pub fn stop_reason(&self) -> Option<u8> {
        if self.cancel.load(Ordering::SeqCst) {
            Some(STOP_CANCELLED)
        } else if Instant::now() >= self.deadline {
            Some(STOP_TIMEOUT)
        } else {
            None
        }
    }

    /// Throws when the call was cancelled or its time is up.
    pub fn check_alive<'js>(&self, ctx: &Ctx<'js>) -> rquickjs::Result<()> {
        match self.stop_reason() {
            Some(why) => Err(self.stop_error(ctx, why)),
            None => Ok(()),
        }
    }
}

/// Installs the host API in the context.
///
/// Install order: storage, console, `fetch` (and with it the stream natives of
/// a streaming run), sleep, `emit` (streaming runs only), `Html` (not ported yet).
/// A later native takes its place at the marked seam, so the order stays that
/// of the list.
pub fn install<'js>(ctx: &Ctx<'js>, env: HostEnv) -> rquickjs::Result<()> {
    let env = Rc::new(env);
    let natives = Object::new(ctx.clone())?;
    storage::register(ctx, &natives, &env)?;
    console::register(ctx, &natives, &env)?;
    fetch::register(ctx, &natives, &env)?;
    sleep::register(ctx, &natives, &env)?;
    if env.streaming.is_some() {
        emit::register(ctx, &natives, &env)?;
    }
    // Seam: Html.
    let init: Function = eval_classic(ctx, HOST_PRELUDE, "<runtime>")?
        .into_function()
        .ok_or_else(|| Exception::throw_message(ctx, "host prelude did not return a function"))?;
    init.call::<_, ()>((natives,))
}
