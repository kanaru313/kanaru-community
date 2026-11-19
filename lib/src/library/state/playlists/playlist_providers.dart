import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/track_id.dart';
import '../../data/playlists/playlist_repository.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_sort.dart';
import '../../domain/playlists/playlist_store.dart';
import '../browse/list_prefs_providers.dart';

/// The playlist store. Tests override it with a fake.
final playlistStoreProvider = Provider<PlaylistStore>(
  (ref) => PlaylistRepository(ref.watch(appDatabaseProvider)),
);

/// User playlists and Favorites from one query; the two views below select
/// from it.
final playlistSummariesProvider = StreamProvider<PlaylistSummaries>(
  (ref) => ref.watch(playlistStoreProvider).watchSummaries(),
);

final playlistsProvider = Provider<AsyncValue<List<PlaylistSummary>>>(
  (ref) => ref.watch(
    playlistSummariesProvider.select((a) => a.whenData((s) => s.playlists)),
  ),
);

final favoritesSummaryProvider = Provider<AsyncValue<PlaylistSummary>>(
  (ref) => ref.watch(
    playlistSummariesProvider.select((a) => a.whenData((s) => s.favorites)),
  ),
);

/// [playlistsProvider] in the order chosen for "Playlist của bạn"
/// (`libraryListViewsProvider`, list [BrowseList.playlists]).
final sortedPlaylistsProvider = Provider<AsyncValue<List<PlaylistSummary>>>((
  ref,
) {
  final sort = ref.watch(
    libraryListViewsProvider.select((v) => v.of(BrowseList.playlists).sort),
  );
  return ref
      .watch(playlistsProvider)
      .whenData((list) => sortPlaylists(list, sort));
});

/// One playlist as stored: null when it does not exist (also after delete) or
/// is a saved queue.
/// A page shows `playlistPageProvider` instead, which adds pending edits.
final playlistDetailProvider = StreamProvider.autoDispose
    .family<PlaylistDetail?, String>(
      (ref, uid) => ref
          .watch(playlistStoreProvider)
          .watchPlaylist(uid)
          // A saved queue has its own page; `/playlists/<its uid>` is "not
          // found" (`loadPlaylist` still reads it for M3U export).
          .map((d) => d?.summary.savedQueue == null ? d : null),
    );

/// Track ids with value equality, so it can key a family.
class TrackIdList {
  TrackIdList(Iterable<TrackId> ids) : ids = List.unmodifiable(ids);

  final List<TrackId> ids;

  @override
  bool operator ==(Object other) {
    if (other is! TrackIdList || other.ids.length != ids.length) return false;
    for (var i = 0; i < ids.length; i++) {
      if (other.ids[i] != ids[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(ids);
}

/// For each playlist uid (Favorites included) how many distinct tracks of the
/// list it already holds.
final playlistMembershipProvider = FutureProvider.autoDispose
    .family<Map<String, int>, TrackIdList>(
      (ref, tracks) =>
          ref.watch(playlistStoreProvider).countExisting(tracks.ids),
    );
