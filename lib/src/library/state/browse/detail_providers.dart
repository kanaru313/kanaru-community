import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/library_keys.dart';
import '../../data/browse/detail_queries.dart';
import '../../data/browse/throttled_query.dart';
import '../../domain/browse/detail_data.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/browse/song_scope.dart';
import 'song_list_providers.dart';

/// Albums of an artist (own and appears-on), live while a scan writes.
final artistAlbumsProvider = StreamProvider.family<ArtistAlbums, ArtistKey>((
  ref,
  artist,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(
    db,
    {db.tracks, db.trackArtists},
    () => artistAlbums(db, artist),
    interval: ref.watch(browseRefreshIntervalProvider),
  );
}, isAutoDispose: true);

/// Artists and albums of a genre or language.
final groupShelvesProvider = StreamProvider.family<GroupShelves, SongScope>((
  ref,
  scope,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(
    db,
    {db.tracks, db.trackArtists},
    () => groupShelves(db, scope),
    interval: ref.watch(browseRefreshIntervalProvider),
  );
}, isAutoDispose: true);

/// Banner totals of a genre or language.
final groupTotalsProvider = StreamProvider.family<GroupTotals, SongScope>((
  ref,
  scope,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(
    db,
    {db.tracks, db.trackArtists},
    () => groupTotals(db, scope),
    interval: ref.watch(browseRefreshIntervalProvider),
  );
}, isAutoDispose: true);
