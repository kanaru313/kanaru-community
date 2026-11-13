//! Streaming runs: the `emit` host function and its caps, the dedicated
//! worker, the wall cap, `reset`, and the bounded single waits of `fetch`. No
//! test touches the network: a scripted `FakeHost` plays the app and a
//! collecting closure the receiving side.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{mpsc, Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

use common::{
    block_on, collecting_emitter, file, ok_response, request_with, rt, run_streaming,
    run_streaming_idle, run_with_host, runtime, stream_answer_with, FakeHost, RunOptions,
};
use kanaru_plugin_runtime::{
    Emitter, FetchFailureKind as Kind, FetchRequest, PluginHost, PluginRuntime, RuntimeConfig,
    ScriptResult, ScriptStatus as S, StreamOp, StreamOptions,
};

fn stream(code: &str) -> (ScriptResult, Vec<String>) {
    let (emitter, events) = collecting_emitter();
    let r = run_streaming(
        code,
        Arc::new(kanaru_plugin_runtime::NoNetwork),
        RunOptions::default(),
        Some(emitter),
    );
    let seen = events.lock().unwrap().clone();
    (r, seen)
}

fn quick(code: &str, emitter: Option<Emitter>) -> ScriptResult {
    run_streaming(
        code,
        Arc::new(kanaru_plugin_runtime::NoNetwork),
        RunOptions::default(),
        emitter,
    )
}

#[test]
fn a_normal_run_has_no_emit_and_ignores_the_stream_option() {
    let _t = common::test();
    let run = |options: &str| {
        let seen: Arc<Mutex<Vec<FetchRequest>>> = Arc::default();
        let log = seen.clone();
        let host = FakeHost::answering(move |request| {
            log.lock().unwrap().push(request.clone());
            ok_response(200, b"whole body")
        });
        let code = format!(
            "function execute() {{
               var body = fetch('https://t.test/'{options}).text();
               return Response.success({{e: typeof emit, body: body}});
             }}"
        );
        let r = run_with_host(&code, host, RunOptions::default());
        let requests = seen.lock().unwrap().clone();
        (r, requests)
    };
    let (r, requests) = run(", {stream: true}");
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#"{"e":"undefined","body":"whole body"}"#);
    assert_eq!(requests.len(), 1);
    assert_eq!(requests[0].url, "https://t.test/");
    assert_eq!(requests[0].method, "GET");
    assert_eq!(requests[0].max_sends, 10);
    let (_, plain) = run("");
    assert_eq!(plain.len(), 1);
    // The deadline is what is left of the wall time, so two runs differ by the
    // few milliseconds that passed; a 300 s cap would differ by minutes.
    let (a, b) = (requests[0].deadline_ms, plain[0].deadline_ms);
    assert!(a.abs_diff(b) <= 1000, "{a} vs {b}");
}

#[test]
fn events_arrive_in_order() {
    let _t = common::test();
    let (r, events) = stream(
        "function execute() { emit({a:1}); emit('x'); emit([1,2]); return Response.success(1); }",
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(events, vec![r#"{"a":1}"#, r#""x""#, "[1,2]"]);
}

#[test]
fn values_that_cannot_be_emitted_throw_and_the_script_can_catch() {
    let _t = common::test();
    let (r, events) = stream(
        "function execute() {
           var out = [];
           function t(f) { try { f(); out.push('no'); } catch (e) { out.push(e.name); } }
           t(function () { emit(undefined); });
           t(function () { emit(function () {}); });
           t(function () { var o = {}; o.o = o; emit(o); });
           t(function () { emit({toJSON: function () { throw new Error('x'); }}); });
           t(function () { emit('\\ud800'); });
           t(function () { var o = {}; o['\\udc00'] = 1; emit(o); });
           t(function () { emit(new String('\\ud800')); });
           t(function () { var o = new String('ok'); o.toString = function () { return '\\ud800'; }; emit(o); });
           t(function () { emit({a: new String('\\udc00')}); });
           t(function () { emit({toJSON: function () { throw new TypeError('well-formed x'); }}); });
           t(function () { emit(new Array(64 * 1024 + 1).join('a')); });
           t(function () {
             try { emit({toJSON: function () { throw new TypeError('well-formed x'); }}); }
             catch (e) { out.push(e.message); throw e; }
           });
           return Response.success(out);
         }",
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(
        r.output_json,
        r#"["TypeError","TypeError","TypeError","TypeError","TypeError","TypeError","TypeError","TypeError","TypeError","TypeError","RangeError","emit: the value must be JSON-serialisable","TypeError"]"#
    );
    assert!(events.is_empty());
}

#[test]
fn a_string_object_is_emitted_as_the_text_that_was_checked() {
    let _t = common::test();
    let (r, events) = stream(
        "function execute() {
           var o = new String('ignored');
           o.toString = function () { return 'fine'; };
           emit(o);
           return Response.success(1);
         }",
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(events, vec![r#""fine""#]);
}

/// Known open case, kept as it was (the replacer is not re-entrancy safe): the replacer reads an own `toString`
/// of a `String` object, so a re-entrant `toString` that calls `emit` runs
/// inside the outer `emit`. The run must still end cleanly (no crash, no
/// hang); the events that do get through are the ones the script emitted.
#[test]
fn a_reentrant_to_string_in_emit_does_not_break_the_run() {
    let _t = common::test();
    let (r, events) = stream(
        "function execute() {
           var o = new String('x');
           var depth = 0;
           o.toString = function () { if (depth++ < 1) emit('inner'); return 'outer'; };
           emit(o);
           return Response.success(1);
         }",
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert!(events.contains(&r#""outer""#.to_owned()), "{events:?}");
}

#[test]
fn the_run_total_is_capped() {
    let _t = common::test();
    // 64 KiB events: the JSON text is 2 quotes + 65534 characters.
    let (r, events) = stream(
        "function execute() {
           var s = new Array(64 * 1024 - 1).join('a');
           var n = 0, name = 'none';
           try { for (;;) { emit(s); n++; } } catch (e) { name = e.name; }
           return Response.success({n: n, name: name});
         }",
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#"{"n":128,"name":"RangeError"}"#);
    assert_eq!(events.len(), 128);
}

#[test]
fn emits_over_the_burst_are_rate_limited() {
    let _t = common::test();
    let started = Instant::now();
    let (r, events) = stream(
        "function execute() { for (var i = 0; i < 150; i++) emit(i); return Response.success(1); }",
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(events.len(), 150);
    assert!(started.elapsed() >= Duration::from_millis(900));
}

#[test]
fn cancel_while_emit_waits_for_a_token() {
    let _t = common::test();
    let (emitter, _events) = collecting_emitter();
    let job = rt::begin_job();
    let request = request_with(
        job,
        vec![file(
            "search.js",
            "function execute() { for (;;) emit(1); }",
        )],
        "{}",
        0,
    );
    let host: Arc<dyn PluginHost> = Arc::new(kanaru_plugin_runtime::NoNetwork);
    let runner =
        thread::spawn(move || block_on(rt::run_streaming(request, 0, host, Some(emitter))));
    // Past the burst, so the script is parked waiting for tokens.
    thread::sleep(Duration::from_millis(300));
    let cancelled_at = Instant::now();
    rt::cancel_job(job);
    let r = runner.join().unwrap();
    assert_eq!(r.status, S::Cancelled);
    assert!(cancelled_at.elapsed() <= Duration::from_millis(300));
}

#[test]
fn an_emitter_that_says_false_is_not_an_error() {
    let _t = common::test();
    let calls = Arc::new(AtomicU32::new(0));
    let counted = calls.clone();
    let emitter: Emitter = Arc::new(move |_| {
        counted.fetch_add(1, Ordering::SeqCst);
        false
    });
    let r = quick(
        "function execute() { emit(1); emit(2); return Response.success(1); }",
        Some(emitter),
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    // A false answer drops that event only; the next one is still offered.
    assert_eq!(calls.load(Ordering::SeqCst), 2);
}

#[test]
fn no_emitter_counts_and_drops() {
    let _t = common::test();
    let r = quick(
        "function execute() { emit(1); return Response.success(1); }",
        None,
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
}

#[test]
fn a_panicking_emitter_ends_the_run_internal() {
    let _t = common::test();
    let emitter: Emitter = Arc::new(|_| panic!("sink exploded"));
    let r = quick(
        "function execute() { try { emit(1); } catch (e) {} return Response.success(1); }",
        Some(emitter),
    );
    assert_eq!(r.status, S::Internal);
    assert!(!r.error_message.contains("sink exploded"));
}

#[test]
fn the_emitter_is_dropped_before_the_result_arrives() {
    let _t = common::test();
    let marker = Arc::new(());
    let held = marker.clone();
    let emitter: Emitter = Arc::new(move |_| {
        let _ = &held;
        true
    });
    let r = quick(
        "function execute() { emit(1); return Response.success(1); }",
        Some(emitter),
    );
    assert_eq!(r.status, S::Ok);
    assert_eq!(Arc::strong_count(&marker), 1);
}

/// Starts a streaming run in a thread whose first `fetch` signals `started`
/// and then never gets an answer; the job id is returned.
fn start_blocked_run() -> (u32, mpsc::Receiver<()>, thread::JoinHandle<ScriptResult>) {
    let (tx, rx) = mpsc::channel();
    let tx = Mutex::new(tx);
    let host = FakeHost::with_futures(move |_| {
        let _ = tx.lock().unwrap().send(());
        Box::pin(std::future::pending())
    });
    let job = rt::begin_job();
    let request = request_with(
        job,
        vec![file(
            "search.js",
            "function execute() { fetch('https://t.test/'); return Response.success(1); }",
        )],
        "{}",
        0,
    );
    let handle = thread::spawn(move || block_on(rt::run_streaming(request, 0, host, None)));
    (job, rx, handle)
}

#[test]
fn a_second_streaming_run_is_busy_and_lyrics_runs_are_not() {
    let _t = common::test();
    let (first, started, handle) = start_blocked_run();
    started.recv_timeout(Duration::from_secs(10)).unwrap();

    let marker = Arc::new(());
    let held = marker.clone();
    let emitter: Emitter = Arc::new(move |_| {
        let _ = &held;
        true
    });
    let second = quick(
        "function execute() { return Response.success(2); }",
        Some(emitter),
    );
    assert_eq!(second.status, S::Busy);
    assert_eq!(Arc::strong_count(&marker), 1, "the emitter was released");

    let lyrics = common::run_script("function execute() { return Response.success(3); }", 0);
    assert_eq!(lyrics.status, S::Ok);

    rt::cancel_job(first);
    assert_eq!(handle.join().unwrap().status, S::Cancelled);

    let third = quick("function execute() { return Response.success(4); }", None);
    assert_eq!(third.status, S::Ok, "{}", third.error_message);
}

#[test]
fn a_busy_streaming_run_spends_its_job_id_and_event_sink() {
    let _t = common::test();
    let (first, started, handle) = start_blocked_run();
    started.recv_timeout(Duration::from_secs(10)).unwrap();

    let marker = Arc::new(());
    let held = marker.clone();
    let sink: Emitter = Arc::new(move |_| {
        let _ = &held;
        true
    });
    let job = rt::begin_job();
    assert!(runtime().attach_job_events(job, sink));
    let request = request_with(
        job,
        vec![file(
            "search.js",
            "function execute() { return Response.success(1); }",
        )],
        "{}",
        0,
    );
    let options = StreamOptions {
        idle_timeout_ms: 0,
        events: true,
    };
    let host: Arc<dyn PluginHost> = Arc::new(kanaru_plugin_runtime::NoNetwork);
    let r = block_on(runtime().run_streaming(request, options, host, None));
    assert_eq!(r.status, S::Busy);
    assert_eq!(Arc::strong_count(&marker), 1, "the sink was released");

    rt::cancel_job(first);
    assert_eq!(handle.join().unwrap().status, S::Cancelled);
}

#[test]
fn events_go_to_the_sink_attached_to_the_job() {
    let _t = common::test();
    let (sink, events) = collecting_emitter();
    let job = rt::begin_job();
    assert!(runtime().attach_job_events(job, sink));
    let request = request_with(
        job,
        vec![file(
            "search.js",
            "function execute() { emit('a'); emit('b'); return Response.success(1); }",
        )],
        "{}",
        0,
    );
    let options = StreamOptions {
        idle_timeout_ms: 0,
        events: true,
    };
    let host: Arc<dyn PluginHost> = Arc::new(kanaru_plugin_runtime::NoNetwork);
    // The emitter argument is ignored when `events` is set.
    let (other, other_events) = collecting_emitter();
    let r = block_on(runtime().run_streaming(request, options, host, Some(other)));
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(*events.lock().unwrap(), vec![r#""a""#, r#""b""#]);
    assert!(other_events.lock().unwrap().is_empty());
}

#[test]
fn events_without_an_attached_sink_end_the_run_internal() {
    let _t = common::test();
    let job = rt::begin_job();
    let request = request_with(
        job,
        vec![file(
            "search.js",
            "function execute() { emit('a'); return Response.success(1); }",
        )],
        "{}",
        0,
    );
    let options = StreamOptions {
        idle_timeout_ms: 0,
        events: true,
    };
    let host: Arc<dyn PluginHost> = Arc::new(kanaru_plugin_runtime::NoNetwork);
    let r = block_on(runtime().run_streaming(request, options, host, None));
    assert_eq!(r.status, S::Internal);
    assert!(
        r.error_message.contains("not attached"),
        "{}",
        r.error_message
    );
}

#[test]
fn a_sink_attached_to_a_job_that_is_not_waiting_is_refused() {
    let _t = common::test();
    let (sink, _events) = collecting_emitter();
    assert!(!runtime().attach_job_events(987_654, sink), "unknown id");
}

#[test]
fn a_single_wait_gives_up_after_its_deadline_plus_grace_and_is_charged() {
    let _t = common::test();
    let started = Instant::now();
    let r = run_streaming(
        "function execute() {
           var first, second;
           try { fetch('https://t.test/', {timeout: 200}); } catch (e) { first = e.name; }
           try { fetch('https://t.test/'); } catch (e) { second = e.name; }
           return Response.success([first, second]);
         }",
        FakeHost::never_answering(),
        RunOptions::default(),
        None,
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#"["NetworkError","TooManyRequestsError"]"#);
    assert_eq!(r.fetch_failure.unwrap().kind, Kind::Network);
    assert!(started.elapsed() >= Duration::from_millis(1100));
}

#[test]
fn a_streaming_fetch_deadline_is_at_most_ninety_seconds() {
    let _t = common::test();
    let seen = Arc::new(AtomicU32::new(0));
    let log = seen.clone();
    let host = FakeHost::answering(move |request| {
        log.store(request.deadline_ms, Ordering::SeqCst);
        ok_response(200, b"x")
    });
    let r = run_streaming(
        "function execute() { fetch('https://t.test/'); return Response.success(1); }",
        host,
        RunOptions::default(),
        None,
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    let ms = seen.load(Ordering::SeqCst);
    assert!((89_000..=90_000).contains(&ms), "{ms}");
}

#[test]
fn the_idle_time_of_reads_is_clamped_and_defaults_to_a_minute() {
    let _t = common::test();
    let code = "function execute() {
           var r = fetch('https://t.test/sse', {stream: true});
           return Response.success(r.read());
         }";
    let waits = |idle_ms: u32| {
        let host = FakeHost::streams(stream_answer_with(|call| match call.op {
            StreamOp::Open => common::stream_opened(),
            _ => common::stream_chunk(b"x", false),
        }));
        let r = run_streaming_idle(code, host.clone(), RunOptions::default(), idle_ms, None);
        assert_eq!(r.status, S::Ok, "{}", r.error_message);
        host.stream_calls()
            .iter()
            .find(|c| c.op == StreamOp::Read)
            .map(|c| c.wait_ms)
            .unwrap()
    };
    assert_eq!(waits(0), 60_000);
    assert_eq!(waits(5), 1_000);
    assert_eq!(waits(20_000), 20_000);
    assert_eq!(waits(u32::MAX), 90_000);
}

#[test]
fn a_stream_read_that_stays_silent_ends_the_run_at_the_idle_time_not_the_wall() {
    let _t = common::test();
    // The host answers a read with `Network` (its idle signal) after the wait.
    let host = FakeHost::streams(stream_answer_with(|call| match call.op {
        StreamOp::Open => common::stream_opened(),
        StreamOp::Read => common::stream_failed(kanaru_plugin_runtime::FetchOutcome::Network),
        _ => common::stream_chunk(b"", false),
    }));
    let started = Instant::now();
    let r = run_streaming_idle(
        "function execute() {
           var r = fetch('https://t.test/sse', {stream: true}), name;
           try { r.readLine(); } catch (e) { name = e.name; }
           return Response.success(name);
         }",
        host,
        RunOptions::default(),
        1000,
        None,
    );
    assert_eq!(r.status, S::Ok, "{}", r.error_message);
    assert_eq!(r.output_json, r#""NetworkError""#);
    assert!(started.elapsed() < Duration::from_secs(5));
}

/// A runtime whose streaming cap is `cap`, so the 300 s rule is reachable.
fn capped_runtime(cap: Duration) -> PluginRuntime {
    PluginRuntime::new(RuntimeConfig {
        stream_wall_cap: cap,
        ..RuntimeConfig::default()
    })
}

fn spin_streaming(rt: &PluginRuntime, timeout_ms: u32) -> (ScriptResult, Duration) {
    let request = request_with(
        rt.begin_job(),
        vec![file("search.js", "function execute() { for (;;) {} }")],
        "{}",
        timeout_ms,
    );
    let options = StreamOptions {
        idle_timeout_ms: 0,
        events: false,
    };
    let host: Arc<dyn PluginHost> = Arc::new(kanaru_plugin_runtime::NoNetwork);
    let started = Instant::now();
    let r = block_on(rt.run_streaming(request, options, host, None));
    (r, started.elapsed())
}

#[test]
fn the_wall_of_a_streaming_run_is_capped_whatever_the_request_asks() {
    let _t = common::test();
    let rt = capped_runtime(Duration::from_millis(600));
    // 0 means the cap; a larger request is cut to it.
    for asked in [0, 400_000, u32::MAX] {
        let (r, took) = spin_streaming(&rt, asked);
        assert_eq!(r.status, S::Timeout, "asked {asked}: {}", r.error_message);
        assert!(
            took >= Duration::from_millis(500),
            "asked {asked}: {took:?}"
        );
        assert!(took < Duration::from_secs(5), "asked {asked}: {took:?}");
    }
    // A request below the cap is honoured.
    let (r, took) = spin_streaming(&rt, 200);
    assert_eq!(r.status, S::Timeout);
    assert!(took < Duration::from_millis(550), "{took:?}");
}

#[test]
fn reset_cancels_a_running_streaming_job() {
    let _t = common::test();
    let (_job, started, handle) = start_blocked_run();
    started.recv_timeout(Duration::from_secs(10)).unwrap();
    let reset_at = Instant::now();
    runtime().reset();
    let r = handle.join().unwrap();
    assert_eq!(r.status, S::Cancelled);
    assert!(reset_at.elapsed() < Duration::from_secs(2));
    // The worker is free again.
    let next = quick("function execute() { return Response.success(1); }", None);
    assert_eq!(next.status, S::Ok, "{}", next.error_message);
}

#[test]
fn dropping_a_streaming_run_cancels_it() {
    let _t = common::test();
    let (tx, rx) = mpsc::channel();
    let tx = Mutex::new(tx);
    let host = FakeHost::with_futures(move |_| {
        let _ = tx.lock().unwrap().send(());
        Box::pin(std::future::pending())
    });
    let request = request_with(
        rt::begin_job(),
        vec![file(
            "search.js",
            "function execute() { fetch('https://t.test/'); return Response.success(1); }",
        )],
        "{}",
        0,
    );
    let options = StreamOptions {
        idle_timeout_ms: 0,
        events: false,
    };
    let mut future = runtime().run_streaming(request, options, host, None);
    let waker = std::task::Waker::noop();
    let mut cx = std::task::Context::from_waker(waker);
    assert!(future.as_mut().poll(&mut cx).is_pending());
    rx.recv_timeout(Duration::from_secs(10)).unwrap();
    drop(future);
    // The worker stops at its next cancel poll and takes the next run.
    let end = Instant::now() + Duration::from_secs(5);
    loop {
        let next = quick("function execute() { return Response.success(1); }", None);
        if next.status == S::Ok {
            break;
        }
        assert!(
            Instant::now() < end,
            "worker never freed: {:?}",
            next.status
        );
        thread::sleep(Duration::from_millis(50));
    }
}
