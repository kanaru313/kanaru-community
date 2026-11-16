import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/sort_order.dart';
import 'library_labels.dart';
import 'list_sort_dialog.dart';

/// Opens the sort dropdown of [list] on [anchor]: "Nâng cao…" first, then the
/// criteria. A criterion makes the sort that one criterion alone, in the
/// direction of the first one now in use. "Nâng cao…" opens the multi-criteria
/// box ([openAdvancedSort]) once the dropdown has closed.
///
/// The sort in use is read through [read] and stored through [write]; [reset]
/// is what "Đặt lại" in the box does. List pages store the sort in the
/// remembered list views, detail pages per page. [read], [write] and [reset]
/// go through a `ProviderContainer` taken before opening, never the page's
/// `ref` (the box may outlive the page); [guard] closes the box with the page.
Future<void> openListSort(
  BuildContext context, {
  required BrowseList list,
  required GlobalKey anchor,
  required SortOrder Function() read,
  required Future<void> Function(SortOrder sort) write,
  required Future<void> Function() reset,
  ListSortGuard? guard,
}) async {
  final l10n = AppLocalizations.of(context);
  Route<dynamic>? route;
  final pick = await showKSortPopover<SortCriterion>(
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
    selected: normalizedSortOf(list, read()).primary.criterion,
    advancedLabel: l10n.librarySortAdvanced,
    onRoute: (r) {
      route = r;
      guard?.track(r);
    },
  );
  if (route != null) guard?.release(route!);
  switch (pick) {
    case KSortPicked<SortCriterion>(:final value):
      try {
        await write(normalizedSortOf(list, read()).pick(value));
      } on Object catch (e, s) {
        Logger('library.sort').warning('Could not store the sort', e, s);
      }
    case KSortAdvanced<SortCriterion>():
      if (!context.mounted) return;
      await openAdvancedSort(
        context,
        list: list,
        read: read,
        write: write,
        reset: reset,
        guard: guard,
      );
    case null:
      break;
  }
}
