import 'dart:async';
import 'dart:typed_data';

import 'run_outcome.dart';

/// How the engine ended a run (the bridge's status, in plain Dart).
enum EngineStatus {
  ok,
  scriptError,
  timeout,
  memory,
  stack,
  cancelled,
  outputTooLarge,
  internal,
  busy,
}

/// Kind of a script-reported failure; [none] when the script gave none.
enum EngineErrorKind { none, rateLimited, invalidResponse, server, auth, quota }

/// How the host answered a fetch of the script.
enum EngineFetchOutcome {
  ok,
  network,
  blockedHost,
  notConsented,
  abandoned,
  invalidRequest,
  invalidResponse,
  rateLimited,
}

/// One file of the package's `src/` folder.
class EngineFile {
  const EngineFile(this.name, this.code);

  final String name;
  final String code;
}

/// What to run. Mirrors the bridge request.
class EngineRequest {
  const EngineRequest({
    required this.job,
    required this.installId,
    required this.files,
    required this.entry,
    required this.inputJson,
    required this.timeoutMs,
    required this.config,
    required this.storageJson,
  });

  final int job;
  final String installId;
  final List<EngineFile> files;
  final String entry;
  final String inputJson;
  final int timeoutMs;

  /// `(key, JSON text of the value)`.
  final List<(String, String)> config;

  /// The plugin's stored map as JSON; empty means nothing stored.
  final String storageJson;
}

/// A script exception.
class EngineJsError {
  const EngineJsError({required this.message, this.stack = ''});

  final String message;
  final String stack;
}

/// How a run ended. Every field is filled whatever the [status].
class EngineResult {
  const EngineResult({
    required this.status,
    this.outputJson = '',
    this.errorMessage = '',
    this.errorKind = EngineErrorKind.none,
    this.retryAfterSec,
    this.jsError,
    this.logs = const [],
    this.fetchFailure,
    this.storageJson,
  });

  final EngineStatus status;
  final String outputJson;
  final String errorMessage;
  final EngineErrorKind errorKind;
  final int? retryAfterSec;
  final EngineJsError? jsError;

  /// Console lines captured before the run ended.
  final List<String> logs;
  final FetchFailureInfo? fetchFailure;

  /// The new storage map, only when the script changed it and finished on its
  /// own.
  final String? storageJson;
}

/// One `fetch` of the script, handed to the host.
class EngineFetchRequest {
  const EngineFetchRequest({
    required this.installId,
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
    required this.deadlineMs,
    required this.maxSends,
  });

  final String installId;
  final String method;
  final String url;
  final List<(String, String)> headers;
  final Uint8List body;

  /// Wall time left for this call, in ms.
  final int deadlineMs;

  /// HTTP sends still allowed for this call, at least 1.
  final int maxSends;
}

/// The host's answer to an [EngineFetchRequest].
class EngineFetchResponse {
  const EngineFetchResponse({
    required this.outcome,
    this.status = 0,
    this.url = '',
    this.headers = const [],
    required this.body,
    this.retryAfterSec,
    this.sends = 0,
  });

  /// An answer that carries no response, only why there is none.
  EngineFetchResponse.failure(this.outcome, {this.retryAfterSec})
    : status = 0,
      url = '',
      headers = const [],
      body = Uint8List(0),
      sends = 0;

  final EngineFetchOutcome outcome;
  final int status;
  final String url;
  final List<(String, String)> headers;
  final Uint8List body;
  final int? retryAfterSec;
  final int sends;
}

typedef EngineFetch = FutureOr<EngineFetchResponse> Function(
  EngineFetchRequest request,
);

/// What a stream call of the script asks for.
enum EngineStreamOp { open, read, close }

/// One call of the runtime about a streamed `fetch`. Mirrors the bridge call.
class EngineStreamCall {
  const EngineStreamCall({
    required this.installId,
    required this.stream,
    required this.op,
    this.request,
    this.maxBytes = 0,
    this.waitMs = 0,
    this.lifetimeMs = 0,
  });

  final String installId;

  /// Stream id, unique within the run.
  final int stream;
  final EngineStreamOp op;

  /// For [EngineStreamOp.open] only.
  final EngineFetchRequest? request;

  /// For read: most bytes to return.
  final int maxBytes;

  /// For read: longest wait for bytes, in ms.
  final int waitMs;

  /// For open: wall time left for the run, in ms; the host closes the stream
  /// by itself once it has passed.
  final int lifetimeMs;
}

/// The host's answer to an [EngineStreamCall].
class EngineStreamReply {
  const EngineStreamReply({
    required this.outcome,
    this.status = 0,
    this.url = '',
    this.headers = const [],
    this.retryAfterSec,
    required this.chunk,
    this.done = false,
    this.sends = 0,
  });

  /// An answer that carries nothing, only [outcome] (`ok` for an answered
  /// close).
  EngineStreamReply.empty(this.outcome, {this.retryAfterSec})
    : status = 0,
      url = '',
      headers = const [],
      chunk = Uint8List(0),
      done = false,
      sends = 0;

  /// `ok`, or why the call failed (`network` also stands for idle).
  final EngineFetchOutcome outcome;

  /// For open: the HTTP status.
  final int status;

  /// For open: the requested URL (nothing is followed).
  final String url;
  final List<(String, String)> headers;
  final int? retryAfterSec;

  /// For read: bytes that arrived; never empty unless [done].
  final Uint8List chunk;

  /// For read: the body really ended.
  final bool done;

  /// For open: HTTP sends made.
  final int sends;
}

typedef EngineStream = Future<EngineStreamReply> Function(
  EngineStreamCall call,
);

/// The plugin runtime as the runner sees it. The production implementation
/// is the Rust runtime; tests use a fake.
abstract interface class PluginEngine {
  /// Forgets every job left over from a previous isolate (a hot restart).
  /// The runner calls it once, before its first job.
  void reset();

  /// Registers a job and returns its id. Every begun id must be passed to
  /// [run] or [cancel]led.
  int begin();

  /// Cancels a job: queued ends cancelled at once, running stops at its next
  /// interrupt. Unknown or finished ids do nothing.
  void cancel(int job);

  /// Runs the script; [fetch] answers its host `fetch` calls. Never throws.
  Future<EngineResult> run(EngineRequest request, EngineFetch fetch);
}
