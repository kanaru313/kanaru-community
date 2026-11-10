part of 'player_controller.dart';

/// Reacting to the engine. Runs inside the chain, after a token check: events
/// of an older load are dropped.
extension _Events on PlayerController {
  Future<void> _onEngineEvent(EngineEvent e) async {
    _dirty = true;
    switch (e) {
      case EngineLoaded(:final token, :final duration):
        if (token != _loaded) return;
        _duration = duration;
        _loadedOk = true;
        _failuresInRow = 0;
        // The restored file opened: the saved session is real.
        restoring = false;
      case EngineAdvanced(:final token):
        if (token.generation != _generation) return;
        await _onAdvanced(token);
      case EngineFailed(:final token):
        if (token.generation != _generation) return;
        await _onFailed(token);
      case EngineEnded(:final token):
        if (token != _loaded) return;
        await _onEnded();
      case EngineSeeked():
        break;
    }
    _publish();
  }

  /// The engine finished the current entry C and moved on to [token]'s
  /// entry. If that is the entry handed over (or, after a replaced hand-over,
  /// the entry that follows C anyway), it becomes current. Otherwise C is
  /// done and the entry after it in the queue as it is now loads at 0: the
  /// finished entry never plays again.
  Future<void> _onAdvanced(EngineToken token) async {
    // A reload is already decided (a jump, a removal of C): it wins.
    if (_forceReload) return;
    final index = _queue.indexOfEntry(token.entryId);
    final follows = nextIndex(_queue, auto: true);
    if (index >= 0 && (token == _handedNext || index == follows)) {
      final skip = token == _handedNext ? _handedSkip : null;
      _queue = _queue.withCurrent(index, _queue.playNextRunIds);
      _loaded = token;
      _handedNext = null;
      _handedSkip = null;
      _loadedOk = false;
      _duration = null;
      _atEnd = false;
      _position = Duration.zero;
      _startAt = Duration.zero;
      _saveNow();
      if (skip != null) {
        _notice(
          TrackSkipped(
            await _titles.titleOf(skip.track),
            skip.reason,
            skip.count,
          ),
        );
      }
      return;
    }
    _generation++;
    _handedNext = null;
    _handedSkip = null;
    if (follows == null) {
      // C was the last entry and what the engine plays is gone: stop it.
      _loaded = null;
      await _engine?.stop();
      _finishQueue();
      // Stay at the end: a reload of C (paused) must not start at 0.
      _startAt = _position;
      return;
    }
    _jump(follows, user: false);
  }

  Future<void> _onFailed(EngineToken token) async {
    if (restoring && (token == _loaded || token == _handedNext)) {
      // The restored file did not open (drive gone, file moved) although the
      // library lists it. It stays current; nothing is said, skipped or
      // saved. Bumping the generation drops the rest of this load's events
      // (the handed next failing or loading). A user Play retries once, then
      // skips with a notice.
      final current = _queue.currentItem;
      if (current != null) _bad.add(current.entryId);
      _generation++;
      _loaded = null;
      _handedNext = null;
      _handedSkip = null;
      _loadedOk = false;
      _enginePlaying = false;
      await _engine?.stop();
      return;
    }
    final item = _queue.items.where((i) => i.entryId == token.entryId);
    final title = item.isEmpty ? '' : await _titles.titleOf(item.first.trackId);
    _notice(TrackFailed(title));
    _failuresInRow++;
    _bad.add(token.entryId);
    if (_failuresInRow >= _queue.length) {
      _intent = PlayIntent.stopped;
      return;
    }
    if (token == _handedNext) {
      // mpv left the current and could not open the next: it is empty. Make
      // the failed entry current; the reconcile skips it and loads the one
      // after it.
      final index = _queue.indexOfEntry(token.entryId);
      _handedNext = null;
      _handedSkip = null;
      _loaded = null;
      if (index >= 0) _jump(index, user: false);
      return;
    }
    if (token == _loaded) {
      final i = nextIndex(_queue, auto: false);
      if (i == null) {
        _intent = PlayIntent.stopped;
        _notice(const QueueEnd());
        return;
      }
      _jump(i, user: false);
    }
  }

  Future<void> _onEnded() async {
    final i = nextIndex(_queue, auto: true);
    if (i == null) {
      // Paused at the end: a song added later waits, paused. The engine is
      // told, so a late hand-over does not start playing by itself.
      await _engine?.pause();
      _finishQueue();
      return;
    }
    _jump(i, user: false);
  }

  void _finishQueue() {
    _intent = PlayIntent.paused;
    _enginePlaying = false;
    _atEnd = true;
    _position = _duration ?? _position;
    _saveNow();
    _notice(const QueueEnd());
  }
}
