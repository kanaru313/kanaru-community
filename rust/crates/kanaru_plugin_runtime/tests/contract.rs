//! The plugin script contract: `execute(input)`, `Response`, `load()`, classic
//! global scripts, error kinds, result fields, compile-only checks, job ids.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::sync::atomic::AtomicBool;
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

use common::rt;
use common::{block_on, file, request_with, run_files, run_script};
use kanaru_plugin_runtime::{
    engine, limits, ErrorKind, ScriptResult, ScriptStatus as S, SourceFile,
};

const OK_SCRIPT: &str = "function execute(input) { return Response.success(input); }";

#[test]
fn success_round_trips_the_input_as_json() {
    let _t = common::test();
    let r = run_files(
        vec![file("search.js", OK_SCRIPT)],
        r#"{"title":"Kết","n":[1,2.5]}"#,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, r#"{"title":"Kết","n":[1,2.5]}"#);
    assert_eq!(r.error_kind, ErrorKind::None);
    assert_eq!(r.error_message, "");
}

#[test]
fn undefined_data_becomes_null() {
    let _t = common::test();
    let r = run_script("function execute() { return Response.success(); }", 0);
    assert_eq!(r.status, S::Ok);
    assert_eq!(r.output_json, "null");
}

#[test]
fn response_error_carries_kind_and_retry_after() {
    let _t = common::test();
    let cases = [
        ("Response.error('m')", ErrorKind::Server, None),
        (
            "Response.error('m', {kind: 'rateLimited', retryAfterSec: 30})",
            ErrorKind::RateLimited,
            Some(30),
        ),
        (
            "Response.error('m', {kind: 'invalidResponse'})",
            ErrorKind::InvalidResponse,
            None,
        ),
        (
            "Response.error('m', {kind: 'server', retryAfterSec: 2.9})",
            ErrorKind::Server,
            Some(2),
        ),
        (
            "Response.error('m', {kind: 'banana'})",
            ErrorKind::Server,
            None,
        ),
        (
            "Response.error('m', {kind: 42, retryAfterSec: -1})",
            ErrorKind::Server,
            None,
        ),
        (
            "Response.error('m', {retryAfterSec: 'soon'})",
            ErrorKind::Server,
            None,
        ),
        ("Response.error('m', null)", ErrorKind::Server, None),
    ];
    for (expr, kind, retry) in cases {
        let r = run_script(&format!("function execute() {{ return {expr}; }}"), 0);
        assert_eq!(r.status, S::ScriptError, "{expr}: {r:?}");
        assert_eq!(r.error_message, "m", "{expr}");
        assert_eq!(r.error_kind, kind, "{expr}");
        assert_eq!(r.retry_after_sec, retry, "{expr}");
        assert_eq!(
            r.js_error, None,
            "{expr}: a Response.error is not an exception"
        );
    }
}

#[test]
fn missing_execute_is_a_script_error() {
    let _t = common::test();
    let r = run_script("var x = 1;", 0);
    assert_eq!(r.status, S::ScriptError);
    assert_eq!(r.error_kind, ErrorKind::InvalidResponse);
    assert!(r.error_message.contains("execute"), "{}", r.error_message);
    let r = run_script("var execute = 5;", 0);
    assert_eq!(r.status, S::ScriptError);
    assert_eq!(r.error_kind, ErrorKind::InvalidResponse);
}

#[test]
fn execute_must_return_a_response() {
    let _t = common::test();
    let bad = [
        "Promise.resolve(Response.success(1))",
        "(async function () { return Response.success(1); })()",
        "undefined",
        "42",
        "'text'",
        "null",
        "{ ok: true, data: 1 }",
        "Object.create(Response.success(1))",
        "JSON.parse(JSON.stringify(Response.success(1)))",
    ];
    for expr in bad {
        let r = run_script(&format!("function execute() {{ return {expr}; }}"), 0);
        assert_eq!(r.status, S::ScriptError, "{expr}: {r:?}");
        assert_eq!(r.error_kind, ErrorKind::InvalidResponse, "{expr}");
        assert_eq!(
            r.error_message,
            "execute must return Response.success or Response.error"
        );
    }
}

#[test]
fn a_script_cannot_forge_or_break_responses() {
    let _t = common::test();
    let script = "
        Object.freeze = function (o) { return o; };
        WeakSet.prototype.add = function () {};
        WeakSet.prototype.has = function () { return true; };
        Response = { success: function () { return { ok: true, data: 'forged' }; } };
        function execute() { return { ok: true, data: 'forged' }; }
    ";
    let r = run_script(script, 0);
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_eq!(r.error_kind, ErrorKind::InvalidResponse);

    let r = run_script(
        "Object.freeze = null; function execute() { return Response.success(1); }",
        0,
    );
    assert_eq!(r.status, S::Ok, "helpers keep their own built-ins: {r:?}");
}

#[test]
fn poisoned_function_helpers_cannot_forge_a_response() {
    let _t = common::test();
    let script = "
        Function.prototype.call = function () { return true; };
        Function.prototype.apply = function () { return true; };
        Function.prototype.bind = function () { return function () { return true; }; };
        Reflect.apply = function () { return true; };
        function execute() { return { ok: true, data: 'forged' }; }
    ";
    let r = run_script(script, 0);
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_eq!(r.error_kind, ErrorKind::InvalidResponse);

    // The real helpers still work after the poisoning.
    let r = run_script(
        "Function.prototype.call = null; Function.prototype.bind = null; function execute() { return Response.success(1); }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
}

#[test]
fn thrown_error_text_is_cut() {
    let _t = common::test();
    let r = run_script(
        "function execute() { var e = new Error('x'.repeat(8 << 20)); e.stack = 'y'.repeat(8 << 20); throw e; }",
        0,
    );
    assert_eq!(r.status, S::ScriptError, "{:?}", r.status);
    let js = r.js_error.expect("js_error");
    assert_eq!(js.message.chars().count(), limits::MAX_ERROR_MESSAGE_CHARS);
    assert!(
        js.stack.len() <= limits::MAX_ERROR_STACK_BYTES,
        "{}",
        js.stack.len()
    );
    assert!(r.error_message.chars().count() <= limits::MAX_ERROR_MESSAGE_CHARS);

    // Multibyte text is cut on a character boundary.
    let r = run_script(
        "function execute() { var e = new Error('é'); e.stack = 'é'.repeat(20000); throw e; }",
        0,
    );
    let js = r.js_error.expect("js_error");
    assert!(js.stack.len() <= limits::MAX_ERROR_STACK_BYTES);
    assert!(js.stack.chars().all(|c| c == 'é'));
}

#[test]
fn only_the_engines_own_stack_error_is_a_stack_status() {
    let _t = common::test();
    for fake in [
        "throw new Error('Maximum call stack size exceeded');",
        "throw new Error('stack overflow');",
        "throw new RangeError('my stack overflow detector');",
        "throw 'stack overflow';",
    ] {
        let r = run_script(&format!("function execute() {{ {fake} }}"), 0);
        assert_eq!(r.status, S::ScriptError, "{fake}: {r:?}");
    }
    let r = run_script("function execute() { function f() { f(); } f(); }", 0);
    assert_eq!(r.status, S::Stack, "{r:?}");
}

#[test]
fn shared_memory_waits_cannot_block_a_worker() {
    let _t = common::test();
    // The wait below must fail because of Atomics.wait itself, not because
    // the constructors are missing.
    let r = run_script(
        "function execute() { return Response.success([typeof SharedArrayBuffer, typeof Int32Array, typeof Atomics.wait]); }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, r#"["function","function","function"]"#);
    let started = Instant::now();
    let r = run_script(
        "function execute() { var sab = new SharedArrayBuffer(16); var a = new Int32Array(sab); return Response.success(Atomics.wait(a, 0, 0, 5000)); }",
        0,
    );
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    let js = r.js_error.expect("js_error from Atomics.wait");
    assert!(
        js.message.contains("Atomics")
            || js.message.contains("block")
            || js.message.contains("wait"),
        "{js:?}"
    );
    assert!(
        started.elapsed() < Duration::from_secs(3),
        "must throw, not wait"
    );
}

#[test]
fn huge_multibyte_output_is_refused_by_utf8_size() {
    let _t = common::test();
    // 1.5 MiB of 3-byte characters is 1.5 Mi UTF-16 units but 4.5 MiB of UTF-8.
    let r = run_script(
        "function execute() { return Response.success('\\u20ac'.repeat(1.5 * 1024 * 1024)); }",
        0,
    );
    assert_eq!(r.status, S::OutputTooLarge, "{:?}", r.status);
}

#[test]
fn a_thrown_value_that_is_not_an_error_is_a_script_error() {
    let _t = common::test();
    let r = run_script("function execute() { throw 'plain string'; }", 0);
    assert_eq!(r.status, S::ScriptError);
    assert_eq!(r.error_message, "plain string");
    assert!(r.js_error.is_some());
}

#[test]
fn script_error_has_js_message_and_stack_with_line_numbers() {
    let _t = common::test();
    let r = run_script(
        "var a = 1;\nfunction execute() {\n  var o = null;\n  return o.missing;\n}",
        0,
    );
    assert_eq!(r.status, S::ScriptError);
    assert_eq!(r.error_kind, ErrorKind::InvalidResponse);
    let js = r.js_error.expect("js_error");
    assert!(js.message.contains("null"), "{js:?}");
    assert!(js.stack.contains("search.js:4"), "{js:?}");
    assert_eq!(r.error_message, js.message);
}

#[test]
fn syntax_error_in_the_entry_is_a_script_error_with_a_line() {
    let _t = common::test();
    let r = run_script("var a = 1;\nvar b = ;\n", 0);
    assert_eq!(r.status, S::ScriptError);
    let js = r.js_error.expect("js_error");
    assert!(js.stack.contains("search.js:2"), "{js:?}");
}

#[test]
fn scripts_are_classic_global_sloppy_scripts() {
    let _t = common::test();
    // `with`, octal literals and implicit globals only work outside strict mode.
    let script = "
        var sloppy = 010;
        implicitGlobal = 5;
        function execute() {
            var r;
            with (Math) { r = max(sloppy, implicitGlobal); }
            return Response.success({ r: r, sameGlobal: this === globalThis || this === undefined });
        }
    ";
    let r = run_script(script, 0);
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert!(r.output_json.contains(r#""r":8"#), "{}", r.output_json);
}

#[test]
fn no_modules_no_std_os_no_ambient_capabilities() {
    let _t = common::test();
    let r = run_script(
        "function execute() { return Response.success([typeof std, typeof os, typeof require, typeof setTimeout, typeof XMLHttpRequest, typeof WebSocket, typeof process]); }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(
        r.output_json,
        r#"["undefined","undefined","undefined","undefined","undefined","undefined","undefined"]"#
    );
    for src in [
        "import x from 'y.js';",
        "export const a = 1;",
        "function execute() { return import('y.js'); }",
    ] {
        let r = run_script(src, 0);
        assert_eq!(r.status, S::ScriptError, "{src}: {r:?}");
    }
}

#[test]
fn promises_are_never_resolved_by_the_host() {
    let _t = common::test();
    let script = "
        var seen = 'not run';
        Promise.resolve().then(function () { seen = 'ran'; });
        function execute() { return Response.success(seen); }
    ";
    let r = run_script(script, 0);
    assert_eq!(r.status, S::Ok);
    assert_eq!(r.output_json, "\"not run\"");
}

// ---------------------------------------------------------------- load()

fn files_with(util: &str) -> Vec<SourceFile> {
    vec![
        file(
            "search.js",
            "load('util.js'); function execute() { return Response.success(helper()); }",
        ),
        file("util.js", util),
    ]
}

#[test]
fn load_runs_a_file_in_the_same_global_scope() {
    let _t = common::test();
    let r = run_files(
        files_with("function helper() { return 'from util'; }"),
        "{}",
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, "\"from util\"");
}

#[test]
fn a_file_loads_at_most_once_per_call() {
    let _t = common::test();
    let files = vec![
        file(
            "search.js",
            "var count = 0; load('util.js'); load('util.js'); load('search.js'); function execute() { return Response.success(count); }",
        ),
        file("util.js", "count++;"),
    ];
    let r = run_files(files, "{}");
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(
        r.output_json, "1",
        "util.js ran once and the entry did not rerun"
    );
    // A new call starts with a fresh scope.
    let r = run_files(
        vec![
            file("search.js", "var count = 0; load('util.js'); function execute() { return Response.success(count); }"),
            file("util.js", "count++;"),
        ],
        "{}",
    );
    assert_eq!(r.output_json, "1");
}

#[test]
fn load_inside_a_loaded_file_works() {
    let _t = common::test();
    let files = vec![
        file(
            "search.js",
            "load('a.js'); function execute() { return Response.success(fromB); }",
        ),
        file("a.js", "load('b.js');"),
        file("b.js", "var fromB = 'deep';"),
    ];
    let r = run_files(files, "{}");
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, "\"deep\"");
}

#[test]
fn load_rejects_paths_and_unknown_files() {
    let _t = common::test();
    let names = [
        "../x.js",
        "a/b.js",
        "/etc/passwd",
        "x.json",
        "missing.js",
        "util",
        "",
        "..\\x.js",
    ];
    for name in names {
        let script = format!(
            "load({}); function execute() {{ return Response.success(1); }}",
            serde_like_quote(name)
        );
        let r = run_files(vec![file("search.js", &script), file("util.js", "")], "{}");
        assert_eq!(r.status, S::ScriptError, "load({name:?}): {r:?}");
        assert!(r.js_error.is_some(), "load({name:?})");
        assert!(r.error_message.contains("load"), "{}", r.error_message);
    }
    // The script can catch the failure itself.
    let r = run_script(
        "var msg; try { load('../x.js'); } catch (e) { msg = e.message; } function execute() { return Response.success(msg); }",
        0,
    );
    assert_eq!(r.status, S::Ok);
    assert!(r.output_json.contains("load"), "{}", r.output_json);
}

fn serde_like_quote(s: &str) -> String {
    format!("'{}'", s.replace('\\', "\\\\").replace('\'', "\\'"))
}

#[test]
fn load_of_a_non_string_throws() {
    let _t = common::test();
    let r = run_script(
        "load(5); function execute() { return Response.success(1); }",
        0,
    );
    assert_eq!(r.status, S::ScriptError, "{r:?}");
}

#[test]
fn error_in_a_loaded_file_names_that_file() {
    let _t = common::test();
    let r = run_files(
        files_with("var a = 1;\nthrow new Error('util broke');"),
        "{}",
    );
    assert_eq!(r.status, S::ScriptError);
    let js = r.js_error.expect("js_error");
    assert!(js.message.contains("util broke"));
    assert!(js.stack.contains("util.js:2"), "{js:?}");

    let r = run_files(files_with("var = ;"), "{}");
    assert_eq!(r.status, S::ScriptError);
    assert!(r.js_error.expect("js_error").stack.contains("util.js:1"));
}

#[test]
fn only_files_of_the_request_can_be_loaded() {
    let _t = common::test();
    let r = run_files(
        vec![file(
            "search.js",
            "load('lyrics.js'); function execute() { return Response.success(1); }",
        )],
        "{}",
    );
    assert_eq!(r.status, S::ScriptError);
}

// ------------------------------------------------------ malformed requests

#[test]
fn malformed_requests_are_internal_not_panics() {
    let _t = common::test();
    let job = rt::begin_job();
    let mut req = request_with(job, vec![file("search.js", OK_SCRIPT)], "{not json", 0);
    let r = block_on(rt::run(req.clone()));
    assert_eq!(r.status, S::Internal, "{r:?}");

    let job = rt::begin_job();
    req = request_with(job, vec![file("other.js", OK_SCRIPT)], "{}", 0);
    let r = block_on(rt::run(req));
    assert_eq!(r.status, S::Internal, "entry not in files: {r:?}");

    let job = rt::begin_job();
    let req = request_with(
        job,
        vec![file("search.js", OK_SCRIPT), file("search.js", "")],
        "{}",
        0,
    );
    let r = block_on(rt::run(req));
    assert_eq!(r.status, S::Internal, "duplicate name: {r:?}");
}

// ------------------------------------------- result fields on every status

fn assert_fields_present(r: &ScriptResult) {
    // Present (empty) on every status: nothing here captures console output yet.
    assert!(r.logs.is_empty(), "{:?}", r.status);
    assert_eq!(r.fetch_failure, None, "{:?}", r.status);
    assert_eq!(r.storage_json, None, "{:?}", r.status);
}

#[test]
fn every_status_carries_logs_fetch_failure_and_an_explanation() {
    let _t = common::test();
    let cancelled_before_start = {
        let id = rt::begin_job();
        rt::cancel_job(id);
        block_on(rt::run(request_with(
            id,
            vec![file("search.js", OK_SCRIPT)],
            "{}",
            0,
        )))
    };
    let cancelled_while_running = {
        let id = rt::begin_job();
        let canceller = thread::spawn(move || {
            thread::sleep(Duration::from_millis(100));
            rt::cancel_job(id);
        });
        let r = block_on(rt::run(request_with(
            id,
            vec![file("search.js", "function execute() { while (true) {} }")],
            "{}",
            0,
        )));
        canceller.join().unwrap();
        r
    };
    let internal = {
        let id = rt::begin_job();
        block_on(rt::run(request_with(
            id,
            vec![file("search.js", OK_SCRIPT)],
            "{not json",
            0,
        )))
    };
    let runs: Vec<(S, ScriptResult)> = vec![
        (S::Ok, run_script(OK_SCRIPT, 0)),
        (
            S::ScriptError,
            run_script("function execute() { throw new Error('boom'); }", 0),
        ),
        (
            S::Timeout,
            run_script("function execute() { while (true) {} }", 150),
        ),
        (
            S::Memory,
            run_script("function execute() { var a = []; for (;;) a.push({}); }", 0),
        ),
        (
            S::Stack,
            run_script("function execute() { function f() { f(); } f(); }", 0),
        ),
        (
            S::OutputTooLarge,
            run_script(
                "function execute() { return Response.success('x'.repeat(3 << 20)); }",
                0,
            ),
        ),
        (S::Cancelled, cancelled_before_start),
        (S::Cancelled, cancelled_while_running.clone()),
        (S::Internal, internal),
    ];
    for (status, r) in &runs {
        assert_eq!(r.status, *status, "{r:?}");
        assert_fields_present(r);
        if *status == S::Ok {
            assert_eq!(r.error_message, "");
        } else {
            assert!(
                !r.error_message.is_empty(),
                "{status:?} must explain itself"
            );
        }
    }

    // js_error: message and stack for a thrown error ...
    let js = runs[1]
        .1
        .js_error
        .clone()
        .expect("scriptError has js_error");
    assert!(
        js.message.contains("boom") && !js.stack.is_empty(),
        "{js:?}"
    );
    // ... present for every limit that stops running JS ...
    for i in [2, 3, 4, 7] {
        let js = runs[i].1.js_error.clone();
        assert!(
            js.is_some_and(|j| !j.message.is_empty()),
            "{:?} has no js_error",
            runs[i].0
        );
    }
    // ... and absent, with an explanation, where no JS was running.
    for i in [0, 5, 6, 8] {
        assert_eq!(runs[i].1.js_error, None, "{:?}", runs[i].0);
    }
}

// ---------------------------------------------------------- compile-only

#[test]
fn check_script_reports_a_syntax_error_with_its_line() {
    let _t = common::test();
    let p = common::runtime()
        .check_script("search.js", "var a = 1;\n\nvar b = ;\n")
        .expect("problem");
    assert_eq!(p.line, 3, "{p:?}");
    assert!(!p.message.is_empty());
}

#[test]
fn check_script_accepts_valid_code_without_running_it() {
    let _t = common::test();
    for code in [
        "throw new Error('top level');",
        "while (true) {}",
        "function execute(input) { return Response.success(input); }",
        "with (Math) { max(1, 2); }",
    ] {
        let started = Instant::now();
        assert_eq!(common::runtime().check_script("a.js", code), None, "{code}");
        assert!(started.elapsed() < Duration::from_secs(5), "{code}");
    }
}

#[test]
fn check_script_survives_absurdly_deep_nesting() {
    let _t = common::test();
    let deep = format!("var a = {}1{};", "(".repeat(200_000), ")".repeat(200_000));
    // Either a clean problem or a pass; never a crash of the test process.
    let _ = common::runtime().check_script("deep.js", &deep);
}

// ---------------------------------------------------------------- job ids

#[test]
fn unknown_or_cancelled_job_ids_return_cancelled_at_once() {
    let _t = common::test();
    let started = Instant::now();
    let r = block_on(rt::run(request_with(
        u32::MAX,
        vec![file("search.js", OK_SCRIPT)],
        "{}",
        0,
    )));
    assert_eq!(r.status, S::Cancelled);
    for _ in 0..100 {
        let id = rt::begin_job();
        rt::cancel_job(id);
        let r = block_on(rt::run(request_with(
            id,
            vec![file("search.js", OK_SCRIPT)],
            "{}",
            0,
        )));
        assert_eq!(r.status, S::Cancelled);
        assert_eq!(r.js_error, None);
    }
    assert!(started.elapsed() < Duration::from_secs(5));
}

#[test]
fn a_job_id_runs_only_once() {
    let _t = common::test();
    let id = rt::begin_job();
    let first = block_on(rt::run(request_with(
        id,
        vec![file("search.js", OK_SCRIPT)],
        "{}",
        0,
    )));
    assert_eq!(first.status, S::Ok);
    let second = block_on(rt::run(request_with(
        id,
        vec![file("search.js", OK_SCRIPT)],
        "{}",
        0,
    )));
    assert_eq!(second.status, S::Cancelled);
}

// ------------------------------------------------------ creation cost

#[test]
fn fresh_runtime_and_context_per_call_is_cheap() {
    let _t = common::test();
    const RUNS: u32 = 300;
    let make = || {
        engine::JobSpec::new(
            [("search.js".to_owned(), OK_SCRIPT.to_owned())],
            "search.js".to_owned(),
            "{}".to_owned(),
            limits::DEFAULT_WALL_TIME,
            Arc::new(AtomicBool::new(false)),
        )
        .unwrap()
    };
    let spec = make();
    let on_worker_stack = |spec: engine::JobSpec| {
        thread::Builder::new()
            .stack_size(limits::THREAD_STACK_BYTES)
            .spawn(move || {
                let _ = engine::run_job(&spec); // warm up
                let started = Instant::now();
                for _ in 0..RUNS {
                    assert_eq!(engine::run_job(&spec).status, S::Ok);
                }
                started.elapsed()
            })
            .unwrap()
            .join()
            .unwrap()
    };
    let total = on_worker_stack(spec);
    let per_call = total / RUNS;
    println!("per-call Runtime + Context + trivial script: {per_call:?} (over {RUNS} runs)");
    // The budget is 5 ms; the assertion is loose so a loaded machine or a
    // debug build does not fail it. The number printed above is the report.
    assert!(per_call < Duration::from_millis(50), "{per_call:?}");
}
