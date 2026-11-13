//! A failed run still returns what was captured before it: console lines, the
//! JavaScript error (message and stack) when there is one, the first fetch
//! failure and the changed storage map. One script per failure; the same
//! script prefix writes a log line, makes a failing fetch and changes storage.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use common::{
    block_on, file, ok_response, outcome_response, request_with, rt, run_with_host, runtime,
    FakeHost, RunOptions,
};
use kanaru_plugin_runtime::{
    FetchFailureKind, FetchOutcome, Pending, PluginHost, ScriptResult, ScriptStatus as S,
};

/// Answers `/fail` with a network error and everything else with 5 MiB.
fn host() -> Arc<FakeHost> {
    FakeHost::answering(|request| {
        if request.url.ends_with("/fail") {
            outcome_response(FetchOutcome::Network)
        } else {
            ok_response(200, &vec![b'x'; 5 * 1024 * 1024])
        }
    })
}

/// Answers the first fetch (`/fail`) with a network error, then never answers.
fn hanging_after_first() -> Arc<FakeHost> {
    let calls = Arc::new(AtomicU32::new(0));
    FakeHost::with_futures(move |_request| -> Pending<_> {
        if calls.fetch_add(1, Ordering::SeqCst) == 0 {
            Box::pin(async { outcome_response(FetchOutcome::Network) })
        } else {
            Box::pin(std::future::pending())
        }
    })
}

/// The shared start of every script: log, fail one fetch, change storage.
fn script(body: &str) -> String {
    format!(
        "function execute() {{
           console.log('step one');
           console.error({{stage: 'two'}});
           try {{ fetch('https://t.test/fail'); }} catch (e) {{ console.log('caught ' + e.name); }}
           localStorage.setItem('seen', 'yes');
           {body}
         }}"
    )
}

/// What every failure must still carry.
fn assert_captured(r: &ScriptResult) {
    assert_eq!(
        r.logs,
        vec![
            "step one".to_owned(),
            r#"{"stage":"two"}"#.to_owned(),
            "caught NetworkError".to_owned()
        ],
        "logs, status {:?}",
        r.status
    );
    let failure = r
        .fetch_failure
        .as_ref()
        .unwrap_or_else(|| panic!("fetch_failure, {r:?}"));
    assert_eq!(failure.kind, FetchFailureKind::Network, "{r:?}");
    // A changed map is returned only when the script finished on its own.
    let finished = matches!(r.status, S::Ok | S::ScriptError);
    assert_eq!(
        r.storage_json.as_deref(),
        finished.then_some(r#"{"seen":"yes"}"#),
        "{r:?}"
    );
}

fn run(body: &str, host: Arc<dyn PluginHost>, timeout_ms: u32) -> ScriptResult {
    run_with_host(
        &script(body),
        host,
        RunOptions {
            timeout_ms,
            ..RunOptions::default()
        },
    )
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
fn script_error_keeps_logs_js_error_and_fetch_failure() {
    let _t = common::test();
    let r = run("throw new TypeError('kaput');", host(), 0);
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_captured(&r);
    assert_js_error(&r);
    assert!(r.js_error.unwrap().message.contains("kaput"));
}

#[test]
fn timeout_keeps_logs_js_error_and_fetch_failure() {
    let _t = common::test();
    let r = run("while (true) {}", host(), 300);
    assert_eq!(r.status, S::Timeout, "{r:?}");
    assert_captured(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn timeout_while_dart_never_answers_keeps_everything() {
    let _t = common::test();
    let hanging_after_first = hanging_after_first();
    let r = run("fetch('https://t.test/hangs');", hanging_after_first, 300);
    assert_eq!(r.status, S::Timeout, "{r:?}");
    assert_captured(&r);
}

#[test]
fn heap_memory_keeps_logs_js_error_and_fetch_failure() {
    let _t = common::test();
    let r = run("var a = []; while (true) a.push({x: a.length});", host(), 0);
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_captured(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn the_rust_byte_budget_keeps_logs_js_error_and_fetch_failure() {
    let _t = common::test();
    let r = run(
        "var kept = []; for (var i = 0; i < 10; i++) kept.push(fetch('https://t.test/big'));",
        host(),
        0,
    );
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_captured(&r);
    assert_js_error(&r);
}

#[test]
fn stack_overflow_keeps_logs_js_error_and_fetch_failure() {
    let _t = common::test();
    let r = run("function f() { return f() + 1; } return f();", host(), 0);
    assert_eq!(r.status, S::Stack, "{r:?}");
    assert_captured(&r);
    assert!(r.js_error.is_some());
}

#[test]
fn output_too_large_keeps_logs_and_fetch_failure_and_has_no_js_error() {
    let _t = common::test();
    let r = run(
        "return Response.success('x'.repeat(3 * 1024 * 1024));",
        host(),
        0,
    );
    assert_eq!(r.status, S::OutputTooLarge, "{r:?}");
    assert_captured(&r);
    assert_eq!(r.js_error, None);
}

#[test]
fn cancel_during_a_fetch_keeps_everything_captured_before() {
    let _t = common::test();
    let hanging_after_first = hanging_after_first();
    let job = rt::begin_job();
    let canceller = thread::spawn(move || {
        thread::sleep(Duration::from_millis(250));
        rt::cancel_job(job);
    });
    let request = request_with(
        job,
        vec![file("search.js", &script("fetch('https://t.test/hangs');"))],
        "{}",
        0,
    );
    let r = block_on(runtime().run(request, hanging_after_first));
    canceller.join().unwrap();
    assert_eq!(r.status, S::Cancelled, "{r:?}");
    assert_captured(&r);
}

#[test]
fn abandoned_fetch_ends_cancelled_with_its_failure_and_the_earlier_data() {
    let _t = common::test();
    let host = FakeHost::answering(|request| {
        if request.url.ends_with("/fail") {
            outcome_response(FetchOutcome::Network)
        } else {
            outcome_response(FetchOutcome::Abandoned)
        }
    });
    let r = run("fetch('https://t.test/walked-away');", host, 0);
    assert_eq!(r.status, S::Cancelled, "{r:?}");
    assert_captured(&r);
    assert_js_error(&r);
}

#[test]
fn a_throwing_dart_callback_is_a_network_failure_even_when_uncaught() {
    let _t = common::test();
    let host = FakeHost::with_futures(|request| -> Pending<_> {
        if request.url.ends_with("/fail") {
            Box::pin(async { outcome_response(FetchOutcome::Network) })
        } else {
            Box::pin(async { panic!("the app threw") })
        }
    });
    let r = run("fetch('https://t.test/boom');", host, 0);
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_captured(&r);
    assert!(r.js_error.as_ref().unwrap().message.contains("network"));
    assert!(
        !format!("{r:?}").contains("the app threw"),
        "panic text is not kept"
    );
    // The pool keeps working.
    let ok = common::run_script("function execute() { return Response.success(1); }", 0);
    assert_eq!(ok.status, S::Ok);
}

#[test]
fn response_error_and_invalid_response_keep_everything_too() {
    let _t = common::test();
    let r = run(
        "return Response.error('nope', {kind: 'rateLimited', retryAfterSec: 9});",
        host(),
        0,
    );
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_captured(&r);
    let r = run("return 5;", host(), 0);
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_captured(&r);
}

#[test]
fn never_answering_dart_is_a_timeout_even_for_the_first_fetch() {
    let _t = common::test();
    let r = run_with_host(
        "function execute() { console.log('only line'); fetch('https://t.test/'); }",
        FakeHost::never_answering(),
        RunOptions {
            timeout_ms: 250,
            ..RunOptions::default()
        },
    );
    assert_eq!(r.status, S::Timeout, "{r:?}");
    assert_eq!(r.logs, vec!["only line".to_owned()]);
    assert_eq!(r.fetch_failure, None, "no outcome ever arrived");
}

#[test]
fn error_texts_stay_capped() {
    let _t = common::test();
    let r = run_with_host(
        "function execute() { console.log('x'); throw new Error('m'.repeat(5000)); }",
        host(),
        RunOptions::default(),
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
        let r = run_with_host(
            &code,
            host(),
            RunOptions {
                // Only the endless loop needs a short deadline.
                timeout_ms: if tail.starts_with("while") { 300 } else { 0 },
                ..RunOptions::default()
            },
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
    let r = block_on(runtime().run(request, host()));
    canceller.join().unwrap();
    assert_eq!(r.status, S::Cancelled, "{r:?}");
    assert_eq!(r.storage_json, None);
}

#[test]
fn a_caught_memory_failure_is_still_memory_and_drops_the_storage_change() {
    let _t = common::test();
    // Rust byte budget: the overrun is caught and the script returns normally.
    let r = run(
        "var kept = [];
         for (var i = 0; i < 6; i++) {
           try { kept.push(fetch('https://t.test/big')); } catch (e) {}
         }
         return Response.success(1);",
        host(),
        0,
    );
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_eq!(r.storage_json, None);
    assert_eq!(r.logs.len(), 3, "logs still come back: {r:?}");

    // Heap OOM caught by the script.
    let r = run(
        "try { var a = []; while (true) a.push({x: a.length}); } catch (e) {}
         return Response.success(1);",
        host(),
        0,
    );
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_eq!(r.storage_json, None);
}
