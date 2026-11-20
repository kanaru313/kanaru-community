import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/sleep_estimates.dart';
import '../../state/sleep_timer_provider.dart';
import '../playback_time_label.dart';
import 'sleep_timer_announce.dart';
import 'sleep_timer_draft.dart';
import 'sleep_timer_focus.dart';
import 'sleep_timer_parts.dart';
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
  });

  final SleepTimerFocus focus;
  final SleepTimerAnnouncer announcer;

  /// "Tắt hẹn giờ": cancels the timer and closes the modal.
  final VoidCallback onOff;
  final VoidCallback onChange;

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
          const RepaintBoundary(child: _RunningClock()),
          const SizedBox(height: KSpace.x3),
          _RunningControls(focus: focus, announcer: announcer),
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

/// The clock, its bar and the row under it. A consumer of its own: it is the
/// part that follows the seconds.
class _RunningClock extends ConsumerWidget {
  const _RunningClock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sleepTimerProvider);
    final mode = s.mode;
    if (mode == null) return const SizedBox.shrink();
    final texts = SleepTimerTexts.of(context);
    final l10n = texts.l10n;
    final status = texts.statusText(s, minutePrecision: true);
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
          startText: l10n.sleepTimerRowSet(
            texts.durationWords(s.setLength.inMinutes),
          ),
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

/// What the buttons need to know; equal values do not rebuild them.
typedef _Controls = ({
  SleepTimerMode? mode,
  bool held,
  bool canTakeMinutes,
  bool canAddMinutes,
  bool canRemoveTrack,
  bool canAddTrack,
});

_Controls _controlsOf(SleepTimerState s) => (
  mode: s.mode,
  held: s.countingPaused,
  canTakeMinutes: s.canSubtract(sleepMinutesRange.step),
  canAddMinutes: s.remaining < const Duration(minutes: sleepTimerMaxMinutes),
  canRemoveTrack: s.canRemoveTrack,
  canAddTrack: s.canAddTrack,
);

/// −5 / +5 and pause / resume (minutes), −1 / +1 (tracks), nothing for the
/// end-of modes. A focused button that turns off hands focus to its pair; the
/// pause and resume looks are one button with one focus node.
class _RunningControls extends ConsumerWidget {
  const _RunningControls({required this.focus, required this.announcer});

  final SleepTimerFocus focus;
  final SleepTimerAnnouncer announcer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(sleepTimerProvider.select(_controlsOf));
    ref.listen(sleepTimerProvider.select(_controlsOf), (prev, next) {
      if (prev == null) return;
      void handOver(bool was, bool now, FocusNode off, FocusNode pair) {
        if (was && !now && off.hasFocus) pair.requestFocus();
      }

      handOver(
        prev.canTakeMinutes,
        next.canTakeMinutes,
        focus.minus,
        focus.plus,
      );
      handOver(prev.canAddMinutes, next.canAddMinutes, focus.plus, focus.minus);
      handOver(
        prev.canRemoveTrack,
        next.canRemoveTrack,
        focus.minus,
        focus.plus,
      );
      handOver(prev.canAddTrack, next.canAddTrack, focus.plus, focus.minus);
    });
    final texts = SleepTimerTexts.of(context);
    final l10n = texts.l10n;
    final timer = ref.read(sleepTimerProvider.notifier);
    final step = sleepMinutesRange.step;
    switch (c.mode) {
      case SleepTimerMode.minutes:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: l10n.sleepTimerRemoveMinutes(step),
                    child: KModalButton(
                      label: l10n.sleepTimerButtonMinusMinutes(step),
                      emphasis: KModalEmphasis.tonal,
                      prominent: true,
                      focusNode: focus.minus,
                      onPressed: c.canTakeMinutes
                          ? () => timer.addMinutes(-step)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: KSpace.x2),
                Expanded(
                  child: Tooltip(
                    message: l10n.sleepTimerAddMinutes(step),
                    child: KModalButton(
                      label: l10n.sleepTimerButtonPlusMinutes(step),
                      emphasis: KModalEmphasis.tonal,
                      prominent: true,
                      focusNode: focus.plus,
                      onPressed: c.canAddMinutes
                          ? () => timer.addMinutes(step)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KSpace.x2),
            KModalButton(
              label: c.held
                  ? l10n.sleepTimerResumeCounting
                  : l10n.sleepTimerPauseCounting,
              emphasis: c.held
                  ? KModalEmphasis.primary
                  : KModalEmphasis.secondary,
              icon: c.held ? KIcons.play : KIcons.pause,
              focusNode: focus.pause,
              onPressed: () {
                if (c.held) {
                  timer.resumeCounting();
                  announcer.say(texts.announceResumed);
                } else {
                  timer.pauseCounting();
                  announcer.say(texts.announceHeld);
                }
              },
            ),
          ],
        );
      case SleepTimerMode.tracks:
        return Row(
          children: [
            Expanded(
              child: Tooltip(
                message: l10n.sleepTimerRemoveTrack,
                child: KModalButton(
                  label: l10n.sleepTimerButtonMinusTracks(
                    sleepTracksRange.step,
                  ),
                  emphasis: KModalEmphasis.tonal,
                  prominent: true,
                  focusNode: focus.minus,
                  onPressed: c.canRemoveTrack
                      ? () => timer.addTracks(-1)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: KSpace.x2),
            Expanded(
              child: Tooltip(
                message: l10n.sleepTimerAddTrack,
                child: KModalButton(
                  label: l10n.sleepTimerButtonPlusTracks(sleepTracksRange.step),
                  emphasis: KModalEmphasis.tonal,
                  prominent: true,
                  focusNode: focus.plus,
                  onPressed: c.canAddTrack ? () => timer.addTracks(1) : null,
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
