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

  /// Whole minutes that still fit under the 720 minute cap (changes once a
  /// minute, so the quick-add chips are not rebuilt every second).
  int roomMinutes,
  bool canRemoveTrack,
  bool canAddTrack,
});

_Controls _controlsOf(SleepTimerState s) => (
  mode: s.mode,
  held: s.countingPaused,
  canTakeMinutes: s.canSubtract(sleepMinutesRange.step),
  canAddMinutes: s.canAddMinutes,
  roomMinutes: s.mode == SleepTimerMode.minutes
      ? (const Duration(minutes: sleepTimerMaxMinutes) - s.remaining)
                .inSeconds ~/
            60
      : 0,
  canRemoveTrack: s.canRemoveTrack,
  canAddTrack: s.canAddTrack,
);

/// Under the progress bar: the quick-add chips and pause / resume (minutes
/// mode); nothing for the other modes (their − / + sit beside the clock, see
/// [sleepTimerStepButtons]). A focused − / + that turns off hands focus to its
/// pair; the pause and resume looks are one button with one focus node.
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
    if (c.mode != SleepTimerMode.minutes) return const SizedBox.shrink();
    final texts = SleepTimerTexts.of(context);
    final l10n = texts.l10n;
    final timer = ref.read(sleepTimerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickAdds(room: c.roomMinutes, onAdd: timer.addMinutes),
        const SizedBox(height: KSpace.x3),
        KModalButton(
          label: c.held
              ? l10n.sleepTimerResumeCounting
              : l10n.sleepTimerPauseCounting,
          emphasis: c.held ? KModalEmphasis.primary : KModalEmphasis.secondary,
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
  }
}

/// Minutes the quick-add chips give (the last one, 60, is "1 giờ").
const _quickAdds = [10, 15, 30, 60];

/// One line of chips; a chip that would pass the cap is off.
class _QuickAdds extends StatelessWidget {
  const _QuickAdds({required this.room, required this.onAdd});

  final int room;
  final void Function(int minutes) onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = SleepTimerTexts.of(context).l10n;
    return KChipLine(
      children: [
        for (final m in _quickAdds)
          Tooltip(
            message: m == 60
                ? l10n.sleepTimerAddHour
                : l10n.sleepTimerAddMinutes(m),
            excludeFromSemantics: true,
            child: KChip(
              dense: true,
              semanticLabel: m == 60
                  ? l10n.sleepTimerAddHour
                  : l10n.sleepTimerAddMinutes(m),
              enabled: m <= room,
              label: Text(
                m == 60
                    ? l10n.sleepTimerChipPlusHour
                    : l10n.sleepTimerChipPlusMinutes(m),
              ),
              onTap: m <= room ? () => onAdd(m) : null,
            ),
          ),
      ],
    );
  }
}
