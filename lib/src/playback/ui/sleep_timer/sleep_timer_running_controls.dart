import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/sleep_timer_provider.dart';
import 'sleep_timer_announce.dart';
import 'sleep_timer_draft.dart';
import 'sleep_timer_focus.dart';
import 'sleep_timer_texts.dart';

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
  canAddMinutes: s.canAddMinutes,
  canRemoveTrack: s.canRemoveTrack,
  canAddTrack: s.canAddTrack,
);

/// −5 / +5 and pause / resume (minutes), −1 / +1 (tracks), nothing for the
/// end-of modes. A focused button that turns off hands focus to its pair; the
/// pause and resume looks are one button with one focus node.
class SleepTimerRunningControls extends ConsumerWidget {
  const SleepTimerRunningControls({
    super.key,
    required this.focus,
    required this.announcer,
    this.frozen,
  });

  final SleepTimerFocus focus;
  final SleepTimerAnnouncer announcer;

  /// The state to show instead of the live one (the modal is closing).
  final SleepTimerState? frozen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = frozen;
    final c = snapshot != null
        ? _controlsOf(snapshot)
        : ref.watch(sleepTimerProvider.select(_controlsOf));
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
                  child: KModalButton(
                    label: l10n.sleepTimerButtonMinusMinutes(step),
                    semanticLabel: l10n.sleepTimerRemoveMinutes(step),
                    emphasis: KModalEmphasis.tonal,
                    prominent: true,
                    focusNode: focus.minus,
                    onPressed: c.canTakeMinutes
                        ? () => timer.addMinutes(-step)
                        : null,
                  ),
                ),
                const SizedBox(width: KSpace.x2),
                Expanded(
                  child: KModalButton(
                    label: l10n.sleepTimerButtonPlusMinutes(step),
                    semanticLabel: l10n.sleepTimerAddMinutes(step),
                    emphasis: KModalEmphasis.tonal,
                    prominent: true,
                    focusNode: focus.plus,
                    onPressed: c.canAddMinutes
                        ? () => timer.addMinutes(step)
                        : null,
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
              child: KModalButton(
                semanticLabel: l10n.sleepTimerRemoveTrack,
                label: l10n.sleepTimerButtonMinusTracks(sleepTracksRange.step),
                emphasis: KModalEmphasis.tonal,
                prominent: true,
                focusNode: focus.minus,
                onPressed: c.canRemoveTrack ? () => timer.addTracks(-1) : null,
              ),
            ),
            const SizedBox(width: KSpace.x2),
            Expanded(
              child: KModalButton(
                semanticLabel: l10n.sleepTimerAddTrack,
                label: l10n.sleepTimerButtonPlusTracks(sleepTracksRange.step),
                emphasis: KModalEmphasis.tonal,
                prominent: true,
                focusNode: focus.plus,
                onPressed: c.canAddTrack ? () => timer.addTracks(1) : null,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
