import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
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
      SortOrder.by(SortCriterion.year, descending: true),
    );
    await n.setView(BrowseList.albums, CollectionView.list);
    await n.setFolderView(FolderView.flat);
    final again = container().read(libraryListViewsProvider);
    expect(
      again.of(BrowseList.songs).sort,
      SortOrder.by(SortCriterion.year, descending: true),
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

  test('a multi-criteria sort persists', () async {
    final order = SortOrder([
      const SortSpec(SortCriterion.artist),
      const SortSpec(SortCriterion.year, descending: true),
    ]);
    await container()
        .read(libraryListViewsProvider.notifier)
        .setSort(BrowseList.albums, order);
    expect(
      container().read(libraryListViewsProvider).of(BrowseList.albums).sort,
      order,
    );
  });

  test(
    'a detail page override is set, then cleared back to the default',
    () async {
      final c = container();
      const page = (list: BrowseList.albumTracks, item: 'a');
      const other = (list: BrowseList.albumTracks, item: 'b');
      final provider = detailSortProvider(page);
      c.listen(provider, (_, _) {});
      expect(c.read(provider), defaultSortOf(BrowseList.albumTracks));
      final notifier = c.read(detailSortOverridesProvider.notifier);
      await notifier.set(
        page,
        SortOrder.by(SortCriterion.title, descending: true),
      );
      await notifier.set(other, SortOrder.by(SortCriterion.duration));
      expect(
        c.read(provider),
        SortOrder.by(SortCriterion.title, descending: true),
      );
      notifier.clear(page);
      expect(c.read(provider), defaultSortOf(BrowseList.albumTracks));
      expect(
        c.read(detailSortProvider(other)),
        SortOrder.by(SortCriterion.duration),
      );
    },
  );
}
