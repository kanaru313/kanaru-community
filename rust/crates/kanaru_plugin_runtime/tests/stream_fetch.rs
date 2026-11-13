//! Streamed `fetch` responses: `readLine`, `read`, `text` and `close`, the
//! limits and the dead-stream rules. No test touches the network: a scripted
//! `FakeHost` plays the app (and checks every stream call carries an
//! `install_id`).

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

use common::{
    block_on, collecting_emitter, count_ops, file, ok_response, plain_stream, request_with, rt,
    run_streaming, run_streaming_idle, scripted_stream, stream_answer_with, stream_chunk,
    stream_failed, stream_opened, FakeHost, RunOptions, StreamFn,
};
use kanaru_plugin_runtime::{
    FetchFailureKind as Kind, FetchOutcome as Outcome, ScriptResult, ScriptStatus as S,
    StreamOp as Op,
};

#[test]
fn a_stream_left_open_at_run_end_gets_no_close_call() {
    let _t = common::test();
    let host = FakeHost::streams(stream_answer_with(|call| match call.op {
        Op::Open => stream_opened(),
        _ => stream_chunk(b"x", false),
    }));
    let code = "function execute() { fetch('https://t.test/s', {stream: true}); return Response.success(1); }";
    let (r, _) = run(code, &host);
    assert_ok(&r);
    // The host closes leftovers itself (its per-run table); Rust sends none.
    assert_eq!(count_ops(&host, Op::Open), 1);
    assert_eq!(count_ops(&host, Op::Close), 0);
}

const KIB: usize = 1024;
const MIB: usize = 1024 * 1024;

/// Runs `code` as a streaming run; returns the result and the emitted events.
fn run(code: &str, host: &Arc<FakeHost>) -> (ScriptResult, Vec<String>) {
    let (emitter, events) = collecting_emitter();
    let r = run_streaming(code, host.clone(), RunOptions::default(), Some(emitter));
    let seen = events.lock().unwrap().clone();
    (r, seen)
}

fn assert_ok(r: &ScriptResult) {
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
}

/// Makes a `Close` call never complete, whatever `inner` does for the rest.
/// The host still records every call.
fn hanging_close(inner: StreamFn) -> StreamFn {
    Arc::new(move |call| {
        if call.op == Op::Close {
            Box::pin(std::future::pending())
        } else {
            inner(call)
        }
    })
}

/// Open and Close are answered at once, a Read never.
fn pending_read() -> StreamFn {
    Arc::new(|call| match call.op {
        Op::Read => Box::pin(std::future::pending()),
        Op::Open => Box::pin(async { stream_opened() }),
        _ => Box::pin(async { stream_chunk(b"", false) }),
    })
}

const OPEN: &str = "fetch('https://t.test/sse', {stream: true})";

#[test]
fn an_sse_body_is_read_line_by_line_and_a_cr_never_waits_for_more() {
    let _t = common::test();
    let (emitter, events) = collecting_emitter();
    let seen_at_third_read = Arc::new(Mutex::new(None));
    let probe = seen_at_third_read.clone();
    let log_events = events.clone();
    let reads = Arc::new(AtomicUsize::new(0));
    let counter = reads.clone();
    let host = FakeHost::streams(scripted_stream(
        vec![
            b"data: a\n\nda".to_vec(),
            b"ta: b\r".to_vec(),
            b"\n\r\n".to_vec(),
        ],
        move |call, reply| {
            if call.op == Op::Read && counter.fetch_add(1, Ordering::SeqCst) == 2 {
                *probe.lock().unwrap() = Some(log_events.lock().unwrap().clone());
            }
            reply
        },
    ));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, lines = [], l;
           while ((l = r.readLine()) !== null) {{
             lines.push(l);
             if (l.indexOf('data: ') === 0) emit(l.slice(6));
           }}
           return Response.success(lines);
         }}"
    );
    let r = run_streaming(&code, host.clone(), RunOptions::default(), Some(emitter));
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["data: a","","data: b",""]"#);
    assert_eq!(*events.lock().unwrap(), vec![r#""a""#, r#""b""#]);
    // `data: b` was emitted before the third chunk was requested.
    assert_eq!(
        seen_at_third_read.lock().unwrap().clone().unwrap(),
        vec![r#""a""#, r#""b""#]
    );
    assert_eq!(count_ops(&host, Op::Read), 4);
    assert_eq!(count_ops(&host, Op::Close), 0);
}

#[test]
fn read_text_and_close_behave() {
    let _t = common::test();
    let host = FakeHost::streams(plain_stream(&[b"ab", b"cd"]));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, a = r.read(), b = r.read(), c = r.read();
           return Response.success([a, b, c, r.status, r.ok, r.url, r.header('Content-Type')]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(
        r.output_json,
        r#"["ab","cd",null,200,true,"https://example.test/stream","text/event-stream"]"#
    );
    assert_eq!(count_ops(&host, Op::Close), 0);

    let host = FakeHost::streams(plain_stream(&[b"l1\nl2\nr", b"est"]));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, a = r.readLine(), b = r.readLine(), t = r.text();
           return Response.success([a, b, t, r.text(), r.readLine(), r.read()]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["l1","l2","rest","",null,null]"#);

    let host = FakeHost::streams(plain_stream(&[b"ab", b"cd"]));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, a = r.read();
           r.close(); r.close();
           return Response.success([a, r.read(), r.readLine(), r.text()]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["ab",null,null,""]"#);
    assert_eq!(count_ops(&host, Op::Close), 1);
    assert_eq!(count_ops(&host, Op::Read), 1);
}

#[test]
fn closing_an_ended_stream_sends_nothing_and_the_last_line_needs_no_terminator() {
    let _t = common::test();
    let host = FakeHost::streams(plain_stream(&[b"x\ny"]));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, a = r.readLine(), b = r.readLine(), c = r.readLine();
           r.close();
           return Response.success([a, b, c]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["x","y",null]"#);
    assert_eq!(count_ops(&host, Op::Close), 0);
}

#[test]
fn opens_carry_bounded_times_and_count_as_sends_but_reads_do_not() {
    let _t = common::test();
    let host = FakeHost::streaming(|_| ok_response(200, b""), plain_stream(&[b"1\n2\n3\n"]));
    let code = format!(
        "function execute() {{
           for (var i = 0; i < 9; i++) fetch('https://t.test/plain');
           var r = {OPEN}, n = 0;
           while (r.readLine() !== null) n++;
           var name;
           try {{ fetch('https://t.test/plain'); }} catch (e) {{ name = e.name; }}
           return Response.success([n, name]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"[3,"TooManyRequestsError"]"#);
    let calls = host.stream_calls();
    let open = calls.iter().find(|c| c.op == Op::Open).unwrap();
    assert_eq!(open.install_id, "test-install");
    let request = open.request.as_ref().unwrap();
    assert_eq!(request.install_id, "test-install");
    assert_eq!(request.url, "https://t.test/sse");
    assert_eq!(request.method, "GET");
    assert_eq!(request.max_sends, 1);
    assert!(request.deadline_ms <= 90_000, "{}", request.deadline_ms);
    assert!(
        (290_000..=300_000).contains(&open.lifetime_ms),
        "{}",
        open.lifetime_ms
    );
    let read = calls.iter().find(|c| c.op == Op::Read).unwrap();
    assert_eq!((read.max_bytes, read.request.is_none()), (64 * 1024, true));
    assert_eq!(read.wait_ms, 60_000);
}

#[test]
fn every_stream_op_carries_the_install_id() {
    let _t = common::test();
    let host = FakeHost::streams(plain_stream(&[b"a\n", b"b\n"]));
    let code = format!(
        "function execute() {{
           var r = {OPEN}; r.readLine(); r.close();
           return Response.success(1);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    let calls = host.stream_calls();
    let ops: Vec<Op> = calls.iter().map(|c| c.op).collect();
    assert_eq!(ops, vec![Op::Open, Op::Read, Op::Close]);
    assert!(calls.iter().all(|c| c.install_id == "test-install"));
}

#[test]
fn open_failures_are_named_and_a_rate_limit_keeps_its_retry_after() {
    let _t = common::test();
    let code = format!(
        "function execute() {{
           try {{ {OPEN}; }} catch (e) {{ return Response.success([e.name, e.retryAfterSec]); }}
         }}"
    );
    for (outcome, name) in [
        (Outcome::BlockedHost, "BlockedHostError"),
        (Outcome::NotConsented, "NotConsentedError"),
        (Outcome::InvalidRequest, "InvalidRequestError"),
        (Outcome::Network, "NetworkError"),
    ] {
        let host = FakeHost::streams(stream_answer_with(move |_| stream_failed(outcome)));
        let (r, _) = run(&code, &host);
        assert_ok(&r);
        assert_eq!(r.output_json, format!(r#"["{name}",null]"#));
    }
    let host = FakeHost::streams(stream_answer_with(|_| {
        let mut reply = stream_failed(Outcome::RateLimited);
        reply.retry_after_sec = Some(20);
        reply
    }));
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["RateLimitedError",20]"#);
    let failure = r.fetch_failure.unwrap();
    assert_eq!(failure.kind, Kind::RateLimited);
    assert_eq!(failure.retry_after_sec, Some(20));

    let host = FakeHost::streams(stream_answer_with(|_| stream_failed(Outcome::Abandoned)));
    let (r, _) = run(&code, &host);
    assert_eq!(r.status, S::Cancelled);
}

#[test]
fn a_failed_read_throws_closes_the_stream_and_later_reads_return_null() {
    let _t = common::test();
    let host = FakeHost::streams(scripted_stream(vec![b"a\n".to_vec()], |call, reply| {
        if call.op == Op::Read && reply.chunk.is_empty() {
            stream_failed(Outcome::Network)
        } else {
            reply
        }
    }));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, first = r.readLine(), name;
           try {{ r.readLine(); }} catch (e) {{ name = e.name; }}
           return Response.success([first, name, r.readLine(), r.read(), r.text()]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["a","NetworkError",null,null,""]"#);
    assert_eq!(count_ops(&host, Op::Read), 2);
    assert_eq!(count_ops(&host, Op::Close), 1);

    let host = FakeHost::streams(scripted_stream(vec![b"a\n".to_vec()], |call, reply| {
        if call.op == Op::Read && reply.chunk.is_empty() {
            stream_failed(Outcome::NotConsented)
        } else {
            reply
        }
    }));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, first = r.readLine(), name;
           try {{ r.readLine(); }} catch (e) {{ name = e.name; }}
           return Response.success([first, name]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["a","NotConsentedError"]"#);
    assert_eq!(count_ops(&host, Op::Close), 1);
}

#[test]
fn an_over_long_line_and_an_oversized_chunk_kill_the_stream() {
    let _t = common::test();
    let code = format!(
        "function execute() {{
           var r = {OPEN}, name;
           try {{ r.readLine(); }} catch (e) {{ name = e.name; }}
           return Response.success([name, r.readLine()]);
         }}"
    );
    // 1 MiB + 1 bytes without a terminator, in chunks of 64 KiB.
    let mut chunks = vec![vec![b'x'; 64 * KIB]; 16];
    chunks.push(vec![b'x'; 1]);
    let host = FakeHost::streams(scripted_stream(chunks, |_, reply| reply));
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["RangeError",null]"#);
    assert_eq!(count_ops(&host, Op::Close), 1);

    // Exactly 1 MiB then a terminator is fine.
    let mut chunks = vec![vec![b'x'; 64 * KIB]; 16];
    chunks.push(b"\n".to_vec());
    let host = FakeHost::streams(scripted_stream(chunks, |_, reply| reply));
    let code_ok = format!(
        "function execute() {{ var r = {OPEN}; return Response.success(r.readLine().length); }}"
    );
    let (r, _) = run(&code_ok, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, MIB.to_string());

    let host = FakeHost::streams(scripted_stream(
        vec![vec![b'x'; 64 * KIB + 1]],
        |_, reply| reply,
    ));
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["InvalidResponseError",null]"#);
    assert_eq!(count_ops(&host, Op::Close), 1);

    // A chunk that is empty but not the end would spin the read loop.
    let host = FakeHost::streams(scripted_stream(vec![Vec::new()], |_, reply| reply));
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["InvalidResponseError",null]"#);
    assert_eq!(count_ops(&host, Op::Close), 1);
}

#[test]
fn a_body_over_16_mib_is_refused() {
    let _t = common::test();
    let chunks = vec![vec![b'\n'; 64 * KIB]; 257];
    let host = FakeHost::streams(scripted_stream(chunks, |_, reply| reply));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, n = 0, name;
           try {{ while (r.readLine() !== null) n++; }} catch (e) {{ name = e.name; }}
           return Response.success([name, n]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    // 256 chunks of 64 KiB newlines are fine; the 257th passes 16 MiB.
    assert_eq!(
        r.output_json,
        format!(r#"["InvalidResponseError",{}]"#, 256 * 64 * KIB)
    );
    assert_eq!(count_ops(&host, Op::Close), 1);
}

#[test]
fn dead_streams_hold_their_slot_until_close_was_answered() {
    let _t = common::test();
    let inner = scripted_stream(vec![vec![b'x'; 64 * KIB]; 17], |_, reply| reply);
    let host = FakeHost::streams(hanging_close(inner));
    let code = format!(
        "function execute() {{
           var a = {OPEN}, killed, third;
           try {{ a.readLine(); }} catch (e) {{ killed = e.name; }}
           var b = {OPEN};
           try {{ {OPEN}; }} catch (e) {{ third = e.name; }}
           return Response.success([killed, third]);
         }}"
    );
    let started = Instant::now();
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["RangeError","TooManyStreamsError"]"#);
    assert_eq!(count_ops(&host, Op::Close), 1);
    assert!(started.elapsed() < Duration::from_secs(5));

    // An answered Close frees the slot: any number of streams in a row.
    let host = FakeHost::streams(plain_stream(&[b"a\n"]));
    let code = format!(
        "function execute() {{
           var a = {OPEN}; a.close();
           var b = {OPEN}; b.close();
           var c = {OPEN}; c.close();
           return Response.success(1);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
}

#[test]
fn a_third_open_stream_is_refused() {
    let _t = common::test();
    let host = FakeHost::streams(plain_stream(&[]));
    let code = format!(
        "function execute() {{
           var a = {OPEN}, b = {OPEN}, name;
           try {{ {OPEN}; }} catch (e) {{ name = e.name; }}
           return Response.success(name);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#""TooManyStreamsError""#);
}

#[test]
fn a_read_that_never_completes_ends_with_a_network_error_after_the_grace() {
    let _t = common::test();
    let host = FakeHost::streams(pending_read());
    let code = format!(
        "function execute() {{
           var r = {OPEN}, name;
           try {{ r.readLine(); }} catch (e) {{ name = e.name; }}
           return Response.success(name);
         }}"
    );
    let started = Instant::now();
    let r = run_streaming_idle(&code, host.clone(), RunOptions::default(), 1000, None);
    let took = started.elapsed();
    assert_ok(&r);
    assert_eq!(r.output_json, r#""NetworkError""#);
    // Waits `idle` plus the 1 s grace.
    assert!(took >= Duration::from_millis(1900), "{took:?}");
    assert!(took < Duration::from_secs(6), "{took:?}");
    assert_eq!(count_ops(&host, Op::Close), 1);
}

#[test]
fn an_open_that_never_answers_gives_up_closes_its_id_and_charges_the_sends() {
    let _t = common::test();
    let host = FakeHost::streams(Arc::new(|call| match call.op {
        Op::Open => Box::pin(std::future::pending()),
        _ => Box::pin(async { stream_chunk(b"", false) }),
    }));
    let code = "function execute() {
           var first, second;
           try { fetch('https://t.test/sse', {stream: true, timeout: 500}); }
           catch (e) { first = e.name; }
           try { fetch('https://t.test/plain'); } catch (e) { second = e.name; }
           return Response.success([first, second]);
         }";
    let started = Instant::now();
    let (r, _) = run(code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["NetworkError","TooManyRequestsError"]"#);
    // The deadline of 500 ms plus the 1 s grace.
    assert!(started.elapsed() >= Duration::from_millis(1400));
    let calls = host.stream_calls();
    let open = calls.iter().find(|c| c.op == Op::Open).unwrap();
    assert_eq!(open.request.as_ref().unwrap().deadline_ms, 500);
    let close = calls.iter().find(|c| c.op == Op::Close).unwrap();
    assert_eq!(close.stream, open.stream);
}

#[test]
fn cancel_while_a_read_waits_stops_the_run_within_300_ms() {
    let _t = common::test();
    let host = FakeHost::streams(pending_read());
    let job = rt::begin_job();
    let code = format!(
        "function execute() {{ var r = {OPEN}; r.readLine(); return Response.success(1); }}"
    );
    let request = request_with(job, vec![file("search.js", &code)], "{}", 0);
    let runner = thread::spawn(move || block_on(rt::run_streaming(request, 0, host, None)));
    // Long enough for the script to be parked in the read.
    thread::sleep(Duration::from_millis(500));
    let cancelled_at = Instant::now();
    rt::cancel_job(job);
    let r = runner.join().unwrap();
    assert_eq!(r.status, S::Cancelled);
    assert!(cancelled_at.elapsed() <= Duration::from_millis(300));
}

#[test]
fn text_held_in_rust_is_charged_to_the_byte_budget() {
    let _t = common::test();
    let big = vec![b'x'; 13 * MIB];
    // A 4 MiB body read by `text()` passes the 16 MiB budget on top of the
    // 13 MiB of an unread body.
    let host = FakeHost::streaming(
        move |_| ok_response(200, &big),
        scripted_stream(vec![vec![b'a'; 64 * KIB]; 64], |_, reply| reply),
    );
    let code = format!(
        "function execute() {{
           fetch('https://t.test/big');
           return Response.success({OPEN}.text().length);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_eq!(r.status, S::Memory, "{}", r.error_message);
    assert_eq!(count_ops(&host, Op::Close), 1);

    // The same body under the budget is returned whole.
    let host = FakeHost::streams(scripted_stream(
        vec![vec![b'a'; 64 * KIB]; 64],
        |_, reply| reply,
    ));
    let code = format!("function execute() {{ return Response.success({OPEN}.text().length); }}");
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, (4 * MIB).to_string());

    // One byte over 4 MiB is a RangeError.
    let host = FakeHost::streams(scripted_stream(
        vec![vec![b'a'; 64 * KIB]; 65],
        |_, reply| reply,
    ));
    let code = format!(
        "function execute() {{
           var name;
           try {{ {OPEN}.text(); }} catch (e) {{ name = e.name; }}
           return Response.success(name);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#""RangeError""#);
}

#[test]
fn consumed_text_is_released_so_a_long_stream_fits() {
    let _t = common::test();
    let held = vec![b'x'; 10 * MIB];
    // 15 MiB in lines of 1 KiB, 64 per chunk.
    let mut chunk = Vec::new();
    for _ in 0..64 {
        chunk.extend(std::iter::repeat_n(b'y', 1023));
        chunk.push(b'\n');
    }
    assert_eq!(chunk.len(), 64 * KIB);
    let host = FakeHost::streaming(
        move |_| ok_response(200, &held),
        scripted_stream(vec![chunk; 240], |_, reply| reply),
    );
    let code = format!(
        "function execute() {{
           fetch('https://t.test/held');
           var r = {OPEN}, n = 0;
           while (r.readLine() !== null) n++;
           return Response.success(n);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, (240 * 64).to_string());
}

#[test]
fn a_read_whose_future_panics_is_a_network_error_and_closes_the_stream() {
    let _t = common::test();
    let host = FakeHost::streams(Arc::new(|call| match call.op {
        Op::Read => Box::pin(async { panic!("read future panics") }),
        Op::Open => Box::pin(async { stream_opened() }),
        _ => Box::pin(async { stream_chunk(b"", false) }),
    }));
    let code = format!(
        "function execute() {{
           var r = {OPEN}, name;
           try {{ r.readLine(); }} catch (e) {{ name = e.name; }}
           return Response.success([name, r.readLine()]);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, r#"["NetworkError",null]"#);
    assert_eq!(count_ops(&host, Op::Read), 1);
    assert_eq!(count_ops(&host, Op::Close), 1);
}

#[test]
fn close_gives_back_the_text_still_buffered() {
    let _t = common::test();
    // Leaves 100 KiB of the 16 MiB budget free. Each stream keeps about
    // 60 KiB buffered after its first line; four of them would pass the
    // budget if `close()` did not release that text.
    let held = vec![b'x'; 16 * MIB - 100 * KIB];
    let mut chunk = b"first\n".to_vec();
    chunk.extend(std::iter::repeat_n(b'z', 60 * KIB));
    let host = FakeHost::streaming(
        move |_| ok_response(200, &held),
        stream_answer_with(move |call| match call.op {
            Op::Open => stream_opened(),
            Op::Read => stream_chunk(&chunk, false),
            _ => stream_chunk(b"", false),
        }),
    );
    let code = format!(
        "function execute() {{
           fetch('https://t.test/held');
           var n = 0;
           for (var i = 0; i < 4; i++) {{
             var r = {OPEN};
             if (r.readLine() === 'first') n++;
             r.close();
           }}
           return Response.success(n);
         }}"
    );
    let (r, _) = run(&code, &host);
    assert_ok(&r);
    assert_eq!(r.output_json, "4");
}
