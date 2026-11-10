import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/library_keys.dart';
import '../../data/browse/album_artist_queries.dart';
import '../../data/browse/detail_queries.dart';
import '../../data/browse/throttled_query.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/detail_data.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/browse/song_scope.dart';
import 'collection_providers.dart';
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

/// Summary of one album (title, display artist, year, cover); null when no
/// visible track has the key.
final albumDetailProvider = StreamProvider.family<AlbumSummary?, AlbumKey>((
  ref,
  key,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(db, {db.tracks, db.trackArtists}, () async {
    final found = await albumSummaries(db, scope: SongScope.album(key));
    return found.isEmpty ? null : found.first;
  }, interval: ref.watch(browseRefreshIntervalProvider));
}, isAutoDispose: true);

/// Summary of one artist from the tracks it takes part in; null for a key
/// that only appears as an album artist (no `track_artists` row).
final artistDetailProvider = StreamProvider.family<ArtistSummary?, ArtistKey>((
  ref,
  key,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(db, {db.tracks, db.trackArtists}, () async {
    final found = await artistSummaries(db, scope: SongScope.artist(key));
    final encoded = key.encode();
    for (final a in found) {
      if (a.key == encoded) return a;
    }
    return null;
  }, interval: ref.watch(browseRefreshIntervalProvider));
}, isAutoDispose: true);

/// Name of an artist page: the artist tag name, else (an album artist with
/// no track of its own) the display artist of its first album, else the key
/// itself. Data null = the artist is in the library nowhere (not found).
/// Loading until both the artist and its albums have answered.
final artistNameProvider = Provider.autoDispose
    .family<AsyncValue<String?>, ArtistKey>((ref, key) {
      final detail = ref.watch(artistDetailProvider(key));
      final albums = ref.watch(artistAlbumsProvider(key));
      final error = detail.error ?? albums.error;
      if (error != null && !(detail.hasValue && albums.hasValue)) {
        return AsyncError(error, StackTrace.current);
      }
      if (!detail.hasValue || !albums.hasValue) return const AsyncLoading();
      final named = detail.value?.name;
      if (named != null) return AsyncData(named);
      final any = albums.value!;
      if (any.own.isEmpty && any.appears.isEmpty) return const AsyncData(null);
      final display = any.own.isEmpty ? null : any.own.first.artist;
      return AsyncData(
        display != null && display.isNotEmpty ? display : key.key,
      );
    });

/// Name of a genre (the stored spelling); data null = no such genre.
final genreNameProvider = Provider.autoDispose
    .family<AsyncValue<String?>, String>((ref, genreKey) {
      return ref.watch(genreSummariesProvider).whenData((all) {
        for (final g in all) {
          if (g.key == genreKey) return g.name;
        }
        return null;
      });
    });
