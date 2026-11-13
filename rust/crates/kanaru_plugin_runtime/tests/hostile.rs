//! Plugins that misbehave, run on the real runtime. Each must end as the
//! documented status, keep the console line it wrote before misbehaving, and
//! leave the pool able to run the next job. The scripts are those of the old
//! app's hostile fixtures. (The cases that need `fetch` come with its natives.)

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::time::{Duration, Instant};

use common::{file, run_files, run_script};
use kanaru_plugin_runtime::{limits, ScriptResult, ScriptStatus as S};

fn assert_pool_still_works() {
    let r = run_script("function execute() { return Response.success('fine'); }", 0);
    assert_eq!(r.status, S::Ok, "{r:?}");
}

/// Runs the plugin's `search.js` with the default wall time.
fn hostile(code: &str, timeout_ms: u32) -> ScriptResult {
    run_script(code, timeout_ms)
}

#[test]
fn big_allocation_is_a_memory_failure() {
    let _t = common::test();
    let r = hostile(
        r#"function execute(input) {
             console.log("before the allocation");
             var big = "x".repeat(64 * 1024 * 1024);
             return Response.success([big.length]);
           }"#,
        0,
    );
    assert_eq!(r.status, S::Memory, "{r:?}");
    assert_eq!(r.logs, vec!["before the allocation"]);
    assert_eq!(r.output_json, "");
    assert_pool_still_works();
}

#[test]
fn deep_recursion_is_a_stack_failure() {
    let _t = common::test();
    let r = hostile(
        r#"function down(n) { return 1 + down(n + 1); }
           function execute(input) {
             console.log("before the recursion");
             return Response.success([down(0)]);
           }"#,
        0,
    );
    assert_eq!(r.status, S::Stack, "{r:?}");
    assert_eq!(r.logs, vec!["before the recursion"]);
    assert_pool_still_works();
}

#[test]
fn infinite_loop_is_stopped_by_the_wall_time() {
    let _t = common::test();
    let started = Instant::now();
    let r = hostile(
        r#"function execute(input) {
             console.log("before the loop");
             while (true) {}
           }"#,
        400,
    );
    assert_eq!(r.status, S::Timeout, "{r:?}");
    assert_eq!(r.logs, vec!["before the loop"]);
    assert!(started.elapsed() < Duration::from_secs(2));
    assert_pool_still_works();
}

#[test]
fn redos_is_stopped_by_the_wall_time() {
    let _t = common::test();
    let started = Instant::now();
    let r = hostile(
        r#"function execute(input) {
             console.log("before the regex");
             var text = "a".repeat(64) + "!";
             /^(a+)+$/.test(text);
             return Response.success([]);
           }"#,
        400,
    );
    assert_eq!(r.status, S::Timeout, "{r:?}");
    assert_eq!(r.logs, vec!["before the regex"]);
    assert!(started.elapsed() < Duration::from_secs(2));
    assert_pool_still_works();
}

#[test]
fn huge_output_is_refused() {
    let _t = common::test();
    let r = hostile(
        r#"function execute(input) {
             console.log("before the answer");
             return Response.success(["x".repeat(3 * 1024 * 1024)]);
           }"#,
        0,
    );
    assert_eq!(r.status, S::OutputTooLarge, "{r:?}");
    assert_eq!(r.logs, vec!["before the answer"]);
    assert_eq!(r.output_json, "");
    assert_pool_still_works();
}

#[test]
fn console_spam_keeps_fifty_short_lines() {
    let _t = common::test();
    let r = hostile(
        r#"function execute(input) {
             for (var i = 0; i < 20000; i++) {
               console.log("line " + i + " " + "x".repeat(1000));
             }
             return Response.success([]);
           }"#,
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, "[]");
    assert_eq!(r.logs.len(), limits::MAX_LOG_LINES);
    assert!(r.logs[0].starts_with("line 0 x"));
    assert!(r
        .logs
        .iter()
        .all(|l| l.chars().count() <= limits::MAX_LOG_LINE_CHARS));
    assert_pool_still_works();
}

#[test]
fn wrong_output_shape_passes_through_the_runtime_untouched() {
    let _t = common::test();
    // The runtime only guarantees a `Response`; that the data is an array is
    // checked by the code that reads the plugin's answer.
    let r = hostile(
        r#"function execute(input) {
             console.log("before the answer");
             return Response.success({ results: [] });
           }"#,
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, r#"{"results":[]}"#);
    assert_eq!(r.logs, vec!["before the answer"]);
}

#[test]
fn load_outside_the_package_is_a_script_error() {
    let _t = common::test();
    let r = run_files(
        vec![
            file(
                "search.js",
                r#"function execute(input) {
                     console.log("before the load");
                     load("../x.js");
                     return Response.success([]);
                   }"#,
            ),
            file(
                "lyrics.js",
                "function execute(id) { return Response.success(null); }",
            ),
        ],
        "{}",
    );
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert!(r.error_message.contains("load"), "{}", r.error_message);
    assert!(r.js_error.is_some());
    assert_eq!(r.logs, vec!["before the load"]);
}
