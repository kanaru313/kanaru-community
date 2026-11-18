import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/browse/list_sort.dart';
import '../../../domain/browse/sort_order.dart';
import '../../../state/browse/list_prefs_providers.dart';
import '../../browse/list_sort_dialog.dart';
import '../../browse/list_sort_popover.dart';

const BrowseList _list = BrowseList.playlists;

/// Opens the sort box of the playlists list. The container is taken now: the
/// box is on the root navigator and can outlive the page, whose `ref` is dead
/// by then.
Future<void> openPlaylistsSort(
  BuildContext context,
  GlobalKey anchor,
  ListSortGuard guard,
) {
  final container = ProviderScope.containerOf(context);
  Future<void> write(SortOrder sort) =>
      container.read(libraryListViewsProvider.notifier).setSort(_list, sort);
  return openListSort(
    context,
    list: _list,
    anchor: anchor,
    guard: guard,
    read: () => container.read(libraryListViewsProvider).of(_list).sort,
    write: write,
    reset: () => write(defaultSortOf(_list)),
  );
}

/// Flips the direction of the stored sort.
void reversePlaylistsSort(WidgetRef ref) {
  final current = ref.read(libraryListViewsProvider).of(_list).sort;
  unawaited(
    ref
        .read(libraryListViewsProvider.notifier)
        .setSort(_list, current.reversed()),
  );
}
