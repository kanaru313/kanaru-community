import '../domain/audio_engine.dart';

/// What the adapter read from mpv at one moment. Every field is read fresh
/// from mpv (never from media_kit's lagging playlist state).
class MpvSnapshot {
  const MpvSnapshot({
    required this.playingPos,
    required this.playingId,
    required this.count,
    required this.idle,
    required this.eofReached,
    this.duration,
  });

  /// `playlist-playing-pos`, -1 when nothing plays.
  final int playingPos;

  /// `playlist/<pos>/id` of the playing entry; null when nothing plays.
  final int? playingId;

  /// `playlist-count`.
  final int count;
  final bool idle;
  final bool eofReached;

  /// `duration` of the playing entry; null or zero until it opened.
  final Duration? duration;
}

class _Entry {
  _Entry(this.mpvId, this.token);
  final int mpvId;
  final EngineToken token;
  bool loaded = false;
}

/// The bookkeeping of mpv's two-entry playlist, pure and driven by
/// [MpvSnapshot]s: which entry plays, when it advanced, loaded, failed or
/// ended. Entries are matched by mpv's entry id, never by path, so the same
/// file queued twice is two entries.
class MpvPlaylistTracker {
  _Entry? _current;
  _Entry? _next;
  bool _endedReported = false;

  EngineToken? get currentToken => _current?.token;
  EngineToken? get nextToken => _next?.token;
  int? get nextMpvId => _next?.mpvId;

  /// Forgets everything (a new load replaces the playlist).
  void reset() {
    _current = null;
    _next = null;
    _endedReported = false;
  }

  /// A fresh playlist whose only entry is [token], mpv id [mpvId].
  void startLoad(EngineToken token, int mpvId) {
    reset();
    _current = _Entry(mpvId, token);
  }

  /// [token] was appended as the entry after the current one.
  void registerNext(EngineToken token, int mpvId) {
    _next = _Entry(mpvId, token);
    _endedReported = false;
  }

  void clearNext() => _next = null;

  /// Whether mpv sits at the end of the current entry with a next one
  /// waiting: the engine must send `playlist-next`.
  bool needsPlaylistNext(MpvSnapshot s) =>
      _next != null &&
      _current != null &&
      s.playingId == _current!.mpvId &&
      s.eofReached;

  /// Entries before the playing one: the engine removes that many from the
  /// front so the playlist holds at most the current and the next entry.
  int entriesToTrim(MpvSnapshot s) =>
      (_current != null && s.playingId == _current!.mpvId && s.playingPos > 0)
      ? s.playingPos
      : 0;

  /// Events implied by [s].
  List<EngineEvent> onSnapshot(MpvSnapshot s) {
    final out = <EngineEvent>[];
    final cur = _current;
    if (cur == null) return out;

    if (!s.idle && s.playingId == null) return out; // transient: between files
    if (s.idle) {
      // mpv has nothing loaded: an entry that never opened failed.
      if (!cur.loaded) {
        out.add(EngineFailed(cur.token, 'could not open the file'));
      }
      if (_next != null) {
        out.add(EngineFailed(_next!.token, 'could not open the file'));
      }
      _current = null;
      _next = null;
      return out;
    }

    final id = s.playingId;
    if (_next != null && id == _next!.mpvId) {
      // Promote only when mpv's playing entry is the handed-over one.
      if (!cur.loaded) {
        out.add(EngineFailed(cur.token, 'left without opening'));
      }
      _current = _next;
      _next = null;
      _endedReported = false;
      out.add(EngineAdvanced(_current!.token));
      _maybeLoaded(s, out);
      return out;
    }
    if (id != cur.mpvId) return out; // stale entry: not ours any more

    _maybeLoaded(s, out);
    // A seek back from the end re-arms the end report.
    if (!s.eofReached) _endedReported = false;
    if (s.eofReached && _next == null && cur.loaded && !_endedReported) {
      _endedReported = true;
      out.add(EngineEnded(cur.token));
    }
    return out;
  }

  void _maybeLoaded(MpvSnapshot s, List<EngineEvent> out) {
    final cur = _current!;
    final d = s.duration;
    if (!cur.loaded && d != null && d > Duration.zero) {
      cur.loaded = true;
      out.add(EngineLoaded(cur.token, d));
    }
  }
}
