part of 'listen_recorder.dart';

/// Clearing the play log while a listen is open.
///
/// The first pending clear parks the open listen in `_held`; while any clear
/// is pending [ListenRecorder.observe] only remembers the last observation, so
/// nothing is counted or written. Each clear's delete runs on the recorder's
/// chain, so every write queued before it lands first, and decides by the
/// listen's start whether the parked one is dropped. When the last clear is
/// done a kept listen goes on (or gets its final write if the player left it)
/// and counting restarts from the last observation, so a dropped listen whose
/// track still plays is counted anew.
extension _ClearCoordination on ListenRecorder {
  /// Deletes the plays that started in `[from, to)` (epoch ms, a missing side
  /// is open). Clears run one after another, each with its own count; the
  /// result is null when the delete failed, and then the history and the open
  /// listen are untouched.
  Future<int?> _clear(ClearBounds bounds) async {
    if (_closed || _closing != null) return null;
    _beginClear();
    int? removed;
    try {
      removed = await _chain.run(() => _deleteRange(bounds));
    } on Object catch (e) {
      _log.warning('could not clear the history: ${e.runtimeType}');
    } finally {
      if (--_pendingClears == 0) _endClears();
    }
    return removed;
  }

  void _beginClear() {
    if (_pendingClears++ > 0) return;
    _clearsDone = Completer<void>();
    _held = _active;
    _active = null;
    _last = _held?.observation;
    _clearing.value = true;
  }

  Future<int> _deleteRange(ClearBounds bounds) async {
    final removed = await _writer.deleteRange(from: bounds.from, to: bounds.to);
    if (clearTouches(bounds, _held?.acc.playedAt)) _held = null;
    if (!_cleared.isClosed) _cleared.add(bounds);
    return removed;
  }

  void _endClears() {
    // Taken first: a listener woken below may start a clear with its own.
    final done = _clearsDone;
    _clearsDone = null;
    try {
      final kept = _held;
      final last = _last;
      _held = null;
      _last = null;
      if (kept != null) {
        if (last != null && last.token == kept.observation.token) {
          _active = kept;
        } else {
          _finish(kept);
        }
      }
      _clearing.value = false;
      if (last != null) observe(last);
    } finally {
      done?.complete();
    }
  }

  /// Completes when no clear is pending, also for one started meanwhile.
  Future<void> _waitForClears() async {
    for (var d = _clearsDone; d != null; d = _clearsDone) {
      await d.future;
    }
  }
}
