import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/history/local_day_provider.dart';
import '../../state/history/most_played_selection.dart';
import '../browse/library_list_scaffold.dart';
import 'most_played_labels.dart';
import 'most_played_limit_picker.dart';

/// Under the chips: `‹` the period `›` and the **Top N ▾** chip that opens the
/// number picker.
///
/// The arrows step a whole period back or forward (a custom range moves by its
/// own length); the forward one is off once the period reaches today, and all
/// time has neither. Today is the local day of [localDayProvider], so a page
/// left open overnight follows.
class MostPlayedPeriodRow extends ConsumerStatefulWidget {
  const MostPlayedPeriodRow({super.key});

  @override
  ConsumerState<MostPlayedPeriodRow> createState() =>
      _MostPlayedPeriodRowState();
}

class _MostPlayedPeriodRowState extends ConsumerState<MostPlayedPeriodRow> {
  /// Anchors the number picker's panel on desktop.
  final _anchor = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final range = ref.watch(mostPlayedRangeProvider);
    final limit = ref.watch(mostPlayedLimitProvider);
    final today = ref.watch(localDayProvider);
    final notifier = ref.read(mostPlayedRangeProvider.notifier);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: libraryBarGutter(context) - KSpace.x2,
        end: libraryBarGutter(context),
        bottom: KSpace.x1,
      ),
      // Wraps when large text leaves no room side by side: the Top N chip
      // goes under the period.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (range.canPrevious)
                KIconButton(
                  tooltip: l10n.historyMostPlayedPrevious,
                  icon: KIcons.chevronLeft,
                  size: KIconSize.sm,
                  padding: const EdgeInsets.all(KSpace.x2),
                  onPressed: () => notifier.set(range.previous()),
                )
              else
                const SizedBox(width: KSpace.x2),
              Flexible(
                child: Text(
                  mostPlayedPeriodText(l10n, range, today),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (range.canPrevious)
                KIconButton(
                  tooltip: l10n.historyMostPlayedNext,
                  icon: KIcons.chevronRight,
                  size: KIconSize.sm,
                  padding: const EdgeInsets.all(KSpace.x2),
                  onPressed: range.canNext(today)
                      ? () => notifier.set(range.next())
                      : null,
                ),
            ],
          ),
          KeyedSubtree(
            key: _anchor,
            child: KChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.historyMostPlayedTop(limit)),
                  const SizedBox(width: KSpace.x1),
                  const Icon(KIcons.collapse, size: KIconSize.xs),
                ],
              ),
              onTap: () => unawaited(
                chooseMostPlayedLimit(context, ref, anchor: _anchor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
