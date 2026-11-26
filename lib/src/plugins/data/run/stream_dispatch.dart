import 'dart:async';

import 'package:logging/logging.dart';

import '../../domain/net/cancel_token.dart';
import '../../domain/run/plugin_engine.dart';
import '../../domain/run/run_request.dart';
import 'fetch_handler.dart';
import 'run_admission.dart';
import 'stream_fetch_handler.dart';
import 'stream_table.dart';

final _log = Logger('plugin_run');

/// Longest wall time of one streaming run.
const maxStreamRunWall = Duration(seconds: 300);

/// Longest wait of a streaming run for the one stream slot, before it ends
/// busy.
const streamAdmissionWait = Duration(seconds: 10);

/// Time the runtime gets, after the outer deadline, to release the job of a
/// streaming run (the delivery of the last events) before the runner takes the
/// slot back.
const streamSettle = Duration(seconds: 2);

/// A table of streams for one run, closed with the run's [CancelToken].
typedef StreamTableFactory = StreamTable Function(CancelToken jobCancel);

/// The streaming side of one dispatch: the caller's event callback behind a
/// door, and the stream calls answered into this run's own [StreamTable].
///
/// Close it when the run is answered: events that still arrive are dropped and
/// every stream is closed. Closing twice is harmless.
class StreamDispatch {
  StreamDispatch({
    required this._options,
    required this._handler,
    required this._context,
    required this.table,
  });

  final StreamOptions _options;
  final StreamFetchHandler _handler;
  final JobContext _context;

  /// The streams of this run; empty and sealed after [close].
  final StreamTable table;
  var _open = true;

  /// Longest wait for data in one stream read.
  Duration get idle => _options.idle;

  /// The engine's event callback: delivers while the door is open; a throw is
  /// logged by type only (the text may carry the caller's data).
  ///
  /// The engine's own event gate is the contract (it never delivers after the
  /// run ends); this door only drops what still arrives after the outcome was
  /// answered, and its catch is a second line behind the gate's.
  void onEvent(String json) {
    if (!_open) return;
    try {
      _options.onEvent(json);
    } on Object catch (error) {
      _log.warning('A plugin event handler failed: ${error.runtimeType}');
    }
  }

  /// The engine's stream calls. A call of another plugin is refused like a
  /// fetch of another plugin.
  Future<EngineStreamReply> call(EngineStreamCall call) {
    if (call.installId != _context.installId) {
      return Future.value(
        EngineStreamReply.empty(EngineFetchOutcome.invalidRequest),
      );
    }
    return _handler.handle(call, _context, table);
  }

  void close() {
    _open = false;
    table.dispose();
  }
}

/// An engine job that was started: the streaming side (null for a plain run)
/// and the future of the engine's result, which also gives the slot back.
class StartedRun {
  const StartedRun({required this.streamRun, required this.running});

  final StreamDispatch? streamRun;

  /// Completes when the runtime let go of the job; the slot is released then.
  final Future<EngineResult> running;
}

/// Starts the engine job of one run, plain or streaming.
///
/// A streaming run gets its [StreamDispatch] and a hung-slot timer: a job that
/// is still not released [hungAfter] from now (the outer deadline plus a
/// settle) is given up on, so one stuck job cannot hold the only stream slot
/// for good. Either way the slot stays taken until the runtime really let go
/// of the job, even when the run was already answered at its deadline.
///
/// When the engine call throws, the streams are closed and the error is
/// rethrown (the caller tells the runtime to forget the job).
StartedRun startEngineRun({
  required PluginEngine engine,
  required EngineRequest request,
  required EngineFetch fetch,
  required JobContext context,
  required CancelToken jobCancel,
  required RunSlot slot,
  required Duration hungAfter,
  StreamOptions? stream,
  StreamFetchHandler? streamHandler,
  StreamTableFactory streamTables = StreamTable.new,
}) {
  final streamRun = stream == null
      ? null
      : StreamDispatch(
          options: stream,
          handler: streamHandler!,
          context: context,
          table: streamTables(jobCancel),
        );
  final Future<EngineResult> started;
  try {
    started = streamRun == null
        ? engine.run(request, fetch)
        : engine.runStreaming(
            request,
            fetch,
            streamRun.call,
            idle: streamRun.idle,
            onEvent: streamRun.onEvent,
          );
  } on Object {
    streamRun?.close();
    rethrow;
  }
  final hung = streamRun == null
      ? null
      : Timer(hungAfter, () {
          if (slot.isReleased) return;
          _log.warning('A stream job did not end: its slot was released');
          slot.release();
        });
  final running = started.whenComplete(() {
    hung?.cancel();
    slot.release();
  });
  return StartedRun(streamRun: streamRun, running: running);
}
