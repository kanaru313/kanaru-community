import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:logging/logging.dart';

import '../data/saved_queue_writer.dart';
import '../domain/replaced_queue.dart';

final _log = Logger('playback.saved_queue');

/// Saves each queue the user loses (cleared, or replaced by another one) as a
/// saved queue. Writes run one after the other in the order the events came,
/// after the player command that caused them returned. A failed write is
/// logged and dropped: history must never break playback.
class SavedQueueRecorder {
  SavedQueueRecorder({required this._writer, required this._now});

  final SavedQueueWriter _writer;
  final int Function() _now;
  Future<void> _tail = Future.value();
  bool _disposed = false;

  /// Completes when every write queued so far has finished (or failed).
  Future<void> get idle => _tail;

  void onReplaced(ReplacedQueue e) {
    if (_disposed) return;
    // Replaced by the same tracks in the same order the user sees: the saved
    // queue would be a copy of the one that is playing again.
    final next = e.next;
    if (next != null && listEquals(e.userOrder, next)) return;
    _tail = _tail.then((_) async {
      // A write still queued when the recorder is disposed is dropped.
      if (_disposed) return;
      try {
        await _writer.save(e, _now());
      } on Object catch (err, st) {
        _log.warning('saving the replaced queue failed: $err', err, st);
      }
    });
  }

  /// Ignores events from now on and drops writes that have not started.
  void dispose() => _disposed = true;
}
