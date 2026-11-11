import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../support/memory_settings_store.dart';

void main() {
  late MemorySettingsStore store;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => store = MemorySettingsStore());

  test('defaults, and sort/view changes persist per list', () async {
    final c = container();
    final n = c.read(libraryListViewsProvider.notifier);
    expect(c.read(libraryListViewsProvider), LibraryListViews());
    await n.setSort(
      BrowseList.songs,
      const SortSpec(SortCriterion.year, descending: true),
    );
    await n.setView(BrowseList.albums, CollectionView.list);
    await n.setFolderView(FolderView.flat);
    final again = container().read(libraryListViewsProvider);
    expect(
      again.of(BrowseList.songs).sort,
      const SortSpec(SortCriterion.year, descending: true),
    );
    expect(again.of(BrowseList.albums).view, CollectionView.list);
    expect(again.folderView, FolderView.flat);
    // Other lists keep their defaults.
    expect(
      again.of(BrowseList.genres),
      ListViewPrefs.defaultsOf(BrowseList.genres),
    );
    expect(again.of(BrowseList.albums).sort, defaultSortOf(BrowseList.albums));
  });

  test('a stored value that is not a map falls back to defaults', () async {
    await store.write(libraryListViewsSetting.key, 'garbage');
    expect(container().read(libraryListViewsProvider), LibraryListViews());
  });

  test('compact folders default on, a bad value falls back to on', () async {
    expect(container().read(compactFoldersProvider), isTrue);
    await store.write(compactFoldersSetting.key, 'yes');
    expect(container().read(compactFoldersProvider), isTrue);
    final c = container();
    await c.read(compactFoldersProvider.notifier).set(false);
    expect(container().read(compactFoldersProvider), isFalse);
  });
}
