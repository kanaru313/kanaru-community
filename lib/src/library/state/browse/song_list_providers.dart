import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/data/track_info_rows.dart';
import '../../data/browse/song_ids_query.dart';
import '../../data/browse/throttled_query.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';

/// Minimum gap between reloads of a list; tests override it.
final browseRefreshIntervalProvider = Provider<Duration>(
  (ref) => browseRefreshInterval,
);

/// Minimum gap between reloads of the folder tree; tests override it.
final folderRefreshIntervalProvider = Provider<Duration>(
  (ref) => folderRefreshInterval,
);

/// Reads the rows of a page of ids for a [TrackWindow]; tests override it.
typedef TrackRowLoader = Future<List<TrackInfo>> Function(List<TrackId> ids);

final trackRowLoaderProvider = Provider<TrackRowLoader>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (ids) => loadTrackInfos(db, ids);
});

/// What a song list shows: which tracks, in which order, narrowed by text.
typedef SongListKey = ({SongScope scope, SortSpec sort, String filter});

/// Ordered visible track ids of a list. Reloads while a scan writes (at most
/// once per refresh interval) and re-emits only when the ids changed. Play
/// counts are watched only when the list is sorted by them, so playback does
/// not refresh the others. One-shot readers (a play button) call [songIds]
/// directly instead of reading this provider's future.
final songIdsProvider = StreamProvider.family<List<TrackId>, SongListKey>((
  ref,
  key,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(
    db,
    {
      db.tracks,
      db.trackArtists,
      if (key.sort.criterion == SortCriterion.playCount) db.playStats,
    },
    () => songIds(db, key.scope, key.sort, key.filter),
    interval: ref.watch(browseRefreshIntervalProvider),
    equals: sameElements,
  );
}, isAutoDispose: true);

/// Ticks (1, 2, 3, ...) after each throttled reload of the data song rows
/// show: a cover, title or artist can change while the id order stays as it
/// was, and the ids provider drops such an emission. A song list calls
/// `TrackWindow.invalidate` on every tick. Never deduplicated.
final songRowsRevisionProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  var revision = 0;
  return throttledQuery(
    db,
    {db.tracks, db.trackArtists},
    () async => ++revision,
    interval: ref.watch(browseRefreshIntervalProvider),
    equals: (_, _) => false,
  );
});

/// Number of visible tracks of a scope, ignoring any filter ("6 / 34").
final songCountProvider = StreamProvider.family<int, SongScope>((ref, scope) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(
    db,
    {db.tracks, db.trackArtists},
    () => songCount(db, scope),
    interval: ref.watch(browseRefreshIntervalProvider),
  );
}, isAutoDispose: true);

/// List equality by element `==` (used to drop an unchanged reload).
bool sameElements<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
