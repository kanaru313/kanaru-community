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
