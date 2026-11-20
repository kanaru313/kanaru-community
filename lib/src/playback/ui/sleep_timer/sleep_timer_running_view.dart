import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/sleep_estimates.dart';
import '../../state/sleep_timer_provider.dart';
import '../playback_time_label.dart';
import 'sleep_timer_announce.dart';
import 'sleep_timer_focus.dart';
import 'sleep_timer_parts.dart';
import 'sleep_timer_running_controls.dart';
import 'sleep_timer_step_buttons.dart';
import 'sleep_timer_texts.dart';

/// Third screen: the clock of the running timer, the buttons that adjust it
/// and "Tắt hẹn giờ" / "Đổi…". Nothing here talks every second: the clock is
/// seen, its status text for a screen reader is minute-precise and not live.
class SleepTimerRunningView extends ConsumerWidget {
  const SleepTimerRunningView({
    super.key,
    required this.focus,
    required this.announcer,
    required this.onOff,
    required this.onChange,
    this.frozen,
  });

  final SleepTimerFocus focus;
  final SleepTimerAnnouncer announcer;

  /// "Tắt hẹn giờ": cancels the timer and closes the modal.
  final VoidCallback onOff;
  final VoidCallback onChange;

  /// The state to show instead of the live one: the modal is closing, and
  /// the screen keeps its content while the route animates out.
  final SleepTimerState? frozen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texts = SleepTimerTexts.of(context);
    return Padding(
      padding: sleepTimerPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SleepTimerHeader(
            title: texts.l10n.playbackSleepTimer,
            icon: KIcons.sleepTimerActive,
          ),
          const SizedBox(height: KSpace.x3),
          RepaintBoundary(
            child: _RunningClock(focus: focus, frozen: frozen),
          ),
          const SizedBox(height: KSpace.x3),
          SleepTimerRunningControls(
            focus: focus,
            announcer: announcer,
            frozen: frozen,
          ),
          SleepTimerFooter(
            children: [
              KModalButton(
                label: texts.l10n.sleepTimerTurnOff,
                emphasis: KModalEmphasis.destructive,
                focusNode: focus.off,
                onPressed: onOff,
              ),
              KModalButton(
                label: texts.l10n.sleepTimerChange,
                emphasis: KModalEmphasis.tonal,
                focusNode: focus.change,
                onPressed: onChange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The clock with its − / + beside it, its bar and the row under it. A
/// consumer of its own: it is the part that follows the seconds.
class _RunningClock extends ConsumerWidget {
  const _RunningClock({required this.focus, this.frozen});

  final SleepTimerFocus focus;
  final SleepTimerState? frozen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SleepTimerState s = frozen ?? ref.watch(sleepTimerProvider);
    final mode = s.mode;
    if (mode == null) return const SizedBox.shrink();
    final texts = SleepTimerTexts.of(context);
    final l10n = texts.l10n;
    final status = texts.statusText(s, minutePrecision: true);
    final sides = sleepTimerStepButtons(
      context: context,
      timer: ref.read(sleepTimerProvider.notifier),
      s: s,
      focus: focus,
    );
    switch (mode) {
      case SleepTimerMode.minutes:
        final held = s.countingPaused;
        final set = s.setLength.inMicroseconds;
        final endsAt = s.endsAt;
        return KClockProgress(
          label: held ? l10n.sleepTimerLabelHeld : l10n.sleepTimerLabelSleepIn,
          bigText: formatClock(s.remaining),
          statusLabel: status,
          fraction: set <= 0 ? 0 : s.remaining.inMicroseconds / set,
          held: held,
          leading: sides?.leading,
          trailing: sides?.trailing,
          endText: held
              ? l10n.sleepTimerRowHeld
              : (endsAt == null ? '' : texts.stopsAtTime(endsAt)),
        );
      case SleepTimerMode.tracks:
        final played = ref.watch(currentTrackPlayedProvider);
        final count = s.tracksAtStart > s.tracksLeft
            ? s.tracksAtStart
            : s.tracksLeft;
        final share = played == null || played.total <= 0
            ? 1.0
            : 1 - played.played / played.total;
        final last = s.tracksLeft <= 1;
        final of = l10n.sleepTimerRowTracksOf(s.tracksLeft, count);
        return KClockProgress(
          label: l10n.sleepTimerLabelPauseAfter,
          bigText: '${s.tracksLeft}',
          statusLabel: status,
          leading: sides?.leading,
          trailing: sides?.trailing,
          segments: (
            count: count,
            done: count - s.tracksLeft,
            currentFraction: share.clamp(0.0, 1.0),
          ),
          startText: l10n.sleepTimerRowCurrentCounts,
          endText: last ? '$of · ${l10n.sleepTimerRowLastTrack}' : of,
        );
      case SleepTimerMode.endOfTrack ||
          SleepTimerMode.endOfAlbum ||
          SleepTimerMode.endOfQueue:
        return _endOfClock(context, ref, s, texts, status);
    }
  }

  Widget _endOfClock(
    BuildContext context,
    WidgetRef ref,
    SleepTimerState s,
    SleepTimerTexts texts,
    String status,
  ) {
    final l10n = texts.l10n;
    final Duration? left;
    final String? leftText;
    final String word;
    switch (s.mode) {
      case SleepTimerMode.endOfTrack:
        final seconds = ref.watch(currentTrackLeftProvider);
        left = seconds == null ? null : Duration(seconds: seconds);
        leftText = left == null ? null : texts.leftTime(left);
        word = l10n.sleepTimerWordTrack;
      case SleepTimerMode.endOfAlbum:
        final run = ref.watch(albumRunProvider).value;
        left = ref.watch(albumLeftProvider);
        leftText = run == null
            ? null
            : texts.leftTracks(run.tracks, time: left, capped: run.capped);
        word = l10n.sleepTimerWordAlbum;
      default:
        final queue = ref.watch(queueLeftProvider);
        left = queue?.time;
        leftText = queue == null
            ? null
            : texts.leftTracks(queue.tracks, time: queue.time);
        word = l10n.sleepTimerWordQueue;
    }
    final startedAt = s.startedAt;
    return KClockProgress(
      label: l10n.sleepTimerLabelPauseAtEnd,
      bigText: word,
      statusLabel: status,
      // Nothing known yet: a full bar, not an empty one.
      fraction: left == null || startedAt == null
          ? 1
          : sleepEndOfFraction(
              left: left,
              startedAt: startedAt,
              now: DateTime.now(),
            ),
      startText: leftText,
      endText: l10n.sleepTimerRowQueueKept,
    );
  }
}
