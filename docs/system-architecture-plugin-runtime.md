# System architecture: plugin runtime

Code: `rust/crates/kanaru_plugin_runtime/` (plain Rust, no FFI, no dependency on
`kanaru_media`) and, on the app side, `rust/crates/kanaru_bridge/src/`
(`runtime_holder.rs`, `host_dart.rs`, `plugin_dto.rs`, `api/plugin_runtime.rs`,
`api/plugin_stream.rs`). What scripts see: [plugin-host-api.md](./plugin-host-api.md).

## The instance

`PluginRuntime::new(RuntimeConfig)` owns everything: the JS worker pool, the
streaming worker pool, the job registry and the late-answers drain. The crate has
no process globals; the only global is the opt-in panic hook of
`install_quiet_panic_hook`; the bridge's `init_app` installs it above its own
guarded-panic hook (one log line per panic caught by `guarded`). The bridge keeps the one instance of the app in a
`OnceLock` (`runtime_holder.rs`), sized from `pools::config::PLUGIN_*`; tests make
their own.

Both pools start eagerly in `new` (a lazy stream pool would race with
`shutdown`: a thread started after the join pass is never joined). The price is
one idle thread with an 8 MiB stack (virtual memory, committed only when used).

- `reset()` cancels every job (running, queued, begun but not started). Workers
  stop within one cancel poll. Used by tests between cases and by the bridge's
  `reset_plugin_runtime` (which does nothing before the runtime exists).
- `shutdown()` and `Drop` stop the pools and join the threads, each join bounded
  (2 s). A thread stuck in a native call that cannot be interrupted (a huge
  `JSON.parse`) is left to end on its own.

Each job creates a fresh QuickJS `Runtime` and `Context` on its worker, runs, and
drops both on that worker. A panic in a job becomes status `Internal`; the worker
survives.

## Threads

| Thread | Count | Started by | Notes |
|---|---|---|---|
| `kanaru-background-N` (bridge pool) | cores - 1 on desktop, cores / 2 (1 to 4) on Android | bridge, first use | scans (tags, covers); low priority; 8 MiB stack |
| `kanaru-interactive-N` (bridge pool) | 2 | bridge, first use | work the user waits for |
| `kanaru-waveform-N` (bridge pool) | 1 | bridge, first use | one waveform job decodes a whole track |
| `plugin-js-N` | 4 (`WORKER_THREADS`) | `PluginRuntime::new` | JS workers, 8 MiB stack; queue of 16 jobs |
| `plugin-js-stream-N` | 1 (`STREAM_WORKER_THREADS`) | `PluginRuntime::new` | streaming runs, no queue |
| `plugin-js-check` | one per `check_script` call | the call | not a pool job: must not wait for or take a worker; 8 MiB stack because the parser recurses; the call blocks until it ends |
| lyrics read thread | one per `read_embedded_lyrics` call | the bridge | a kernel-blocked read cannot be cancelled; the caller times out (10 s) and the stuck thread is left behind; at most 2 stuck at once (checked at start) |
| `plugin-late-answers` | 1 | first late answer (not `new`) | the late-answers drain (below) |

The plugin threads (workers, stream worker, check, drain) are started by the
runtime itself, not by a bridge pool. The bridge passes a `ThreadStartHook` in
`RuntimeConfig`; the runtime calls it first thing on each thread it starts, with
the thread's name. Today the bridge's hook does nothing: plugin threads run work
the user waits for, so they keep normal priority (the hook is where a lower
priority would go). A panicking hook is ignored. The bridge builds the runtime
on first use, so no plugin thread exists until a plugin is run or checked; its
threads live until the process ends. Stack sizes: `limits.rs`
(`THREAD_STACK_BYTES` 8 MiB, a smaller configured value is raised to it, because
QuickJS is told scripts may use 1 MiB of stack).

## `PluginHost`

The runtime does no I/O itself. `PluginHost` is implemented by the bridge
(`DartHost`, over the Dart fetch and stream callbacks) and by test fakes;
`NoNetwork` fails every call with `Network`.

```rust
trait PluginHost: Send + Sync {
    fn fetch(&self, request: FetchRequest) -> Pending<FetchResponse>;
    fn stream(&self, call: StreamCall) -> Pending<StreamReply>;
}
```

`Pending<T>` is a boxed future. The method must return quickly with a future; the
JS worker polls it. Every request carries the run's `install_id`.

Stream-close rule (the host's side): keep one stream table per run; close every
stream still open when the run ends or is cancelled. During a run Rust sends
`Close` when the script calls `close()`, after a stream failed, and for an `Open`
answered too late; it sends none for streams still open at the end or on cancel
(a cancel can stop a `Close` before it is sent). Close at once an `Open` answered
after the run ended, and expect a `Close` while that stream's `Open` is pending.

## Park and waker

The JS worker blocks while the host works. It calls the host, then polls the
returned future itself with a `Waker` that unparks the thread, and parks between
polls with `park_timeout(min(CANCEL_POLL, time left))`. It wakes when the future
completes (the app's reply wakes it from another thread), after 50 ms
(`CANCEL_POLL`) to look at the cancel flag, or at the deadline. No async runtime
and no blocked bridge worker are involved. A host call that panics is caught
(`quietly`) and answered as `Network`.

## Cancel and deadline

Every job has a cancel flag and a deadline (15 s by default, at most 90 s, 300 s
for a streaming run). QuickJS' interrupt handler looks at both, so a cancel or
timeout stops a script that loops forever, and `try/catch` in the script cannot
swallow it. A blocked host call or `sleep` looks at both every 50 ms. A job still
in the queue when cancelled ends `Cancelled` at once and gives its slot back. The
wall clock starts when a worker takes the job, so the caller keeps its own outer
deadline for the queue wait.

Dart cannot abort an HTTP request in flight: when the Rust side stops waiting
(cancel, deadline), the Dart future is still running. The app side finishes it
and the answer is discarded (next section); it is the host's job to give up its
own connection (timeouts, closing streams).

## Late-answers drain

A future the script stopped waiting for (cancel, deadline) may be driven by the
app's side. The drain thread (`plugin-late-answers`) takes those futures and
polls them until they finish, so the host can release what it holds; the answers
are discarded. A polled future is never dropped on a JS thread (its destructor
could run on the wrong thread): the drain forgets a future it gives up on. Caps:
256 futures at once (`MAX_LATE`), 120 s per future (`MAX_LATE_AGE`, above the
longest deadline plus grace); shutdown and a panic also end the wait. One thread
per runtime.

## Threat: C `assert()` in QuickJS

QuickJS is C code. A failing `assert()` in it calls `abort()`, which ends the
whole app, not just the job; Rust's `catch_unwind` cannot stop it. The engine's
asserts are kept on deliberately: they turn an engine bug into a clean crash
instead of undefined behaviour inside a process that holds the user's library.
The limits (heap, stack, output, timeouts) and the pinned engine version are the
mitigation. A hostile plugin that finds such a bug can crash the app. Plugins are
installed by the user from a repository or a zip.

## Bindgen on Android

`rquickjs-sys` ships pre-made bindings only for some hosts, none for Android, so
building for Android runs `bindgen` (the runtime crate enables the `bindgen`
feature of `rquickjs` in an Android-only dependency block). Under the Nix dev
shell the clang that `bindgen` finds is a wrapper that injects host glibc include
dirs, which fails for the Android target (`gnu/stubs-32.h`). The vendored cargokit
therefore carries a local patch that points `bindgen` at the NDK clang and the NDK
sysroot; see [code-standards.md](./code-standards.md) ("Vendored cargokit local
patch"). `tool/check_rust` fails if the patch is lost.

## Html

`src/host/html/`: `mod.rs` (arena of parsed documents, handles, the six natives
`htmlParse`, `htmlSelect`, `htmlText`, `htmlHtml`, `htmlAttr`, `htmlTag`, each
run under a `catch_unwind` that marks the run `Internal`), `sink.rs` (the bounded
html5ever tree sink and chunked parse), `select.rs` (own selector matcher with a
step gate), `text.rs` (`text()` rules), `serialize.rs` (capped `html()`).
Documents live in Rust (`scraper`); scripts only hold numbers checked on every
call. Limits are in `limits.rs` (input 4 MiB, 8 documents, 200 000 nodes, depth
512, 160 bytes per node against the 16 MiB budget, selector 1024 bytes) and in
the modules (parse chunk 1 KiB, early depth margin 64, matcher check every
65 536 steps, serialized output 4 MiB).

Two failures shaped it: a deep `:has` overflowed the thread stack (abort), and a
deep `<div>` parse was quadratic. So depth is capped at parse (with an early
stop), and the matcher is ours: scraper's `select` cannot be interrupted, and
QuickJS' interrupt does not run inside Rust. The sink reaches html5ever
internals (`parser.tokenizer.sink.sink`), so `html5ever`, `scraper`, `ego-tree`,
`selectors` and `cssparser` are pinned exactly in the workspace. `unsafe` is not
used.

## Removed globals

Why: a static review of a plugin package is only worth something if the package
is all the code that ever runs. `eval` or `Function` would let a plugin fetch
JS and run it.

What: `globals/no_eval.rs` runs last in `globals::install` (test builds install their hooks after it),
before the entry script. It replaces `.constructor` on the four function prototypes (plain,
async, generator, async generator; the last three found with
`Object.getPrototypeOf` of a literal) with a non-configurable getter that
throws `TypeError`, then deletes the globals `eval` and `Function` and fails
the setup (`Internal`) if either is still there. The prototype objects stay, so
the prelude's captured `Function.prototype.call` keeps working. `load()` and the
entry compile through Rust (`eval_classic`), so they are not affected. Normal
and streaming runs share `engine::run_in_context`, so both get it.

Trade-off: the globals are deleted, not replaced by stubs, so code that
probes `Function` fails loudly instead of silently misbehaving; libraries that
need `Function` or `fn.constructor` do not run (see the compatibility note in
`plugin-host-api.md`).

Tests: `tests/no_eval.rs` (every route blocked, constructor not restorable,
`load` / crypto / host API still work).

## App side

The only Dart caller is `PluginRunner` (`lib/src/plugins/data/run/`, see [system-architecture-plugins.md](./system-architecture-plugins.md#runs)); it talks to the bridge through `RustPluginEngine`, the one file that imports `lib/src/rust/api/plugin_runtime.dart` (the syntax check in `data/native/rust_script_checker.dart` is the other bridge user).

- **No second init.** The app initialises `flutter_rust_bridge` once at startup (`platform/data/native_library.dart`). The engine never calls `RustLib.init`; tests use a fake engine and never load the library.
- **Reset once.** The runner calls `engine.reset()` before its first job and `RustPluginEngine.reset()` calls `resetPluginRuntime()` once per process (a static flag; a hot restart resets Dart statics, so it runs again then, which is what the runtime needs: workers held by the dead isolate are cancelled). It must only be called from the main isolate.
- **Admission.** The runner lets at most 4 jobs (the worker count) into the runtime at once, first come first served, so the Rust queue stays empty and `Busy` does not happen. The run wall (`timeout_ms`) therefore starts when the job is dispatched; the runner keeps an outer deadline of the wall plus 30 s and cancels the job when it passes.
- **Cancel.** The runner calls `cancelPluginJob` for a caller's cancel, a plugin switch (run gate) and the outer deadline. A job that ends `Cancelled` is mapped by who stopped it.
- **Fetch.** Each run passes its own fetch closure (the callback is per call; a request carries `install_id` but no job id), so the handler judges a request against the snapshot of its own run. The Dart handler (`HttpPluginFetchHandler`, see [system-architecture-plugins.md](./system-architecture-plugins.md) Runs) is the only network path: allowlist, public-only address check, header drops, no redirects, 4 MiB cap, 100 ms spacing per plugin.

### Streaming runs (Dart side)

A request with `stream` set (`PluginRunRequest.stream`: idle time and an `onEvent` callback) goes through the same `PluginRunner.run` path as any run (gate, pause, setup, required settings, run log, pause from the outcome); only these parts differ:

- **Engine call.** `engine.runStreaming` instead of `run`. `RustPluginEngine` attaches a `StreamEventGate` to the job's event stream before the run starts, delivers the events in order, and after the script result waits for the event stream to end for at most 2 s (`settle`), then closes the gate. A throw from `onEvent` is logged by type only and does not end the run.
- **Stream host.** `StreamFetchHandler` answers the runtime's `open` / `read` / `close` calls. An open is judged and recorded exactly like a one-shot fetch (`judgeFetch`, `recordFetch`: consent, allowlist, public address, spacing, headers) and the body is read through `PluginHttpStreamClient`. Each dispatch owns one `StreamTable` (at most 2 streams, as in the runtime), built by a factory from the job's cancel token. The table seals when the job is cancelled and is disposed when the run ends, which closes every stream still open.
- **Event door.** `StreamDispatch` wraps the caller's `onEvent`: after the run returned its outcome (deadline, settle timeout, error or normal end) events that still arrive are dropped.
- **Admission.** A second `RunAdmission(slots: 1)` (`streamRunAdmissionProvider`, a provider that watches nothing, so rebuilding `pluginRunnerProvider` does not forget a stream that is running). A run waits at most 10 s for it: the wait ends as granted, aborted (caller cancel or plugin switch: the run is started over or cancelled as for any run) or timed out. A timed-out wait is `RunBusy` and never starts the run over. A slot granted in the same tick as the timer is released and the answer is `RunBusy`. Normal runs use the 4-slot admission and are never blocked by a stream.
- **Wall.** `min(300 s, timeout + 9 x spacing)` for a stream run (90 s for a normal one), outer deadline wall + 30 s (`RunFailed(timeout)`). The slot is kept until the engine releases the job; if it has not by wall + 30 s + 2 s the runner logs it, releases the slot and the caller has already seen `RunFailed(timeout)`. A later `Busy` from the runtime is `RunBusy`.
- **Storage.** `persistStorage: false` (chat runs): the run starts with empty storage (the stored value is not read) and what the script returns is never written back.
- **Outcome.** `RunOk` and `RunScriptError` carry `pluginVersion`, the version of the package that really ran (a silent restart after a plugin switch re-reads the row).
- **Logs.** `RunLogRecorder` writes a failed stream run with its status, error kind and only the leading `ai:<code>` of the message: no input, message tail, console lines or stack. Masks (settings, storage, request headers) still apply to what is written. Clearing the log uses the existing `PluginLogOps.clear`.

## Tests

`crates/kanaru_plugin_runtime/tests/` share one runtime per test binary behind a
lock (`common/mod.rs`) and a `FakeHost` that records every request and checks the
`install_id`. `compat_repo.rs` runs a real plugin repository against such a host,
locally only (see [plugin-host-api.md](./plugin-host-api.md#compatibility-check)).
`tool/check_rust` runs the `kanaru_plugin_runtime` tests on one test thread
(`-- --test-threads=1`) so the wall-clock bounds of `tests/limits.rs` do not compete
for the CPU; each bound is its stop path's guarantee plus one scheduling
allowance (`SCHED`).

`html.rs`, `html_memory.rs` and `html_fuzz.rs` prove the Html limits and are
run in release mode by `tool/check_rust` (the profile the app ships, debug
assertions off), as are the two wall-clock tests of `html/sink_tests.rs`. `html_fuzz.rs` is a bounded `proptest` (fixed seed, 64
cases per generator, no persisted failures) that must give a result or a limit /
syntax error, never `Internal`; it is ignored in debug builds.
