import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../browse/library_list_scaffold.dart';
import 'history_labels.dart';
import 'history_line_metrics.dart';

/// The bar that starts a day: its name (Today, Yesterday, a weekday or
/// `dd/MM`) over `dd/MM/yyyy · plays · songs · time listened`, and the day's
/// ⋮ at the end. The pinned bar and the header line of every later day are
/// this widget at the same [height] (`HistoryLineMetrics.dayBar`), so the
/// swap between them is invisible.
///
/// Both lines are one line with an ellipsis; the whole text is the header's
/// semantics label, and a tooltip on desktop.
class HistoryDayBar extends StatelessWidget {
  const HistoryDayBar({
    super.key,
    required this.day,
    required this.today,
    required this.height,
  });

  final HistoryDay day;

  /// The local day the screen is on, for the name of the day.
  final DateTime today;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = historyDayLabel(l10n, day.start, today);
    final stats = historyDayStats(l10n, day);
    Widget text = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: HistoryLineMetrics.lineHeight,
          ),
        ),
        Text(
          stats,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: HistoryLineMetrics.lineHeight,
          ),
        ),
      ],
    );
    if (FormFactor.of(context) == FormFactor.desktop) {
      text = Tooltip(
        message: '$label · $stats',
        waitDuration: const Duration(milliseconds: 600),
        child: text,
      );
    }
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: libraryBarGutter(context)),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                label: '$label, $stats',
                excludeSemantics: true,
                child: text,
              ),
            ),
            // The day's menu is not wired yet: present, off.
            KIconButton(
              tooltip: l10n.historyDayMenuLabel(label),
              size: KIconSize.sm,
              padding: const EdgeInsets.all(KSpace.x2),
              onPressed: null,
              icon: KIcons.moreVert,
            ),
            SizedBox(width: libraryBarGutter(context) - KSpace.x2),
          ],
        ),
      ),
    );
  }
}
