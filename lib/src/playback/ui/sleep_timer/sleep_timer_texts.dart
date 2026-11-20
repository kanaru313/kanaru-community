import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/sleep_timer_state.dart';
import '../../state/sleep_estimates.dart';
import '../playback_time_label.dart';

/// Every text of the sleep timer screens and entries, from l10n. Two kinds of
/// time: what is shown counts seconds ([formatClock]); what a screen reader
/// reads uses minutes rounded up ("24 phút"), so nothing talks every second.
class SleepTimerTexts {
  const SleepTimerTexts(this.l10n, this.clockAt);

  /// Texts for [context]: the app's language, and wall-clock times in the
  /// device's 12 / 24 hour format.
  factory SleepTimerTexts.of(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    return SleepTimerTexts(
      AppLocalizations.of(context),
      (t) => material.formatTimeOfDay(
        TimeOfDay.fromDateTime(t),
        alwaysUse24HourFormat: use24,
      ),
    );
  }

  final AppLocalizations l10n;

  /// A wall-clock time as the device shows it ("23:40" / "11:40 PM").
  final String Function(DateTime) clockAt;

  // ---- durations ----

  /// "15 phút" · "1 giờ" · "1 giờ 30" (tiles, chip tooltips).
  String minutesLabel(int m) => m < 60
      ? l10n.sleepTimerMinutes(m)
      : m % 60 == 0
      ? l10n.sleepTimerHours(m ~/ 60)
      : l10n.sleepTimerHoursMinutesShort(m ~/ 60, m % 60);

  /// "15 ph" · "1 giờ" · "1 giờ 30" (chips).
  String chipLabel(int m) =>
      m < 60 ? l10n.sleepTimerChipMinutes(m) : minutesLabel(m);

  /// "15 phút" · "1 giờ" · "1 giờ 30 phút" (sentences).
  String durationWords(int m) => m < 60
      ? l10n.sleepTimerMinutes(m)
      : m % 60 == 0
      ? l10n.sleepTimerHours(m ~/ 60)
      : l10n.sleepTimerHoursMinutes(m ~/ 60, m % 60);

  /// Unit under the big number: "phút", or "phút · 1 giờ 30 phút" from one
  /// hour.
  String unitMinutes(int value) => value < 60
      ? l10n.sleepTimerUnitMinutes
      : l10n.sleepTimerUnitMinutesWords(durationWords(value));

  String unitTracks(int count) => l10n.sleepTimerUnitTracks(count);

  // ---- wall-clock texts ----

  String tileUntil(DateTime now, int minutes) =>
      l10n.sleepTimerTileUntil(clockAt(now.add(Duration(minutes: minutes))));

  /// Label of a start tile: "Bắt đầu 15 phút, dừng lúc 23:40".
  String tileStartLabel(DateTime now, int minutes) =>
      l10n.sleepTimerTileStartLabel(
        durationWords(minutes),
        clockAt(now.add(Duration(minutes: minutes))),
      );

  /// "Dừng lúc 23:40" for a timer of [minutes] started at [now].
  String stopsAt(DateTime now, int minutes) =>
      l10n.sleepTimerStopsAt(clockAt(now.add(Duration(minutes: minutes))));

  String stopsAtTime(DateTime at) => l10n.sleepTimerStopsAt(clockAt(at));

  String stopsAfterTracks(int count) => l10n.sleepTimerStopsAfterTracks(count);

  // ---- "còn …" of the end-of rows ----

  String leftTime(Duration d) => l10n.sleepTimerLeftTime(formatClock(d));

  /// "còn 4 bài", "còn 7 bài · 29 phút" (with [time]), "còn 100+ bài"
  /// ([capped]: the count is a floor, no time).
  String leftTracks(int count, {Duration? time, bool capped = false}) {
    if (capped) return l10n.sleepTimerLeftTracksCapped(count);
    if (time == null) return l10n.sleepTimerLeftTracks(count);
    return l10n.sleepTimerLeftTracksDuration(
      count,
      durationWords(_ceilMinutes(time)),
    );
  }

  /// The end-of-album line of a run: the track count, or under repeat one
  /// "Đang lặp một bài · dừng sau bài này".
  String albumRunLine(AlbumRun run, {Duration? time}) => run.repeatsOne
      ? l10n.sleepTimerRepeatOneStops
      : leftTracks(run.tracks, time: time, capped: run.capped);

  // ---- running state ----

  static int _ceilMinutes(Duration d) => (d.inSeconds + 59) ~/ 60;

  String endOfLabel(SleepTimerMode mode) => switch (mode) {
    SleepTimerMode.endOfTrack => l10n.sleepTimerEndOfTrack,
    SleepTimerMode.endOfAlbum => l10n.sleepTimerEndOfAlbum,
    _ => l10n.sleepTimerEndOfQueue,
  };

  /// What the pill or ring label shows: "23:41", "3 bài", "Bài" / "Album" /
  /// "Hàng đợi".
  String pillLabel(SleepTimerState s) => switch (s.mode) {
    SleepTimerMode.minutes => formatClock(s.remaining),
    SleepTimerMode.tracks => l10n.sleepTimerTracksCount(s.tracksLeft),
    SleepTimerMode.endOfTrack => l10n.sleepTimerPillTrack,
    SleepTimerMode.endOfAlbum => l10n.sleepTimerPillAlbum,
    SleepTimerMode.endOfQueue => l10n.sleepTimerPillQueue,
    null => '',
  };

  /// Status of a running timer: "Ngủ sau 23:41" (seconds), or with
  /// [minutePrecision] "Ngủ sau 24 phút" (the node the screen reader reads).
  String statusText(SleepTimerState s, {bool minutePrecision = false}) {
    final left = minutePrecision
        ? durationWords(_ceilMinutes(s.remaining))
        : formatClock(s.remaining);
    return switch (s.mode) {
      SleepTimerMode.minutes =>
        s.countingPaused
            ? l10n.sleepTimerStatusHeld(left)
            : l10n.sleepTimerStatusMinutes(left),
      SleepTimerMode.tracks => l10n.sleepTimerStatusTracks(s.tracksLeft),
      SleepTimerMode.endOfTrack => l10n.sleepTimerStatusEndTrack,
      SleepTimerMode.endOfAlbum => l10n.sleepTimerStatusEndAlbum,
      SleepTimerMode.endOfQueue => l10n.sleepTimerStatusEndQueue,
      null => '',
    };
  }

  String _entryPart(SleepTimerState s, bool minutePrecision) =>
      switch (s.mode) {
        SleepTimerMode.minutes => l10n.sleepTimerLeftTime(
          minutePrecision
              ? durationWords(_ceilMinutes(s.remaining))
              : formatClock(s.remaining),
        ),
        SleepTimerMode.tracks => l10n.sleepTimerLeftTracks(s.tracksLeft),
        SleepTimerMode.endOfTrack => l10n.sleepTimerEntryEndTrack,
        SleepTimerMode.endOfAlbum => l10n.sleepTimerEntryEndAlbum,
        SleepTimerMode.endOfQueue => l10n.sleepTimerEntryEndQueue,
        null => '',
      };

  /// Tooltip / label of an entry button: "Hẹn giờ ngủ" while off, else
  /// "Hẹn giờ ngủ: còn 23:41" (with [minutePrecision] "còn 24 phút"), plus
  /// "(tạm dừng đếm)" while the count is held.
  String entryLabel(SleepTimerState s, {bool minutePrecision = false}) {
    if (!s.active) return l10n.playbackSleepTimer;
    final text = l10n.sleepTimerEntryRunning(_entryPart(s, minutePrecision));
    return s.countingPaused ? '$text ${l10n.sleepTimerHeldSuffix}' : text;
  }

  /// Desktop tooltip of a running timer: "Hẹn giờ ngủ: Ngủ sau 23:41".
  String entryStatusTooltip(SleepTimerState s) => s.active
      ? l10n.sleepTimerEntryRunning(statusText(s))
      : l10n.playbackSleepTimer;

  /// Label of the ⋮ item: "Hẹn giờ ngủ · còn 23:41".
  String menuLabel(SleepTimerState s, {bool minutePrecision = false}) =>
      s.active
      ? l10n.sleepTimerMenuRunning(_entryPart(s, minutePrecision))
      : l10n.playbackSleepTimer;
}
