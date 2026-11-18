/// Tracks of this length or shorter never count as a listen.
const listenMinTrackLength = Duration(seconds: 30);

/// The time that counts when the length of the track is unknown and the rule
/// has no time part; also the cap of the standard rule.
const listenMaxRequired = Duration(minutes: 4);

/// The share of a track that counts never exceeds its length minus this: the
/// last position the engine reports comes a little before the end, so "100 %"
/// could not be reached.
const listenEndSlack = Duration(seconds: 1);

/// The position may run ahead of the clock by this much and still count as
/// played (ticks delivered late, in a burst); more than that is a seek.
const listenSeekSlack = Duration(seconds: 1);

/// Stops of the "listening time" slider, ms; 0 = no time rule.
const listenAfterStopsMs = <int>[
  0,
  10000,
  20000,
  30000,
  45000,
  60000,
  90000,
  120000,
  180000,
  240000,
  300000,
  420000,
  600000,
];

/// When a listen counts: after [afterMs] of listening (0 = no time rule) or
/// after [percent] of the track, whichever comes first. 100 % means the
/// whole track.
class ListenRule {
  const ListenRule({required this.afterMs, required this.percent});

  /// A rule from stored numbers: [percent] kept in 10..100 on a step of 5,
  /// [afterMs] moved to the nearest of [listenAfterStopsMs].
  factory ListenRule.snapped(int afterMs, int percent) => ListenRule(
    afterMs: listenAfterStopsMs.reduce(
      (best, stop) =>
          (stop - afterMs).abs() < (best - afterMs).abs() ? stop : best,
    ),
    percent: ((percent.clamp(10, 100) / 5).round() * 5),
  );

  /// Four minutes or half of the track.
  static const standard = ListenRule(afterMs: 240000, percent: 50);

  final int afterMs;
  final int percent;

  @override
  bool operator ==(Object other) =>
      other is ListenRule &&
      other.afterMs == afterMs &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(afterMs, percent);
}

/// Listening time that makes a listen of a track [length] long under [rule]:
/// the earlier of the time rule and the share of the track, kept below the
/// end. An unknown length needs the time rule, or four minutes without one.
Duration listenRequiredFor(
  Duration? length, [
  ListenRule rule = ListenRule.standard,
]) {
  final after = rule.afterMs > 0 ? Duration(milliseconds: rule.afterMs) : null;
  if (length == null) return after ?? listenMaxRequired;
  final share = Duration(
    microseconds: length.inMicroseconds * rule.percent ~/ 100,
  );
  final wanted = after != null && after < share ? after : share;
  final reachable = length - listenEndSlack;
  return wanted < reachable ? wanted : reachable;
}

/// Whether [listened] makes a listen of a track [length] long: the track is
/// longer than 30 s and was heard for [listenRequiredFor] it.
bool qualifiesAsListen(
  Duration listened,
  Duration? length, [
  ListenRule rule = ListenRule.standard,
]) {
  if (length != null && length <= listenMinTrackLength) return false;
  return listened >= listenRequiredFor(length, rule);
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

  /// Whether the listen counts now under the standard rule.
  bool get qualifies => qualifiesUnder(ListenRule.standard);

  /// Whether the listen counts now under [rule].
  bool qualifiesUnder(ListenRule rule) =>
      qualifiesAsListen(_listened, _length, rule);

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
