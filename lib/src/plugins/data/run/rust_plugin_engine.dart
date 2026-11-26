import 'dart:async';

import 'package:logging/logging.dart';

import '../../../rust/api/plugin_runtime.dart' as rust;
import '../../../rust/api/plugin_stream.dart' as rust;
import '../../domain/run/plugin_engine.dart';
import '../../domain/run/run_outcome.dart';
import 'stream_event_gate.dart';

final _log = Logger('plugin_run');

// Dart statics are reset by a hot restart, which is when the runtime needs
// its one reset (workers held by the dead isolate).
bool _runtimeReset = false;

/// The Rust plugin runtime behind [PluginEngine]. The only file that talks to
/// the plugin-runtime bridge besides the syntax check; it never initialises
/// the bridge library (the app does that once at startup).
class RustPluginEngine implements PluginEngine {
  const RustPluginEngine();

  @override
  void reset() {
    if (_runtimeReset) return;
    _runtimeReset = true;
    try {
      rust.resetPluginRuntime();
    } on Object catch (error) {
      _log.warning('The plugin runtime reset failed: ${error.runtimeType}');
    }
  }

  @override
  int begin() => rust.beginPluginJob();

  @override
  void cancel(int job) {
    try {
      rust.cancelPluginJob(job: job);
    } on Object catch (error) {
      _log.warning('The plugin job cancel failed: ${error.runtimeType}');
    }
  }

  @override
  Future<EngineResult> run(EngineRequest request, EngineFetch fetch) async {
    try {
      final result = await rust.runPluginScript(
        request: _toBridgeRequest(request),
        fetch: (req) async => _toBridge(await fetch(_fromBridge(req))),
      );
      return _fromBridgeResult(result);
    } on Object catch (error) {
      _log.warning('The plugin runtime call failed: ${error.runtimeType}');
      return const EngineResult(status: EngineStatus.internal);
    }
  }

  @override
  Future<EngineResult> runStreaming(
    EngineRequest request,
    EngineFetch fetch,
    EngineStream stream, {
    required Duration idle,
    required void Function(String json) onEvent,
  }) async {
    StreamEventGate? gate;
    try {
      // Attached (sync) before the run starts, so no event is missed.
      gate = StreamEventGate(rust.pluginJobEvents(job: request.job), onEvent);
      final result = await rust.runPluginStreamScript(
        request: _toBridgeRequest(request),
        options: rust.PluginStreamOptions(
          idleTimeoutMs: idle.inMilliseconds,
          events: true,
        ),
        fetch: (req) async => _toBridge(await fetch(_fromBridge(req))),
        stream: (call) async =>
            streamReplyToBridge(await stream(streamCallFromBridge(call))),
      );
      await gate.finish();
      return _fromBridgeResult(result);
    } on Object catch (error) {
      _log.warning('The plugin runtime call failed: ${error.runtimeType}');
      gate?.close();
      return const EngineResult(status: EngineStatus.internal);
    }
  }
}

rust.PluginScriptRequest _toBridgeRequest(EngineRequest request) =>
    rust.PluginScriptRequest(
      job: request.job,
      installId: request.installId,
      files: [
        for (final f in request.files)
          rust.PluginSourceFile(name: f.name, code: f.code),
      ],
      entry: request.entry,
      inputJson: request.inputJson,
      timeoutMs: request.timeoutMs,
      config: request.config,
      storageJson: request.storageJson,
    );

/// A bridge stream call as the engine's plain type.
EngineStreamCall streamCallFromBridge(rust.PluginStreamCall c) =>
    EngineStreamCall(
      installId: c.installId,
      stream: c.stream,
      op: switch (c.op) {
        rust.PluginStreamOp.open => EngineStreamOp.open,
        rust.PluginStreamOp.read => EngineStreamOp.read,
        rust.PluginStreamOp.close => EngineStreamOp.close,
      },
      request: c.request == null ? null : _fromBridge(c.request!),
      maxBytes: c.maxBytes,
      waitMs: c.waitMs,
      lifetimeMs: c.lifetimeMs,
    );

/// The engine's stream reply as the bridge type.
rust.PluginStreamReply streamReplyToBridge(EngineStreamReply r) =>
    rust.PluginStreamReply(
      outcome: _outcomeToBridge(r.outcome),
      status: r.status,
      url: r.url,
      headers: r.headers,
      retryAfterSec: r.retryAfterSec,
      chunk: r.chunk,
      done: r.done,
      sends: r.sends,
    );

EngineFetchRequest _fromBridge(rust.PluginFetchRequest r) => EngineFetchRequest(
  installId: r.installId,
  method: r.method,
  url: r.url,
  headers: r.headers,
  body: r.body,
  deadlineMs: r.deadlineMs,
  maxSends: r.maxSends,
);

rust.PluginFetchResponse _toBridge(EngineFetchResponse r) =>
    rust.PluginFetchResponse(
      outcome: _outcomeToBridge(r.outcome),
      status: r.status,
      url: r.url,
      headers: r.headers,
      body: r.body,
      retryAfterSec: r.retryAfterSec,
      sends: r.sends,
    );

EngineResult _fromBridgeResult(rust.PluginScriptResult r) => EngineResult(
  status: switch (r.status) {
    rust.PluginScriptStatus.ok => EngineStatus.ok,
    rust.PluginScriptStatus.scriptError => EngineStatus.scriptError,
    rust.PluginScriptStatus.timeout => EngineStatus.timeout,
    rust.PluginScriptStatus.memory => EngineStatus.memory,
    rust.PluginScriptStatus.stack => EngineStatus.stack,
    rust.PluginScriptStatus.cancelled => EngineStatus.cancelled,
    rust.PluginScriptStatus.outputTooLarge => EngineStatus.outputTooLarge,
    rust.PluginScriptStatus.internal => EngineStatus.internal,
    rust.PluginScriptStatus.busy => EngineStatus.busy,
  },
  outputJson: r.outputJson,
  errorMessage: r.errorMessage,
  errorKind: switch (r.errorKind) {
    rust.PluginErrorKind.none => EngineErrorKind.none,
    rust.PluginErrorKind.rateLimited => EngineErrorKind.rateLimited,
    rust.PluginErrorKind.invalidResponse => EngineErrorKind.invalidResponse,
    rust.PluginErrorKind.server => EngineErrorKind.server,
    rust.PluginErrorKind.auth => EngineErrorKind.auth,
    rust.PluginErrorKind.quota => EngineErrorKind.quota,
  },
  retryAfterSec: r.retryAfterSec,
  jsError: r.jsError == null
      ? null
      : EngineJsError(message: r.jsError!.message, stack: r.jsError!.stack),
  logs: r.logs,
  fetchFailure: r.fetchFailure == null ? null : _failureOf(r.fetchFailure!),
  storageJson: r.storageJson,
);

FetchFailureInfo _failureOf(rust.PluginFetchFailure f) => FetchFailureInfo(
  kind: switch (f.kind) {
    rust.PluginFetchFailureKind.network => FetchFailureKind.network,
    rust.PluginFetchFailureKind.blockedHost => FetchFailureKind.blockedHost,
    rust.PluginFetchFailureKind.notConsented => FetchFailureKind.notConsented,
    rust.PluginFetchFailureKind.abandoned => FetchFailureKind.abandoned,
    rust.PluginFetchFailureKind.invalidRequest =>
      FetchFailureKind.invalidRequest,
    rust.PluginFetchFailureKind.invalidResponse =>
      FetchFailureKind.invalidResponse,
    rust.PluginFetchFailureKind.rateLimited => FetchFailureKind.rateLimited,
  },
  retryAfter: f.retryAfterSec == null
      ? null
      : Duration(seconds: f.retryAfterSec!),
  message: f.message,
);

rust.PluginFetchOutcome _outcomeToBridge(EngineFetchOutcome o) => switch (o) {
  EngineFetchOutcome.ok => rust.PluginFetchOutcome.ok,
  EngineFetchOutcome.network => rust.PluginFetchOutcome.network,
  EngineFetchOutcome.blockedHost => rust.PluginFetchOutcome.blockedHost,
  EngineFetchOutcome.notConsented => rust.PluginFetchOutcome.notConsented,
  EngineFetchOutcome.abandoned => rust.PluginFetchOutcome.abandoned,
  EngineFetchOutcome.invalidRequest => rust.PluginFetchOutcome.invalidRequest,
  EngineFetchOutcome.invalidResponse => rust.PluginFetchOutcome.invalidResponse,
  EngineFetchOutcome.rateLimited => rust.PluginFetchOutcome.rateLimited,
};
