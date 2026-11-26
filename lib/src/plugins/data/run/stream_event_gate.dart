import 'dart:async';

import 'package:logging/logging.dart';

final _log = Logger('plugin_run');

/// Delivers the events of a streaming run to a callback, in order, and shuts
/// the door when the run is over.
///
/// Create it before the run starts (the subscription is made at once), call
/// [finish] after the script result: it waits for the event stream to end (the
/// bridge closes it when the run ends) for at most [settle], then cancels the
/// subscription. After [finish] or [close] the callback is never called again.
/// A throw from the callback is logged by type only and the run goes on.
class StreamEventGate {
  StreamEventGate(
    Stream<String> events,
    this._onEvent, {
    this.settle = const Duration(seconds: 2),
  }) {
    _sub = events.listen(
      _deliver,
      onError: (Object error) {
        // Type only: the text may carry the plugin's own data.
        _log.warning('The plugin event stream failed: ${error.runtimeType}');
        _end();
      },
      onDone: _end,
      cancelOnError: false,
    );
  }

  /// Longest wait for the event stream to end after the script result.
  final Duration settle;
  final void Function(String json) _onEvent;
  late final StreamSubscription<String> _sub;
  final _done = Completer<void>();
  var _open = true;

  void _deliver(String json) {
    if (!_open) return;
    try {
      _onEvent(json);
    } on Object catch (error) {
      // Type only: the text may carry the plugin's own data.
      _log.warning('A plugin event handler failed: ${error.runtimeType}');
    }
  }

  void _end() {
    if (!_done.isCompleted) _done.complete();
  }

  /// Waits for the end of the events (at most [settle]), then closes the gate
  /// and cancels the subscription. Safe to call more than once.
  Future<void> finish() async {
    if (_open) {
      await _done.future.timeout(settle, onTimeout: () {});
    }
    close();
  }

  /// Closes the gate at once, dropping what has not been delivered.
  void close() {
    _open = false;
    // Not awaited: a cancel can wait for the source to close, which must not
    // hold the run's result back.
    unawaited(
      _sub.cancel().catchError((Object error) {
        _log.warning('The plugin event cancel failed: ${error.runtimeType}');
      }),
    );
  }
}
