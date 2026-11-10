import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import 'library_labels.dart';

/// Opens the sort popover of [list] on [anchor]. The sort in use is read
/// through [read] (again after every direction change, which keeps the
/// popover open) and stored through [write]; the list pages store it in the
/// remembered list views, the detail pages per page.
Future<void> openListSort(
  BuildContext context, {
  required BrowseList list,
  required GlobalKey anchor,
  required SortSpec Function() read,
  required Future<void> Function(SortSpec sort) write,
}) async {
  final l10n = AppLocalizations.of(context);
  final current = read();
  final numeric = current.criterion.isNumeric;
  final picked = await showKSortPopover<SortCriterion>(
    context,
    anchor: anchor,
    criteria: [
      for (final c in criteriaOf(list))
        KSortCriterion(
          value: c,
          label: sortCriterionLabel(l10n, c),
          icon: sortCriterionIcon(c),
        ),
    ],
    selected: current.criterion,
    ascending: !current.descending,
    ascendingLabel: numeric
        ? l10n.libraryOrderAscNumber
        : l10n.libraryOrderAscText,
    descendingLabel: numeric
        ? l10n.libraryOrderDescNumber
        : l10n.libraryOrderDescText,
    onAscendingChanged: (ascending) =>
        write(read().withDirection(descending: !ascending)),
  );
  if (picked == null) return;
  await write(SortSpec(picked, descending: read().descending));
}
