//! The `fetch` request body cap (1 MiB) against the 32 MiB script heap: a
//! chat-sized input and a body at the cap go through a streamed `fetch`; one
//! byte more is refused before the host sees it.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::sync::Arc;

use common::{
    block_on, file, request_with, rt, stream_answer_with, stream_chunk, stream_opened, FakeHost,
};
use kanaru_plugin_runtime::{ScriptResult, ScriptStatus as S, StreamOp as Op};

const KIB: usize = 1024;
const MIB: usize = 1024 * 1024;

/// A JSON input of Vietnamese text, at least `bytes` bytes of UTF-8.
fn vietnamese_input(bytes: usize) -> String {
    let unit = "Tiếng Việt có dấu: ắ ằ ẳ ẵ ặ ế ề ể ễ ệ ố ồ ổ ỗ ộ ư ơ đ. ";
    let mut text = String::new();
    while text.len() < bytes {
        text.push_str(unit);
    }
    format!(r#"{{"text":"{text}"}}"#)
}

/// Runs `code` as a streaming run with `input_json`.
fn run(code: &str, input_json: &str, host: &Arc<FakeHost>) -> ScriptResult {
    let job = rt::begin_job();
    let request = request_with(job, vec![file("search.js", code)], input_json, 0);
    block_on(rt::run_streaming(request, 0, host.clone(), None))
}

fn streams_host() -> Arc<FakeHost> {
    FakeHost::streams(stream_answer_with(|call| match call.op {
        Op::Open => stream_opened(),
        _ => stream_chunk(b"", true),
    }))
}

#[test]
fn a_768_kib_vietnamese_input_and_a_1_mib_body_fit_the_32_mib_heap() {
    let _t = common::test();
    let host = streams_host();
    let input = vietnamese_input(768 * KIB);
    assert!(input.len() >= 768 * KIB);
    let code = format!(
        "function execute(input) {{
           var copy = JSON.stringify(input);
           var pad = {MIB} - JSON.stringify({{a: ''}}).length;
           var body = JSON.stringify({{a: 'x'.repeat(pad)}});
           fetch('https://t.test/chat', {{method: 'POST', body: body, stream: true}});
           return Response.success(copy.length > 0 && input.text.length > 0);
         }}"
    );
    let r = run(&code, &input, &host);
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, "true");
    let calls = host.stream_calls();
    let open = calls.iter().find(|c| c.op == Op::Open).unwrap();
    assert_eq!(open.request.as_ref().unwrap().body.len(), MIB);
}

#[test]
fn a_body_over_1_mib_throws_invalid_request_error_before_the_host() {
    let _t = common::test();
    let host = streams_host();
    let code = format!(
        "function execute() {{
           var name;
           try {{
             fetch('https://t.test/chat', {{method: 'POST', body: 'x'.repeat({MIB} + 1), stream: true}});
           }} catch (e) {{ name = e.name; }}
           return Response.success(name);
         }}"
    );
    let r = run(&code, "{}", &host);
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#""InvalidRequestError""#);
    assert!(host.stream_calls().is_empty());
    assert!(host.requests().is_empty());
}
