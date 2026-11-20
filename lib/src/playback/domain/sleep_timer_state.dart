/// When the sleep timer pauses playback.
enum SleepTimerMode {
  /// After a number of minutes, fading out over the last seconds.
  minutes,

  /// After a number of tracks (the current one included) played to their end.
  tracks,

  /// When the current track ends.
  endOfTrack,

  /// When the next track in play order belongs to another album, or none
  /// follows.
  endOfAlbum,

  /// When the last track in play order ends, whatever repeat says.
  endOfQueue,
}

/// Fewest and most minutes the minutes mode counts down from.
const sleepTimerMinMinutes = 1;
const sleepTimerMaxMinutes = 720;

/// Fewest and most tracks the tracks mode counts.
const sleepTimerMinTracks = 1;
const sleepTimerMaxTracks = 20;

const Object _keep = Object();

/// What the sleep timer shows. Session only: never saved.
class SleepTimerState {
  const SleepTimerState.off()
    : mode = null,
      remaining = Duration.zero,
      endsAt = null,
      countingPaused = false,
      tracksLeft = 0,
      setLength = Duration.zero,
      tracksAtStart = 0,
      startedAt = null,
      startSerial = 0;

  const SleepTimerState({
    required SleepTimerMode this.mode,
    this.remaining = Duration.zero,
    this.endsAt,
    this.countingPaused = false,
    this.tracksLeft = 0,
    this.setLength = Duration.zero,
    this.tracksAtStart = 0,
    this.startedAt,
    this.startSerial = 0,
  });

  /// `null` while the timer is off.
  final SleepTimerMode? mode;

  /// Time left in the minutes mode, in whole seconds rounded up; zero in the
  /// other modes.
  final Duration remaining;

  /// Wall-clock time the minutes mode stops at; null in the other modes and
  /// while the count is on hold.
  final DateTime? endsAt;

  /// The minutes countdown is on hold (only in the minutes mode).
  final bool countingPaused;

  /// Tracks still to finish, the current one included, in the tracks mode;
  /// zero in the other modes.
  final int tracksLeft;

  /// What the user set in the minutes mode; raised when "+5" pushes the time
  /// left above it, so a bar of time left over [setLength] never passes full.
  /// Zero in the other modes.
  final Duration setLength;

  /// Tracks set in the tracks mode; raised when "+1" pushes the count above
  /// it. Zero in the other modes.
  final int tracksAtStart;

  /// Wall-clock time of the start (the controller's clock, as [endsAt]); the
  /// end-of modes measure their bar from it. Null while the timer is off.
  final DateTime? startedAt;

  /// Counts the starts of the session: a start while running (or after an
  /// end) gives a new value, hold, resume and adds do not. Zero while off.
  final int startSerial;

  bool get active => mode != null;

  /// Whether taking [minutes] off still leaves time: subtracting is refused
  /// once no more than that is left, so it never turns the timer off.
  bool canSubtract(int minutes) =>
      mode == SleepTimerMode.minutes && remaining > Duration(minutes: minutes);

  bool get canRemoveTrack => mode == SleepTimerMode.tracks && tracksLeft > 1;

  bool get canAddTrack =>
      mode == SleepTimerMode.tracks && tracksLeft < sleepTimerMaxTracks;

  /// A copy with the given fields replaced. [endsAt] and [startedAt] may be
  /// set to null.
  SleepTimerState copyWith({
    SleepTimerMode? mode,
    Duration? remaining,
    Object? endsAt = _keep,
    bool? countingPaused,
    int? tracksLeft,
    Duration? setLength,
    int? tracksAtStart,
    Object? startedAt = _keep,
    int? startSerial,
  }) => SleepTimerState(
    mode: mode ?? this.mode!,
    remaining: remaining ?? this.remaining,
    endsAt: identical(endsAt, _keep) ? this.endsAt : endsAt as DateTime?,
    countingPaused: countingPaused ?? this.countingPaused,
    tracksLeft: tracksLeft ?? this.tracksLeft,
    setLength: setLength ?? this.setLength,
    tracksAtStart: tracksAtStart ?? this.tracksAtStart,
    startedAt: identical(startedAt, _keep)
        ? this.startedAt
        : startedAt as DateTime?,
    startSerial: startSerial ?? this.startSerial,
  );

  @override
  bool operator ==(Object other) =>
      other is SleepTimerState &&
      other.mode == mode &&
      other.remaining == remaining &&
      other.endsAt == endsAt &&
      other.countingPaused == countingPaused &&
      other.tracksLeft == tracksLeft &&
      other.setLength == setLength &&
      other.tracksAtStart == tracksAtStart &&
      other.startedAt == startedAt &&
      other.startSerial == startSerial;

  @override
  int get hashCode => Object.hash(
    mode,
    remaining,
    endsAt,
    countingPaused,
    tracksLeft,
    setLength,
    tracksAtStart,
    startedAt,
    startSerial,
  );

  @override
  String toString() =>
      'SleepTimerState($mode, $remaining'
      '${endsAt == null ? '' : ', ends $endsAt'}'
      '${countingPaused ? ', held' : ''}'
      '${tracksLeft > 0 ? ', $tracksLeft tracks' : ''})';
}

/// How much of an end-of mode's bar is left: the time still to go over the
/// time since [startedAt] plus the time still to go, so a queue edit that
/// grows [left] widens the bar instead of overflowing it. Clamped to 0..1;
/// 0 when there is nothing to divide by (a clock that went back included).
double sleepEndOfFraction({
  required Duration left,
  required DateTime startedAt,
  required DateTime now,
}) {
  if (left <= Duration.zero) return 0;
  final elapsed = now.difference(startedAt);
  final total = (elapsed.isNegative ? Duration.zero : elapsed) + left;
  if (total <= Duration.zero) return 0;
  return (left.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
}
