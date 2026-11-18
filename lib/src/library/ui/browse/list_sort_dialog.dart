import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/sort_order.dart';
import 'library_labels.dart';

final _log = Logger('library.sort');

/// What [openAdvancedSort] draws for [list] and [order]: the criteria the list
/// offers, and the order's entries. Both come from [criteriaOf] (the order is
/// repaired against it), so every entry has its option: the box skips an entry
/// without one and then counts drag indices over the drawn rows only.
typedef SortDialogModel = ({
  List<KSortOption<SortCriterion>> options,
  List<KSortEntry<SortCriterion>> chosen,
});

/// [order] repaired against what [list] offers.
SortOrder normalizedSortOf(BrowseList list, SortOrder order) =>
    SortOrder.normalized(
      order.specs,
      criteriaOf(list),
      fallback: defaultSortOf(list),
    );

/// Words of the two directions of a criterion of [kind] (ascending first).
({String ascending, String descending}) sortDirectionWords(
  AppLocalizations l10n,
  SortKind kind,
) => switch (kind) {
  SortKind.text => (
    ascending: l10n.libraryOrderAscText,
    descending: l10n.libraryOrderDescText,
  ),
  SortKind.number => (
    ascending: l10n.libraryOrderAscNumber,
    descending: l10n.libraryOrderDescNumber,
  ),
  SortKind.date => (
    ascending: l10n.libraryOrderOldFirst,
    descending: l10n.libraryOrderNewFirst,
  ),
  SortKind.position => (
    ascending: l10n.libraryOrderFirstToLast,
    descending: l10n.libraryOrderLastToFirst,
  ),
};

SortDialogModel sortDialogModel(
  AppLocalizations l10n,
  BrowseList list,
  SortOrder order,
) => (
  options: [
    for (final c in criteriaOf(list))
      KSortOption(
        value: c,
        label: sortCriterionLabel(l10n, c),
        icon: sortCriterionIcon(c),
        ascendingLabel: sortDirectionWords(l10n, c.kind).ascending,
        descendingLabel: sortDirectionWords(l10n, c.kind).descending,
      ),
  ],
  chosen: [
    for (final s in normalizedSortOf(list, order).specs)
      KSortEntry(value: s.criterion, descending: s.descending),
  ],
);

/// Lets the page that opened the sort dropdown or dialog close it when the
/// page goes away: both live on the root navigator, so they outlive the page.
/// Own one per page [State], pass it to `openListSort`, call [close] from
/// `dispose`. It holds the exact route the widget reported, never a guess.
class ListSortGuard {
  Route<dynamic>? _route;

  /// Remembers the route just pushed (a dropdown or a dialog).
  void track(Route<dynamic> route) => _route = route;

  /// Forgets [route] once it has closed on its own.
  void release(Route<dynamic> route) {
    if (identical(_route, route)) _route = null;
  }

  /// Removes the tracked route if it is still open; nothing otherwise. Runs
  /// after the current frame: a page's `dispose` happens while the tree is
  /// locked, and removing a route rebuilds the overlay.
  void close() {
    final route = _route;
    _route = null;
    if (route == null) return;
    scheduleMicrotask(() {
      if (route.isActive) route.navigator?.removeRoute(route);
    });
  }
}

/// Runs a write the UI does not wait for; a failure is logged, not thrown into
/// the void.
void _logFailure(Future<void> write, VoidCallback after) {
  unawaited(
    write.then(
      (_) => after(),
      onError: (Object e, StackTrace s) {
        _log.warning('Could not store the sort', e, s);
        after();
      },
    ),
  );
}

/// Opens the "Sắp xếp theo" box for [list]. Every change goes through
/// [write] at once and the rows follow what [read] answers afterwards (the
/// stores assign their state before they await, so that is the new order);
/// [reset] puts the list back to its default (list pages write the default
/// sort, detail pages drop their override).
///
/// [read] and [write] must not depend on the page's `ref`: the dialog may
/// outlive the page, so callers use the `ProviderContainer` taken before
/// opening. [guard] lets the page close the dialog when it is disposed.
Future<void> openAdvancedSort(
  BuildContext context, {
  required BrowseList list,
  required SortOrder Function() read,
  required Future<void> Function(SortOrder sort) write,
  required Future<void> Function() reset,
  ListSortGuard? guard,
}) async {
  final l10n = AppLocalizations.of(context);
  final model = sortDialogModel(l10n, list, read());
  final chosen = ValueNotifier<List<KSortEntry<SortCriterion>>>(model.chosen);
  var open = true;
  Route<dynamic>? route;

  SortOrder current() => normalizedSortOf(list, read());
  void refresh() {
    if (open) chosen.value = sortDialogModel(l10n, list, read()).chosen;
  }

  void apply(SortOrder Function(SortOrder now) change) {
    _logFailure(write(change(current())), refresh);
    refresh();
  }

  try {
    final done = showKSortDialog<SortCriterion>(
      context,
      options: model.options,
      chosen: chosen,
      onAdd: (c) => apply((now) => now.add(c)),
      onRemove: (c) => apply((now) => now.remove(c)),
      onFlip: (c) => apply((now) => now.flip(c)),
      onMove: (from, to) => apply((now) {
        final n = now.specs.length;
        return from < 0 || to < 0 || from >= n || to >= n
            ? now
            : now.move(from, to);
      }),
      onReset: () {
        _logFailure(reset(), refresh);
        refresh();
      },
      onRoute: (r) {
        route = r;
        guard?.track(r);
      },
      strings: KSortDialogStrings(
        title: l10n.librarySortDialogTitle,
        chosen: l10n.librarySortChosen,
        notChosen: l10n.librarySortNotChosen,
        reset: l10n.librarySortReset,
        done: l10n.librarySortDone,
        dragHint: (label) => l10n.librarySortDragHint(label),
        flipTooltip: (word) => l10n.librarySortFlipTooltip(word),
        flipSemantics: (label, word) =>
            l10n.librarySortFlipSemantics(label, word),
        remove: (label) => l10n.librarySortRemove(label),
        add: (label) => l10n.librarySortAdd(label),
      ),
    );
    await done;
  } finally {
    open = false;
    if (route != null) guard?.release(route!);
    chosen.dispose();
  }
}
