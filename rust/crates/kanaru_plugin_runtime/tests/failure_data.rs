//! A failed run still returns what was captured before it: console lines, the
//! JavaScript error (message and stack) when there is one and the changed
//! storage map. One script per failure; the same script prefix writes two log
//! lines and changes storage.
//!
//! The cases that need `fetch` (the first fetch failure kept, a host that
//! never answers, an abandoned or panicking host call, the Rust byte budget)
//! come with the fetch natives.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::thread;
use std::time::Duration;

use common::{block_on, file, request_with, rt, run_script, run_with_state};
use kanaru_plugin_runtime::{ScriptResult, ScriptStatus as S};

/// The shared start of every script: two log lines, a storage change.
fn script(body: &str) -> String {
    format!(
        "function execute() {{
           console.log('step one');
           console.error({{stage: 'two'}});
           localStorage.setItem('seen', 'yes');
           {body}
         }}"
    )
}

/// What every failure must still carry.
fn assert_captured(r: &ScriptResult) {
    assert_eq!(
        r.logs,
        vec!["step one".to_owned(), r#"{"stage":"two"}"#.to_owned()],
        "logs, status {:?}",
        r.status
    );
    // A changed map is returned only when the script finished on its own.
    let finished = matches!(r.status, S::Ok | S::ScriptError);
    assert_eq!(
        r.storage_json.as_deref(),
        finished.then_some(r#"{"seen":"yes"}"#),
        "{r:?}"
    );
}

fn run(body: &str, timeout_ms: u32) -> ScriptResult {
    run_with_state(&script(body), &[], "", timeout_ms)
}

fn assert_js_error(r: &ScriptResult) {
    let js = r
        .js_error
        .as_ref()
        .unwrap_or_else(|| panic!("js_error, {r:?}"));
    assert!(
        !js.message.is_empty() || r.status == S::Timeout || r.status == S::Cancelled,
        "{js:?}"
    );
    assert!(
        js.stack.contains("search.js:"),
        "stack with line numbers: {js:?}"
    );
}

#[test]
fn script_error_keeps_logs_and_js_error() {
    let _t = common::test();
    let r = run("throw new TypeError('kaput');", 0);
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_captured(&r);
    assert_js_error(&r);
    assert!(r.js_error.unwrap().message.contains("kaput"));
}

#[test]
fn timeout_keeps_logs_and_js_error() {
    let _t = common::test();
    let r = run("while (true) {}", 300);
    assert_eq!(r.status, S::Timeout, "{r:?}");
    assert_captured(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn heap_memory_keeps_logs_and_js_error() {
    let _t = common::test();
    let r = run("var a = []; while (true) a.push({x: a.length});", 0);
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_captured(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn stack_overflow_keeps_logs_and_js_error() {
    let _t = common::test();
    let r = run("function f() { return f() + 1; } return f();", 0);
    assert_eq!(r.status, S::Stack, "{r:?}");
    assert_captured(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn output_too_large_keeps_logs_and_has_no_js_error() {
    let _t = common::test();
    let r = run("return Response.success('x'.repeat(3 * 1024 * 1024));", 0);
    assert_eq!(r.status, S::OutputTooLarge, "{r:?}");
    assert_captured(&r);
    assert_eq!(r.js_error, None);
}

#[test]
fn response_error_and_invalid_response_keep_everything_too() {
    let _t = common::test();
    let r = run(
        "return Response.error('nope', {kind: 'rateLimited', retryAfterSec: 9});",
        0,
    );
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_captured(&r);
    let r = run("return 5;", 0);
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_captured(&r);
}

#[test]
fn error_texts_stay_capped() {
    let _t = common::test();
    let r = run_script(
        "function execute() { console.log('x'); throw new Error('m'.repeat(5000)); }",
        0,
    );
    let js = r.js_error.unwrap();
    assert_eq!(js.message.chars().count(), 1000);
    assert!(js.stack.len() <= 16 * 1024);
}

#[test]
fn storage_changes_are_returned_only_for_a_run_that_finished_on_its_own() {
    let _t = common::test();
    let change = "localStorage.setItem('k', 'v');";
    let saved = Some(r#"{"k":"v"}"#);
    let cases: [(&str, S, Option<&str>); 6] = [
        ("throw new Error('x');", S::ScriptError, saved),
        ("return Response.error('no');", S::ScriptError, saved),
        ("return Response.success(1);", S::Ok, saved),
        ("while (true) {}", S::Timeout, None),
        (
            "var a = []; while (true) a.push({x: a.length});",
            S::Memory,
            None,
        ),
        (
            "return Response.success('x'.repeat(3 * 1024 * 1024));",
            S::OutputTooLarge,
            None,
        ),
    ];
    for (tail, status, want) in cases {
        let code = format!("function execute() {{ {change} {tail} }}");
        // Only the endless loop needs a short deadline.
        let r = run_with_state(
            &code,
            &[],
            "",
            if tail.starts_with("while") { 300 } else { 0 },
        );
        assert_eq!(r.status, status, "{tail}: {r:?}");
        assert_eq!(r.storage_json.as_deref(), want, "{tail}");
    }
}

#[test]
fn storage_changes_are_dropped_when_the_job_is_cancelled() {
    let _t = common::test();
    let job = rt::begin_job();
    let canceller = thread::spawn(move || {
        thread::sleep(Duration::from_millis(250));
        rt::cancel_job(job);
    });
    let request = request_with(
        job,
        vec![file(
            "search.js",
            "function execute() { localStorage.setItem('k', 'v'); while (true) {} }",
        )],
        "{}",
        0,
    );
    let r = block_on(rt::run(request));
    canceller.join().unwrap();
    assert_eq!(r.status, S::Cancelled, "{r:?}");
    assert_eq!(r.storage_json, None);
}

#[test]
fn a_caught_memory_failure_is_still_memory_and_drops_the_storage_change() {
    let _t = common::test();
    // Heap OOM caught by the script: the script returns normally.
    let r = run(
        "try { var a = []; while (true) a.push({x: a.length}); } catch (e) {}
         return Response.success(1);",
        0,
    );
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_eq!(r.storage_json, None);
    assert_eq!(r.logs.len(), 2, "logs still come back: {r:?}");
}
