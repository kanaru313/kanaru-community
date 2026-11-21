import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_ranges.dart';
import '../../state/history/most_played_selection.dart';
import 'most_played_limit_dialog.dart';

/// Value of the picker's last row: "Tuỳ chọn…" (0 is never a valid number of
/// songs).
const _custom = 0;

/// Opens the Top N picker (a dropdown under [anchor] on both shells): Top 5 /
/// 10 / 50 / 100 and Tuỳ chọn… for any number from 1 to 1000. A number outside the presets selects Tuỳ chọn… and shows itself in
/// its subtitle. Choosing a preset sets it; choosing Tuỳ chọn… closes the
/// picker and opens the number dialog, whose Huỷ keeps the old number and does
/// not bring the picker back.
Future<void> chooseMostPlayedLimit(
  BuildContext context,
  WidgetRef ref, {
  required GlobalKey anchor,
}) async {
  final l10n = AppLocalizations.of(context);
  final current = ref.read(mostPlayedLimitProvider);
  final custom = !mostPlayedLimitPresets.contains(current);
  final picked = await showSelectionPicker<int>(
    context,
    anchor: anchor,
    presentation: SelectionPickerPresentation.anchored,
    selected: custom ? _custom : current,
    options: [
      for (final n in mostPlayedLimitPresets)
        SelectionOption(value: n, title: Text(l10n.historyMostPlayedTop(n))),
      SelectionOption(
        value: _custom,
        title: Text(l10n.historyMostPlayedLimitCustom),
        subtitle: Text(
          custom
              ? l10n.historyMostPlayedLimitCustomValue(current)
              : l10n.historyMostPlayedLimitHint,
        ),
      ),
    ],
  );
  if (picked == null || !context.mounted) return;
  if (picked != _custom) {
    ref.read(mostPlayedLimitProvider.notifier).set(picked);
    return;
  }
  final typed = await showMostPlayedLimitDialog(context, initial: current);
  // The page may have closed while the dialog was open: its ref is dead.
  if (typed == null || !context.mounted) return;
  ref.read(mostPlayedLimitProvider.notifier).set(typed);
}
