import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/menus/menu_loaders.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../../database/support/test_db.dart';
import '../../../support/memory_settings_store.dart';
import '../../browse/support/library_fixture.dart';
import 'menu_fixtures.dart';

/// Play and shuffle of the album / artist menu take the songs in the order the
/// detail page shows: its session sort, else the kind's remembered sort.
void main() {
  late ProviderContainer container;
  late List<int> ids; // by track number 1..3
  final album = albumKeyOf('Blue', 'Miles');
  final artist = ArtistKey('miles');

  setUp(() async {
    final db = openTestDb();
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      ],
    );
    addTearDown(container.dispose);
    final source = await addSource(db);
    // Titles disagree with the track order.
    ids = [
      for (final (n, title) in [(1, 'Cc'), (2, 'Aa'), (3, 'Bb')])
        await addLibraryTrack(
          db,
          source: source,
          locator: '$n.flac',
          title: title,
          artists: ['Miles'],
          album: 'Blue',
          albumArtist: 'Miles',
          trackNo: n,
          addedAt: n,
        ),
    ];
  });

  Future<List<int>> albumIds() async => [
    for (final id in (await albumMenuSpec(
      container,
      env(),
      album,
      const MenuOrigin.list(),
    )).queueIds)
      id.value,
  ];

  Future<List<int>> artistIds() async => [
    for (final id in (await artistMenuSpec(
      container,
      env(),
      artist,
      const MenuOrigin.list(),
    )).queueIds)
      id.value,
  ];

  test('album: the kind default when nothing was chosen', () async {
    expect(await albumIds(), ids);
  });

  test('album: the remembered sort of album tracks', () async {
    await container
        .read(libraryListViewsProvider.notifier)
        .setSort(
          BrowseList.albumTracks,
          SortOrder.by(SortCriterion.trackNumber, descending: true),
        );
    expect(await albumIds(), ids.reversed.toList());
  });

  test('album: the page override wins over the remembered sort', () async {
    await container
        .read(libraryListViewsProvider.notifier)
        .setSort(
          BrowseList.albumTracks,
          SortOrder.by(SortCriterion.trackNumber, descending: true),
        );
    await container.read(detailSortOverridesProvider.notifier).set((
      list: BrowseList.albumTracks,
      item: album.encode(),
    ), SortOrder.by(SortCriterion.title));
    expect(await albumIds(), [ids[1], ids[2], ids[0]]);
  });

  test('artist: remembered sort, then the page override', () async {
    await container
        .read(libraryListViewsProvider.notifier)
        .setSort(BrowseList.detailSongs, SortOrder.by(SortCriterion.title));
    expect(await artistIds(), [ids[1], ids[2], ids[0]]);
    await container.read(detailSortOverridesProvider.notifier).set((
      list: BrowseList.detailSongs,
      item: artist.encode(),
    ), SortOrder.by(SortCriterion.title, descending: true));
    expect(await artistIds(), [ids[0], ids[2], ids[1]]);
  });
}
