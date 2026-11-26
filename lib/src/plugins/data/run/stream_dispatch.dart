import 'package:logging/logging.dart';

import '../../domain/net/cancel_token.dart';
import '../../domain/run/plugin_engine.dart';
import '../../domain/run/run_request.dart';
import 'fetch_handler.dart';
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
