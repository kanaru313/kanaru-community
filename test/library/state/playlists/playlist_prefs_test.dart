import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_prefs_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../../support/memory_settings_store.dart';

void main() {
  late MemorySettingsStore settings;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(settings)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => settings = MemorySettingsStore());

  final byTitleThenArtist = SortOrder([
    const SortSpec(SortCriterion.title, descending: true),
    const SortSpec(SortCriterion.artist),
  ]);

  test('absent playlist uses playlist order ascending', () {
    final c = container();
    expect(
      c.read(playlistTrackSortProvider('p')),
      defaultSortOf(BrowseList.playlistTracks),
    );
    expect(c.read(playlistTrackSortsProvider), isEmpty);
  });

  test('set persists across containers, keeping criteria in order', () async {
    final first = container();
    await first
        .read(playlistTrackSortsProvider.notifier)
        .set('p', byTitleThenArtist);
    expect(first.read(playlistTrackSortProvider('p')), byTitleThenArtist);

    final second = container();
    expect(second.read(playlistTrackSortProvider('p')), byTitleThenArtist);
    expect(
      second.read(playlistTrackSortProvider('other')),
      defaultSortOf(BrowseList.playlistTracks),
    );
  });

  test('reset and forget drop the entry', () async {
    final c = container();
    final n = c.read(playlistTrackSortsProvider.notifier);
    await n.set('a', byTitleThenArtist);
    await n.set('b', byTitleThenArtist);
    await n.reset('a');
    await n.forget('b');
    expect(c.read(playlistTrackSortsProvider), isEmpty);
    expect(container().read(playlistTrackSortsProvider), isEmpty);
  });

  test('corrupt data falls back to the default per entry', () async {
    await settings.write('library.playlist_track_sorts', {
      'good': [
        {'by': 'title', 'desc': true},
      ],
      'bad': 'nonsense',
      'unknownCriterion': [
        {'by': 'bogus', 'desc': false},
      ],
    });
    final c = container();
    expect(c.read(playlistTrackSortsProvider).keys, ['good']);

    await settings.write('library.playlist_track_sorts', 'not a map');
    expect(container().read(playlistTrackSortsProvider), isEmpty);
  });

  test(
    'list view and sort of the playlists list use library.list_views',
    () async {
      final c = container();
      final sort = SortOrder.by(SortCriterion.name);
      await c
          .read(libraryListViewsProvider.notifier)
          .setSort(BrowseList.playlists, sort);
      expect(
        c.read(libraryListViewsProvider).of(BrowseList.playlists).sort,
        sort,
      );
    },
  );
}
