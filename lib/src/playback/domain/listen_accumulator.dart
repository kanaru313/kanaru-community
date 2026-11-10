/// Tracks of this length or shorter never count as a listen.
const listenMinTrackLength = Duration(seconds: 30);

/// A listen needs at most this much listening time, however long the track.
const listenMaxRequired = Duration(minutes: 4);

/// The share of a track that counts never exceeds its length minus this: the
/// last position the engine reports comes a little before the end, so "100 %"
/// could not be reached.
const listenEndSlack = Duration(seconds: 1);

/// The position may run ahead of the clock by this much and still count as
/// played (ticks delivered late, in a burst); more than that is a seek.
const listenSeekSlack = Duration(seconds: 1);

/// Listening time that makes a listen of a track [length] long: half of it
/// (kept below the end), at most four minutes. An unknown length needs the
/// four minutes.
Duration listenRequiredFor(Duration? length) {
  if (length == null) return listenMaxRequired;
  final half = Duration(microseconds: length.inMicroseconds ~/ 2);
  final reachable = length - listenEndSlack;
  final needed = half < reachable ? half : reachable;
  return needed < listenMaxRequired ? needed : listenMaxRequired;
}

/// Whether [listened] makes a listen of a track [length] long: the track is
/// longer than 30 s and was heard for [listenRequiredFor] it.
bool qualifiesAsListen(Duration listened, Duration? length) {
  if (length != null && length <= listenMinTrackLength) return false;
  return listened >= listenRequiredFor(length);
}

/// Listening time of one load of one entry. Feed it every observation.
///
/// Time counts between two consecutive samples that are both playing and
/// whose position moved forward. The position delta is taken as is unless it
/// outruns the monotonic clock by more than [listenSeekSlack]: then it was a
/// jump (a seek) and only the clock delta counts, the audio that really
/// played. A burst of late ticks counts in full, backward moves and pauses
/// add nothing.
///
/// The track length is locked at the first value seen: with gapless playback
/// the engine can report the next track's length for the tail of this one.
class ListenAccumulator {
  Duration _lastPosition = Duration.zero;
  Duration _lastClock = Duration.zero;
  bool _wasPlaying = false;
  bool _seen = false;
  Duration _listened = Duration.zero;
  Duration? _length;
  int? _playedAt;

  /// Time listened so far.
  Duration get listened => _listened;

  /// Length of the track, locked at the first known value.
  Duration? get length => _length;

  /// Wall time (epoch ms) of the first playing sample; null before it.
  int? get playedAt => _playedAt;

  /// Whether the last sample was playing.
  bool get playing => _wasPlaying;

  /// Whether the listen counts now.
  bool get qualifies => qualifiesAsListen(_listened, _length);

  /// Sets the length once; later values are ignored.
  void lockLength(Duration? length) {
    if (_length == null && length != null && length > Duration.zero) {
      _length = length;
    }
  }

  /// One observation: [position] in the track, a monotonic [clock], whether
  /// audio is [playing], and the wall time [wallMs] (stored for the first
  /// playing sample).
  void sample({
    required Duration position,
    required Duration clock,
    required bool playing,
    required int wallMs,
  }) {
    if (playing) _playedAt ??= wallMs;
    if (_seen && _wasPlaying && playing) {
      final positionDelta = position - _lastPosition;
      if (positionDelta > Duration.zero) {
        final clockDelta = clock - _lastClock;
        _listened += positionDelta <= clockDelta + listenSeekSlack
            ? positionDelta
            : (clockDelta > Duration.zero ? clockDelta : Duration.zero);
      }
    }
    _seen = true;
    _lastPosition = position;
    _lastClock = clock;
    _wasPlaying = playing;
  }
}
