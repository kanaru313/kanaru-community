//! Runs untrusted plugin JavaScript (QuickJS) with the host API plugins see.
//!
//! Plain Rust with no FFI and no knowledge of `kanaru_media`. I/O a plugin
//! asks for (fetch, streams) goes through the [`PluginHost`] trait the bridge
//! implements. Everything lives in a [`PluginRuntime`] instance (threads, job
//! registry, late-answers drain); the crate has no process globals except the
//! optional panic hook of [`install_quiet_panic_hook`].
//!
//! Model: a pool of [`limits::WORKER_THREADS`] threads; every job creates a
//! fresh QuickJS `Runtime` + `Context` on its worker, runs, and drops both
//! there.

mod charset;
mod collector;
mod compile_check;
// `engine` is public only with `test-hooks` so integration tests can reach it;
// it is not an API (it needs a big-stack thread, the pools and the registry).
#[cfg(feature = "test-hooks")]
#[doc(hidden)]
pub mod engine;
#[cfg(not(feature = "test-hooks"))]
mod engine;
mod globals;
mod host;
mod jobs;
pub mod limits;
mod memory;
mod pool;
mod runtime;
mod stream_text;
mod types;

pub use host::emit::Emitter;
pub use host::quiet::install_quiet_panic_hook;
pub use host::{failed_response, failed_stream_reply, NoNetwork, PluginHost};
pub use pool::ThreadStartHook;
pub use runtime::{PluginRuntime, RuntimeConfig};
pub use types::{
    ErrorKind, FetchFailure, FetchFailureKind, FetchOutcome, FetchRequest, FetchResponse, JsError,
    Pending, ScriptProblem, ScriptRequest, ScriptResult, ScriptStatus, SourceFile, StreamCall,
    StreamOp, StreamOptions, StreamReply,
};

/// Version of this crate, so the bridge can report what it links.
pub const CRATE_VERSION: &str = env!("CARGO_PKG_VERSION");
