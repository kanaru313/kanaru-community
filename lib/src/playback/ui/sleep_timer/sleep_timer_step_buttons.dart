import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/sleep_timer_provider.dart';
import 'sleep_timer_draft.dart';
import 'sleep_timer_focus.dart';
import 'sleep_timer_texts.dart';

/// The round −5 / +5 (minutes) or −1 / +1 (tracks) buttons on both sides of
/// the big number of the running screen; null for the end-of-modes, which have
/// none. Enabled by what [s] allows; the focus nodes are the modal's, so a
/// focused button can hand focus to its pair when it turns off.
({Widget leading, Widget trailing})? sleepTimerStepButtons({
  required BuildContext context,
  required SleepTimer timer,
  required SleepTimerState s,
  required SleepTimerFocus focus,
}) {
  final l10n = SleepTimerTexts.of(context).l10n;
  switch (s.mode) {
    case SleepTimerMode.minutes:
      final step = sleepMinutesRange.step;
      // − is −5, and −1 once 5 minutes or less are left; same focus node.
      final minus = s.minusMinutes;
      return (
        leading: KStepButton.text(
          label: l10n.sleepTimerStepMinus(minus),
          semanticLabel: minus == 1
              ? l10n.sleepTimerRemoveOneMinute
              : l10n.sleepTimerRemoveMinutes(minus),
          focusNode: focus.minus,
          onPressed: s.canSubtract(minus)
              ? () => timer.addMinutes(-minus)
              : null,
        ),
        trailing: KStepButton.text(
          label: l10n.sleepTimerStepPlus(step),
          semanticLabel: l10n.sleepTimerAddMinutes(step),
          focusNode: focus.plus,
          onPressed: s.canAddMinutes ? () => timer.addMinutes(step) : null,
        ),
      );
    case SleepTimerMode.tracks:
      final step = sleepTracksRange.step;
      return (
        leading: KStepButton.text(
          label: l10n.sleepTimerStepMinus(step),
          semanticLabel: l10n.sleepTimerRemoveTrack,
          focusNode: focus.minus,
          onPressed: s.canRemoveTrack ? () => timer.addTracks(-step) : null,
        ),
        trailing: KStepButton.text(
          label: l10n.sleepTimerStepPlus(step),
          semanticLabel: l10n.sleepTimerAddTrack,
          focusNode: focus.plus,
          onPressed: s.canAddTrack ? () => timer.addTracks(step) : null,
        ),
      );
    default:
      return null;
  }
}
