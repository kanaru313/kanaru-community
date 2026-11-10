import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';

/// Settings key `library.list_views`: sort and layout of every list.
final Setting<LibraryListViews> libraryListViewsSetting = Setting(
  'library.list_views',
  LibraryListViews(),
  decode: LibraryListViews.fromJson,
  encode: (v) => v.toJson(),
);

/// Remembered sort, layout and folder view; each list keeps its own.
class LibraryListViewsNotifier extends SettingNotifier<LibraryListViews> {
  LibraryListViewsNotifier() : super(libraryListViewsSetting);

  Future<void> setSort(BrowseList list, SortSpec sort) =>
      set(state.withList(list, state.of(list).copyWith(sort: sort)));

  Future<void> setView(BrowseList list, CollectionView view) =>
      set(state.withList(list, state.of(list).copyWith(view: view)));

  Future<void> setFolderView(FolderView view) =>
      set(state.withFolderView(view));
}

final libraryListViewsProvider =
    NotifierProvider<LibraryListViewsNotifier, LibraryListViews>(
      LibraryListViewsNotifier.new,
    );

/// Settings key `library.compact_folders`: merge single-subfolder chains in
/// the folder tree. No settings screen yet.
final Setting<bool> compactFoldersSetting = Setting(
  'library.compact_folders',
  true,
  decode: (json) =>
      json is bool ? json : throw const FormatException('not a bool'),
  encode: (v) => v,
);

final compactFoldersProvider = settingNotifierProvider(compactFoldersSetting);

/// One detail page: the kind of its song list and the item it shows (the
/// encoded album / artist key, or the genre / language id).
typedef DetailPageKey = ({BrowseList list, String item});

/// Sorts chosen on detail pages during this session. A page nobody changed
/// starts with the remembered default of its kind (`library.list_views`).
class DetailSortOverrides extends Notifier<Map<DetailPageKey, SortSpec>> {
  @override
  Map<DetailPageKey, SortSpec> build() => const {};

  Future<void> set(DetailPageKey page, SortSpec sort) async =>
      state = {...state, page: sort};
}

final detailSortOverridesProvider =
    NotifierProvider<DetailSortOverrides, Map<DetailPageKey, SortSpec>>(
      DetailSortOverrides.new,
    );

/// Sort in use on one detail page: its override, else the kind's default.
final detailSortProvider = Provider.autoDispose.family<SortSpec, DetailPageKey>(
  (ref, page) =>
      ref.watch(detailSortOverridesProvider.select((m) => m[page])) ??
      ref.watch(libraryListViewsProvider.select((v) => v.of(page.list).sort)),
);
