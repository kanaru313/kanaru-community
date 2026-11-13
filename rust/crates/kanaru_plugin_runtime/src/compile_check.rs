#![allow(unsafe_code)]
//! Compile-only check of a plugin script: parses it as a classic global
//! script and never runs it, so a top-level `throw` or an endless loop is
//! not executed.
//!
//! Raw `JS_Eval` with `COMPILE_ONLY` is the only way to parse without running
//! (rquickjs has no compile-only call), hence the `unsafe` in this file.

use std::ffi::CString;
use std::thread;

use rquickjs::{qjs, CatchResultExt, CaughtError, Context, Ctx, Runtime};

use crate::limits::{MEMORY_LIMIT_BYTES, SCRIPT_STACK_BYTES};
use crate::memory::LimitedAllocator;
use crate::pool::{run_thread_start, ThreadStartHook};
use crate::types::ScriptProblem;

/// Name of the check thread.
pub const THREAD_NAME: &str = "plugin-js-check";

/// `None` when `code` parses, else the first problem. Runs on a thread of its
/// own with `stack_bytes` of stack (the runtime's effective worker stack), because the caller is a bridge worker with
/// a small stack and the parser recurses. The thread calls `on_start` first.
pub fn check_script(
    name: &str,
    code: &str,
    stack_bytes: usize,
    on_start: Option<ThreadStartHook>,
) -> Option<ScriptProblem> {
    let (name, code) = (name.to_owned(), code.to_owned());
    let spawned = thread::Builder::new()
        .name(THREAD_NAME.to_owned())
        .stack_size(stack_bytes)
        .spawn(move || {
            run_thread_start(&on_start, THREAD_NAME);
            check_on_this_thread(&name, &code)
        });
    match spawned.map(|handle| handle.join()) {
        Ok(Ok(problem)) => problem,
        _ => Some(ScriptProblem {
            message: "the syntax check could not run".to_owned(),
            line: 0,
        }),
    }
}

fn check_on_this_thread(name: &str, code: &str) -> Option<ScriptProblem> {
    let internal = |what: &str| {
        Some(ScriptProblem {
            message: format!("the syntax check could not run: {what}"),
            line: 0,
        })
    };
    let (allocator, _memory_hit) = LimitedAllocator::new(MEMORY_LIMIT_BYTES);
    let runtime = match Runtime::new_with_alloc(allocator) {
        Ok(rt) => rt,
        Err(e) => return internal(&e.to_string()),
    };
    runtime.set_max_stack_size(SCRIPT_STACK_BYTES);
    let context = match Context::full(&runtime) {
        Ok(c) => c,
        Err(e) => return internal(&e.to_string()),
    };
    let problem = context.with(|ctx| compile_only(&ctx, name, code));
    drop(context);
    drop(runtime);
    problem
}

fn compile_only(ctx: &Ctx<'_>, name: &str, code: &str) -> Option<ScriptProblem> {
    let Ok(source) = CString::new(code) else {
        return Some(ScriptProblem {
            message: "the script contains a NUL character".to_owned(),
            line: 0,
        });
    };
    let file = CString::new(name).unwrap_or_else(|_| c"plugin.js".to_owned());
    let flags = (qjs::JS_EVAL_TYPE_GLOBAL | qjs::JS_EVAL_FLAG_COMPILE_ONLY) as i32;
    // SAFETY: `ctx` is a live context of this thread; `source` and `file` are
    // NUL-terminated and outlive the call (the length is passed explicitly);
    // the returned value is freed below unless it is the exception marker.
    let value = unsafe {
        qjs::JS_Eval(
            ctx.as_raw().as_ptr(),
            source.as_ptr(),
            code.len() as _,
            file.as_ptr(),
            flags,
        )
    };
    // SAFETY: `value` was just returned by `JS_Eval` for this context.
    let is_exception = unsafe { qjs::JS_IsException(value) };
    if !is_exception {
        // SAFETY: `value` is a live value of this context that nothing else
        // owns, freed exactly once here.
        unsafe { qjs::JS_FreeValue(ctx.as_raw().as_ptr(), value) };
        return None;
    }
    let caught: Result<(), CaughtError<'_>> = Err::<(), _>(rquickjs::Error::Exception).catch(ctx);
    let (message, stack) = match caught {
        Err(CaughtError::Exception(e)) => (
            e.message().unwrap_or_default(),
            e.stack().unwrap_or_default(),
        ),
        Err(other) => (other.to_string(), String::new()),
        Ok(()) => (String::new(), String::new()),
    };
    let line = line_in_stack(&stack, name);
    Some(ScriptProblem { message, line })
}

/// The first `name:LINE` in an engine stack text; 0 when there is none.
fn line_in_stack(stack: &str, name: &str) -> u32 {
    stack
        .split(&format!("{name}:") as &str)
        .nth(1)
        .map(|rest| {
            rest.chars()
                .take_while(char::is_ascii_digit)
                .collect::<String>()
        })
        .and_then(|digits| digits.parse().ok())
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::limits::THREAD_STACK_BYTES;

    /// The check with the default worker stack.
    fn check_script(
        name: &str,
        code: &str,
        on_start: Option<ThreadStartHook>,
    ) -> Option<ScriptProblem> {
        super::check_script(name, code, THREAD_STACK_BYTES, on_start)
    }

    #[test]
    fn valid_script_passes() {
        assert_eq!(
            check_script("a.js", "function execute(i) { return 1; }", None),
            None
        );
    }

    #[test]
    fn syntax_error_reports_the_line() {
        let p = check_script("search.js", "var a = 1;\nvar b = 2;\nvar c = ;\n", None)
            .expect("problem");
        assert_eq!(p.line, 3, "{p:?}");
        assert!(!p.message.is_empty());
    }

    #[test]
    fn top_level_throw_is_not_run() {
        assert_eq!(
            check_script("a.js", "throw new Error('x'); while (true) {}", None),
            None
        );
    }

    #[test]
    fn sloppy_code_compiles() {
        assert_eq!(
            check_script(
                "a.js",
                "with (Math) { var x = max(1, 2); } var o = 010;",
                None
            ),
            None
        );
    }

    #[test]
    fn nul_is_a_problem_not_a_panic() {
        assert!(check_script("a.js", "var a;\0", None).is_some());
    }

    #[test]
    fn the_check_thread_runs_the_start_hook_with_its_name() {
        let names = std::sync::Arc::new(std::sync::Mutex::new(Vec::<String>::new()));
        let seen = names.clone();
        let hook: ThreadStartHook = std::sync::Arc::new(move |name| {
            seen.lock().expect("lock").push(name.to_owned());
        });
        assert_eq!(check_script("a.js", "var a = 1;", Some(hook)), None);
        assert_eq!(*names.lock().expect("lock"), vec![THREAD_NAME.to_owned()]);
    }

    #[test]
    fn line_parsing() {
        assert_eq!(line_in_stack("    at a.js:12:5\n", "a.js"), 12);
        assert_eq!(line_in_stack("no position", "a.js"), 0);
    }
}
