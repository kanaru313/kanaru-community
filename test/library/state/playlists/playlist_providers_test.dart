import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../../support/memory_settings_store.dart';
import 'playlist_test_support.dart';

class _Store implements PlaylistStore {
  final summaries = StreamController<PlaylistSummaries>.broadcast();
  final counted = <List<TrackId>>[];
  int summaryListens = 0;

  @override
  Stream<PlaylistSummaries> watchSummaries() {
    summaryListens++;
    return summaries.stream;
  }

  @override
  Future<Map<String, int>> countExisting(List<TrackId> tracks) async {
    counted.add(tracks);
    return {'p': tracks.length};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Store store;
  late ProviderContainer c;

  setUp(() {
    store = _Store();
    c = ProviderContainer(
      overrides: [
        playlistStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      ],
    );
    addTearDown(c.dispose);
  });

  PlaylistSummaries sums(List<PlaylistSummary> list) => PlaylistSummaries(
    playlists: list,
    favorites: summary(uid: 'favorites', name: 'Favorites'),
  );

  test('one summaries stream feeds playlists and favorites', () async {
    final a = c.listen(playlistsProvider, (_, _) {});
    final b = c.listen(favoritesSummaryProvider, (_, _) {});
    addTearDown(a.close);
    addTearDown(b.close);
    store.summaries.add(sums([summary(uid: 'x', name: 'X')]));
    await waitFor(() => a.read().hasValue, what: 'summaries');
    expect(a.read().value!.single.uid, 'x');
    expect(b.read().value!.uid, 'favorites');
    expect(store.summaryListens, 1);
  });

  test(
    'sortedPlaylists follows the stored sort of the playlists list',
    () async {
      final sub = c.listen(sortedPlaylistsProvider, (_, _) {});
      addTearDown(sub.close);
      store.summaries.add(
        sums([
          summary(uid: 'b', name: 'Beta', updatedAt: 5),
          summary(uid: 'a', name: 'Alpha', updatedAt: 9),
        ]),
      );
      await waitFor(() => sub.read().hasValue, what: 'summaries');
      expect(sub.read().value!.map((s) => s.uid), ['a', 'b']); // newest first
      await c
          .read(libraryListViewsProvider.notifier)
          .setSort(
            BrowseList.playlists,
            SortOrder.by(SortCriterion.name, descending: true),
          );
      expect(sub.read().value!.map((s) => s.uid), ['b', 'a']);
    },
  );

  test(
    'TrackIdList has value equality and keys the membership family',
    () async {
      expect(
        TrackIdList([TrackId(1), TrackId(2)]),
        TrackIdList([TrackId(1), TrackId(2)]),
      );
      expect(TrackIdList([TrackId(1)]) == TrackIdList([TrackId(2)]), isFalse);
      expect(
        TrackIdList([TrackId(1)]).hashCode,
        TrackIdList([TrackId(1)]).hashCode,
      );
      final first = c.listen(
        playlistMembershipProvider(TrackIdList([TrackId(1), TrackId(2)])),
        (_, _) {},
      );
      final second = c.listen(
        playlistMembershipProvider(TrackIdList([TrackId(1), TrackId(2)])),
        (_, _) {},
      );
      addTearDown(first.close);
      addTearDown(second.close);
      await waitFor(() => first.read().hasValue, what: 'membership');
      expect(first.read().value, {'p': 2});
      expect(store.counted, hasLength(1));
    },
  );
}
