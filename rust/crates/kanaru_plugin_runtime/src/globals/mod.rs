//! What a plugin script sees: the `Response` helper, `load()`, the host API,
//! and the call of the global `execute(input)` with the check of what it
//! returned.
//!
//! Scripts are classic global scripts (sloppy mode, no modules): the entry
//! file and every file it `load()`s share one global scope.

mod execute;
mod load;
mod response;

use std::collections::HashMap;
use std::sync::Arc;

use rquickjs::context::EvalOptions;
use rquickjs::{CatchResultExt, CaughtError, Coerced, Ctx, FromJs, Value};

use crate::host::{self, HostEnv};
use crate::limits::{MAX_ERROR_MESSAGE_CHARS, MAX_ERROR_STACK_BYTES};

pub use execute::{call_execute, Finished, RunFailure};
pub use response::Helpers;

/// The package's `src/` files by name.
pub type Sources = Arc<HashMap<String, String>>;

/// An exception, a syntax error or an engine error, as owned text.
#[derive(Debug, Clone, Default)]
pub struct JsFailure {
    /// The exception's `name` (`RangeError`, ...); empty for non-objects.
    pub name: String,
    pub message: String,
    /// Empty when the engine gave none.
    pub stack: String,
}

/// Turns an engine error into owned text. `ctx.catch()` takes the pending
/// exception, so call this once per error.
pub fn describe_error<'js>(ctx: &Ctx<'js>, err: rquickjs::Error) -> JsFailure {
    let caught: Result<(), CaughtError<'js>> = Err::<(), _>(err).catch(ctx);
    let mut failure = match caught {
        Ok(()) => JsFailure::default(),
        Err(CaughtError::Exception(e)) => JsFailure {
            name: e
                .get::<_, Option<String>>("name")
                .ok()
                .flatten()
                .unwrap_or_default(),
            message: e.message().unwrap_or_default(),
            stack: e.stack().unwrap_or_default(),
        },
        Err(CaughtError::Value(v)) => JsFailure {
            message: Coerced::<String>::from_js(ctx, v)
                .map(|c| c.0)
                .unwrap_or_else(|_| "non-string value thrown".to_owned()),
            ..JsFailure::default()
        },
        Err(CaughtError::Error(rquickjs::Error::Allocation)) => JsFailure {
            message: "out of memory".to_owned(),
            ..JsFailure::default()
        },
        Err(CaughtError::Error(e)) => JsFailure {
            message: e.to_string(),
            ..JsFailure::default()
        },
    };
    failure.message = truncate_chars(failure.message, MAX_ERROR_MESSAGE_CHARS);
    failure.stack = truncate_bytes(failure.stack, MAX_ERROR_STACK_BYTES);
    failure
}

/// Cuts `s` to at most `max` characters.
fn truncate_chars(s: String, max: usize) -> String {
    match s.char_indices().nth(max) {
        Some((i, _)) => s[..i].to_owned(),
        None => s,
    }
}

/// Cuts `s` to at most `max` bytes, on a character boundary.
fn truncate_bytes(mut s: String, max: usize) -> String {
    if s.len() > max {
        let mut cut = max;
        while !s.is_char_boundary(cut) {
            cut -= 1;
        }
        s.truncate(cut);
    }
    s
}

/// Runs `code` as a classic global script named `filename`.
pub fn eval_classic<'js>(
    ctx: &Ctx<'js>,
    code: &str,
    filename: &str,
) -> rquickjs::Result<Value<'js>> {
    let mut options = EvalOptions::default();
    options.strict = false;
    options.filename = Some(filename.to_owned());
    ctx.eval_with_options::<Value, _>(code, options)
}

/// Installs `Response`, the host API and `load()`; returns the prelude helpers.
/// `entry` counts as already loaded.
pub fn install<'js>(
    ctx: &Ctx<'js>,
    sources: Sources,
    entry: &str,
    host: HostEnv,
) -> rquickjs::Result<Helpers<'js>> {
    #[cfg(feature = "test-hooks")]
    let (collector, late) = (host.collector.clone(), host.late.clone());
    let helpers = response::install(ctx)?;
    load::install(ctx, sources, entry)?;
    host::install(ctx, host)?;

    #[cfg(feature = "test-hooks")]
    install_test_hooks(ctx, &collector, &late)?;
    Ok(helpers)
}

/// Host functions only test builds have (cargo feature `test-hooks`): they let
/// a test write a console line, panic, or announce `__testReady()` from inside
/// the script.
#[cfg(feature = "test-hooks")]
fn install_test_hooks<'js>(
    ctx: &Ctx<'js>,
    collector: &crate::collector::Collector,
    late: &std::sync::Arc<crate::host::late::LateDrain>,
) -> rquickjs::Result<()> {
    use rquickjs::Function;

    let sink = collector.clone();
    let log = Function::new(ctx.clone(), move |line: String| sink.push_log(line))?;
    ctx.globals().set("__testLog", log)?;
    let panic_fn = Function::new(ctx.clone(), || -> () {
        panic!("test host function panicked")
    })?;
    ctx.globals().set("__testPanic", panic_fn)?;
    let late = late.clone();
    let ready = Function::new(ctx.clone(), move || late.mark_ready())?;
    ctx.globals().set("__testReady", ready)?;
    Ok(())
}
