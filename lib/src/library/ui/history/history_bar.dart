import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../browse/library_list_scaffold.dart';

/// Above the timeline: `2026 · N plays` with the jump-to-date and filter
/// buttons at the end, then one chip per year that has plays (newest first,
/// the shown one selected).
///
/// [onJump] / [onFilter] null leave a button off. While the filter is open
/// ([filterOpen]) its button is pressed and [filterField] sits between the
/// count line and the chips.
class HistoryBar extends StatelessWidget {
  const HistoryBar({
    super.key,
    required this.years,
    required this.year,
    required this.plays,
    required this.onYear,
    this.onJump,
    this.onFilter,
    this.filterOpen = false,
    this.filterField,
  });

  /// Years with plays, newest first.
  final List<int> years;
  final int year;

  /// Plays of [year]; null while that year is being read.
  final int? plays;
  final ValueChanged<int> onYear;
  final VoidCallback? onJump;
  final VoidCallback? onFilter;
  final bool filterOpen;

  /// The filter's text field, shown while [filterOpen].
  final Widget? filterField;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gutter = libraryBarGutter(context);
    final count = plays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: gutter,
            end: libraryRowGutter(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  count == null
                      ? '$year'
                      : l10n.historyBarCount('$year', count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              KIconButton(
                tooltip: l10n.historyJumpToDay,
                size: KIconSize.sm,
                padding: const EdgeInsets.all(KSpace.x2),
                onPressed: onJump,
                icon: KIcons.dateAdded,
              ),
              KIconButton(
                tooltip: l10n.libraryFilter,
                size: KIconSize.sm,
                padding: const EdgeInsets.all(KSpace.x2),
                onPressed: onFilter,
                selected: filterOpen,
                icon: KIcons.filter,
              ),
            ],
          ),
        ),
        if (filterOpen && filterField != null)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              KSpace.x1,
              libraryRowGutter(context),
              KSpace.x1,
            ),
            child: filterField,
          ),
        Semantics(
          container: true,
          label: l10n.historyYearsLabel,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              KSpace.x1,
              gutter,
              KSpace.x3,
            ),
            child: Row(
              children: [
                for (final y in years) ...[
                  KChip(
                    label: Text('$y'),
                    selected: y == year,
                    onTap: () => onYear(y),
                  ),
                  const SizedBox(width: KSpace.x2),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
