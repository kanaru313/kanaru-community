part of 'player_controller.dart';

/// Session persistence: restore at launch, position saves, listens and the
/// exit flush.
extension _Session on PlayerController {
  /// First task of the chain: puts the saved queue back, paused, and lets the
  /// next reconcile load the current entry at the saved position. Nothing is
  /// written; the restored state stays frozen until the file loads or the
  /// user acts.
  Future<void> _restore() async {
    _volume = readSetting(_settings, volumeSetting);
    final session = await loadSession(repo: _repo, settings: _settings);
    if (session == null) {
      restoring = false;
      _publish();
      return;
    }
    _queue = session.queue;
    _repeatTimes = session.repeatTimes;
    _context = session.context;
    _position = session.position;
    _startAt = session.position;
    _intent = PlayIntent.paused;
    _savedCurrent = _queue.currentItem?.entryId;
    _forceReload = true;
    _dirty = true;
    _publish();
  }

  /// The user did something that makes the session theirs: persistence and
  /// skipping of unplayable entries may start.
  void _thaw() => restoring = false;

  /// Position write right away (pause, seek, track change, stop).
  void _saveNow() => _saver.save(_position);

  /// Tells the listen recorder what is playing. Called on every tick and
  /// every published change; synchronous and cheap.
  void _observeListen() {
    final token = _loaded;
    final cur = _queue.currentItem;
    final length = _duration;
    if (token == null ||
        !_loadedOk ||
        cur == null ||
        length == null ||
        token.entryId != cur.entryId) {
      _listens.observe(null);
      return;
    }
    _listens.observe(
      ListenObservation(
        token: token,
        trackId: cur.trackId,
        context: _context,
        position: _position,
        length: length,
        playing: _intent == PlayIntent.playing && _enginePlaying,
      ),
    );
  }
}
