import '../../state/sleep_timer_provider.dart';

/// What the custom screen sets: minutes or a number of tracks.
enum SleepTimerKind { minutes, tracks }

/// Limits, steps and quick choices of one [SleepTimerKind]. The only place
/// the numbers live: the field, buttons, ruler and chips all read them here.
class SleepTimerRange {
  const SleepTimerRange({
    required this.min,
    required this.max,
    required this.rulerMax,
    required this.step,
    required this.defaultValue,
    required this.presets,
    this.rulerMajorEvery = 5,
    this.rulerLabelEvery = 15,
  });

  /// Fewest and most a typed number can be.
  final int min;
  final int max;

  /// The ruler runs from [min] to this; a larger typed number leaves it at
  /// the end.
  final int rulerMax;

  /// Ruler ticks: a taller one every [rulerMajorEvery] units, a number every
  /// [rulerLabelEvery].
  final int rulerMajorEvery;
  final int rulerLabelEvery;

  /// Amount of the − / + buttons.
  final int step;
  final int defaultValue;

  /// Quick choices: the chips of the custom screen (and, for minutes, the
  /// tiles of the first screen).
  final List<int> presets;

  int clamp(int value) => value < min ? min : (value > max ? max : value);
}

const sleepMinutesRange = SleepTimerRange(
  min: sleepTimerMinMinutes,
  max: sleepTimerMaxMinutes,
  rulerMax: 180,
  step: 5,
  defaultValue: 45,
  presets: [15, 30, 45, 60, 90],
);

const sleepTracksRange = SleepTimerRange(
  min: sleepTimerMinTracks,
  max: sleepTimerMaxTracks,
  rulerMax: sleepTimerMaxTracks,
  rulerLabelEvery: 1,
  step: 1,
  defaultValue: 3,
  presets: [1, 2, 3, 5, 10],
);

SleepTimerRange sleepRangeOf(SleepTimerKind kind) =>
    kind == SleepTimerKind.tracks ? sleepTracksRange : sleepMinutesRange;

/// First code point of each block of ten decimal digits that typed text may
/// use (ASCII, Arabic-Indic, Indic scripts, Thai, Lao, Tibetan, Myanmar,
/// Khmer, Mongolian, full-width). Other characters are dropped.
const _digitBlocks = <int>[
  0x0030, 0x0660, 0x06F0, 0x07C0, 0x0966, 0x09E6, 0x0A66, 0x0AE6, //
  0x0B66, 0x0BE6, 0x0C66, 0x0CE6, 0x0D66, 0x0E50, 0x0ED0, 0x0F20,
  0x1040, 0x17E0, 0x1810, 0xFF10,
];

/// The digits of [raw] as ASCII, every other character dropped
/// ("１２０" → "120", "45 phút" → "45", "-5" → "5").
String asciiDigitsOf(String raw) {
  final out = StringBuffer();
  for (final c in raw.runes) {
    for (final zero in _digitBlocks) {
      if (c >= zero && c <= zero + 9) {
        out.writeCharCode(0x30 + (c - zero));
        break;
      }
    }
  }
  return out.toString();
}

/// The number [raw] means for [range], or null when it is not a value (empty
/// or zero). It clamps the whole number before anything is cut, so a pasted
/// "1000" is the maximum, not "100".
int? parseTypedNumber(String raw, SleepTimerRange range) {
  final digits = asciiDigitsOf(raw).replaceFirst(RegExp('^0+'), '');
  if (digits.isEmpty) return null;
  // More digits than any int the range could hold is above the maximum.
  final value = digits.length > 9 ? range.max : int.parse(digits);
  return range.clamp(value);
}

/// What the user has chosen on the custom screen and not started. Pure: the
/// field, buttons, ruler and chips all go through it.
class SleepTimerDraft {
  const SleepTimerDraft({
    this.kind = SleepTimerKind.minutes,
    this.minutes = 45,
    this.tracks = 3,
  });

  /// Starts from the running timer ("Đổi…"): minutes rounded up to whole
  /// minutes, tracks as they are left. Other modes (and off) give the
  /// defaults.
  factory SleepTimerDraft.fromState(SleepTimerState state) {
    switch (state.mode) {
      case SleepTimerMode.minutes:
        final seconds = state.remaining.inSeconds;
        return SleepTimerDraft(
          minutes: sleepMinutesRange.clamp((seconds + 59) ~/ 60),
        );
      case SleepTimerMode.tracks:
        return SleepTimerDraft(
          kind: SleepTimerKind.tracks,
          tracks: sleepTracksRange.clamp(state.tracksLeft),
        );
      case _:
        return const SleepTimerDraft();
    }
  }

  final SleepTimerKind kind;
  final int minutes;
  final int tracks;

  SleepTimerRange get range => sleepRangeOf(kind);
  int get value => kind == SleepTimerKind.tracks ? tracks : minutes;

  bool get canStepDown => value > range.min;
  bool get canStepUp => value < range.max;

  /// The value the ruler shows: kept inside the ruler, so a typed 240 stays
  /// the draft's value while the ruler waits at its end.
  int get rulerValue =>
      value > range.rulerMax ? range.rulerMax : value; // min is the ruler's

  /// The chip to light: the one equal to the value, if any.
  int? get matchingPreset => range.presets.contains(value) ? value : null;

  SleepTimerDraft withKind(SleepTimerKind next) =>
      SleepTimerDraft(kind: next, minutes: minutes, tracks: tracks);

  /// Sets the current kind's number, kept within its range (chips, ruler).
  SleepTimerDraft withValue(int number) {
    final kept = range.clamp(number);
    return kind == SleepTimerKind.tracks
        ? SleepTimerDraft(kind: kind, minutes: minutes, tracks: kept)
        : SleepTimerDraft(kind: kind, minutes: kept, tracks: tracks);
  }

  /// Text typed or pasted: not a value (empty, zero) keeps the last valid
  /// number; anything else is cleaned and clamped ([parseTypedNumber]).
  SleepTimerDraft withTyped(String raw) {
    final typed = parseTypedNumber(raw, range);
    return typed == null ? this : withValue(typed);
  }

  /// The − (`-1`) or + (`1`) button: one step from the current value (an
  /// off-step 24 goes to 29), kept within the range.
  SleepTimerDraft stepped(int direction) =>
      withValue(value + direction * range.step);

  /// Starts the timer the draft describes, replacing a running one.
  void startOn(SleepTimer timer) {
    switch (kind) {
      case SleepTimerKind.minutes:
        timer.startMinutes(minutes);
      case SleepTimerKind.tracks:
        timer.startTracks(tracks);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SleepTimerDraft &&
      other.kind == kind &&
      other.minutes == minutes &&
      other.tracks == tracks;

  @override
  int get hashCode => Object.hash(kind, minutes, tracks);
}
