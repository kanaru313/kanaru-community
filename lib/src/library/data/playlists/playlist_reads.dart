import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../../playback/data/track_info_rows.dart';
import '../../domain/playlists/playlist_cover_rule.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../domain/playlists/playlist_models.dart';
import 'playlist_sql.dart';

const _favoritesName = 'Favorites';
const _coverCandidates = 64;

PlaylistSummary _emptyFavorites() => PlaylistSummary(
  uid: PlaylistUids.favorites,
  name: _favoritesName,
  description: '',
  isFavorites: true,
  trackCount: 0,
  durationMs: 0,
  createdAt: 0,
  updatedAt: 0,
  autoCoverKeys: const [],
);

/// Summary query: counts and durations walk the `playlist_entries_order`
/// index (O(entries) per playlist); cover candidates come from a per-playlist
/// `LIMIT` subquery that stops after 64 entries with a cover (it may pass
/// cover-less ones first); its covers are in playlist order, and Favorites
/// overrides them with [favoriteCoverSql]. Favorites (`kind = 'favorites'`) skips copies hidden
/// by duplicate hiding (`dup_hidden = 1`); regular playlists keep them. The
/// aggregate `ORDER BY` needs SQLite 3.44. The
/// `sqlite3` package bundles a precompiled SQLite (3.54.x) on Android and
/// Linux. Never switch to the system SQLite: Android 11-13 ships 3.32, which
/// has no aggregate `ORDER BY`.
const playlistStatsSql =
    '''
  CASE WHEN p.kind IS 'favorites' THEN
    (SELECT COUNT(DISTINCT e.track_id) FROM playlist_entries e
      JOIN tracks t ON t.id = e.track_id
      WHERE e.playlist_id = p.id AND e.deleted_at IS NULL
        AND t.dup_hidden = 0)
  ELSE
    (SELECT COUNT(DISTINCT e.track_id) FROM playlist_entries e
      WHERE e.playlist_id = p.id AND e.deleted_at IS NULL)
  END AS cnt,
  (SELECT COALESCE(SUM(t.duration_ms), 0) FROM tracks t WHERE t.id IN
    (SELECT e.track_id FROM playlist_entries e
      WHERE e.playlist_id = p.id AND e.deleted_at IS NULL)
      AND (p.kind IS NOT 'favorites' OR t.dup_hidden = 0)) AS dur,
  (SELECT json_group_array(json_array(x.cover_key, x.grp)
            ORDER BY x.sk, x.eu) FROM
    (SELECT t.cover_key AS cover_key,
       COALESCE(t.album_artist_key || '|' || t.album_title_key,
                't' || t.id) AS grp, e.sort_key AS sk, e.uid AS eu
     FROM playlist_entries e JOIN tracks t ON t.id = e.track_id
     WHERE e.playlist_id = p.id AND e.deleted_at IS NULL
       AND t.cover_key IS NOT NULL
       AND (p.kind IS NOT 'favorites' OR t.dup_hidden = 0)
     ORDER BY e.sort_key, e.uid LIMIT $_coverCandidates) x) AS covers
''';

/// The playlist list: user playlists and Favorites, never mood or queue rows.
const summarySql =
    '''
SELECT p.uid, p.name, p.description, p.kind, p.created_at, p.updated_at,
$playlistStatsSql
FROM playlists p
WHERE p.deleted_at IS NULL AND (p.kind IS NULL OR p.kind = 'favorites')
ORDER BY p.created_at, p.id
''';

/// A [PlaylistSummary] from a row of [summarySql]-shaped columns (`uid`,
/// `name`, `description`, `created_at`, `updated_at`, `cnt`, `dur`, `covers`
/// of [playlistStatsSql]). [covers] replaces the row's own cover candidates
/// (Favorites).
PlaylistSummary summaryOfRow(
  QueryRow r, {
  bool isFavorites = false,
  SavedQueueInfo? savedQueue,
  Iterable<({String group, String? coverKey})>? covers,
}) {
  final candidates =
      covers ??
      ((jsonDecode(r.read<String>('covers')) as List).cast<List<Object?>>())
          .map((c) => (group: c[1] as String, coverKey: c[0] as String?));
  return PlaylistSummary(
    uid: r.read<String>('uid'),
    name: r.read<String>('name'),
    description: r.read<String>('description'),
    isFavorites: isFavorites,
    trackCount: r.read<int>('cnt'),
    durationMs: r.read<int>('dur'),
    createdAt: r.read<int>('created_at'),
    updatedAt: r.read<int>('updated_at'),
    autoCoverKeys: pickAutoCoverKeys(candidates),
    savedQueue: savedQueue,
  );
}

/// Cover candidates of Favorites, newest added first (equal times keep list
/// order); the first 64 with a cover, as the summary query does for the other
/// playlists. There is no index on `added_at`, so SQLite keeps a 64-row top-N
/// while it scans the live favourites.
const favoriteCoverSql =
    '''
SELECT t.cover_key AS cover_key,
  COALESCE(t.album_artist_key || '|' || t.album_title_key,
           't' || t.id) AS grp
FROM playlist_entries e JOIN tracks t ON t.id = e.track_id
WHERE e.playlist_id = (SELECT id FROM playlists WHERE uid = ?)
  AND e.deleted_at IS NULL AND t.cover_key IS NOT NULL AND t.dup_hidden = 0
ORDER BY e.added_at DESC, e.sort_key, e.uid LIMIT $_coverCandidates
''';

/// All user playlists plus Favorites, from one query.
Future<PlaylistSummaries> loadSummaries(AppDatabase db) async {
  final rows = await db.customSelect(summarySql).get();
  final playlists = <PlaylistSummary>[];
  PlaylistSummary? favorites;
  for (final r in rows) {
    final isFavorites =
        r.readNullable<String>('kind') == PlaylistKind.favorites;
    final favoriteCovers = isFavorites
        ? (await db
                  .customSelect(
                    favoriteCoverSql,
                    variables: [Variable.withString(r.read<String>('uid'))],
                  )
                  .get())
              .map(
                (c) => (
                  group: c.read<String>('grp'),
                  coverKey: c.readNullable<String>('cover_key'),
                ),
              )
        : null;
    final s = summaryOfRow(r, isFavorites: isFavorites, covers: favoriteCovers);
    if (isFavorites) {
      favorites = s;
    } else {
      playlists.add(s);
    }
  }
  return PlaylistSummaries(
    playlists: playlists,
    favorites: favorites ?? _emptyFavorites(),
  );
}

/// One playlist with its entries, read in one transaction so a write cannot
/// land between the entries and their tracks. Also reads a saved queue row
/// (`summary.savedQueue` set; M3U export needs it): a caller that must not
/// show one checks that field.
Future<PlaylistDetail?> loadDetail(
  AppDatabase db,
  String uid,
) => db.transaction(() async {
  final rows = await db
      .customSelect(
        'SELECT id, uid, name, description, kind, created_at, updated_at, '
        'saved_at, context_kind, context_ref, context_label '
        'FROM playlists WHERE uid = ? AND deleted_at IS NULL',
        variables: [Variable.withString(uid)],
      )
      .get();
  if (rows.isEmpty) {
    if (uid != PlaylistUids.favorites) return null;
    return PlaylistDetail(summary: _emptyFavorites(), entries: const []);
  }
  final p = rows.single;
  final entryRows = await db
      .customSelect(
        'SELECT e.uid AS uid, e.track_id AS track_id, e.added_at AS added_at '
        'FROM playlist_entries e JOIN tracks t ON t.id = e.track_id '
        'WHERE e.playlist_id = ? AND e.deleted_at IS NULL '
        // Favorites follows duplicate hiding; other playlists keep copies.
        'AND (? = 0 OR t.dup_hidden = 0) '
        'ORDER BY e.sort_key, e.uid',
        variables: [
          Variable.withInt(p.read<int>('id')),
          Variable.withInt(
            p.readNullable<String>('kind') == PlaylistKind.favorites ? 1 : 0,
          ),
        ],
      )
      .get();
  final isFavorites = p.readNullable<String>('kind') == PlaylistKind.favorites;
  // Entry uid -> added time, for the Favorites cover order.
  final addedAt = {
    for (final r in entryRows) r.read<String>('uid'): r.read<int>('added_at'),
  };
  final infos = await loadTrackInfos(db, [
    for (final r in entryRows) TrackId(r.read<int>('track_id')),
  ]);
  final byId = {for (final i in infos) i.id: i};
  final entries = [
    for (final r in entryRows)
      if (byId[TrackId(r.read<int>('track_id'))] case final info?)
        PlaylistEntryView(uid: r.read<String>('uid'), info: info),
  ];
  final distinct = <TrackId, int>{
    for (final e in entries) e.info.id: e.info.durationMs ?? 0,
  };
  return PlaylistDetail(
    summary: PlaylistSummary(
      uid: uid,
      name: p.read<String>('name'),
      description: p.read<String>('description'),
      isFavorites: p.readNullable<String>('kind') == PlaylistKind.favorites,
      trackCount: distinct.length,
      durationMs: distinct.values.fold(0, (a, b) => a + b),
      createdAt: p.read<int>('created_at'),
      updatedAt: p.read<int>('updated_at'),
      savedQueue: p.readNullable<String>('kind') == PlaylistKind.queue
          ? SavedQueueInfo(
              savedAt:
                  p.readNullable<int>('saved_at') ?? p.read<int>('created_at'),
              contextKind: p.readNullable<String>('context_kind'),
              contextRef: p.readNullable<String>('context_ref'),
              contextLabel: p.readNullable<String>('context_label'),
            )
          : null,
      autoCoverKeys: pickAutoCoverKeys(
        (isFavorites ? _newestFirst(entries, addedAt) : entries)
            .where((e) => e.info.coverKey != null)
            .take(_coverCandidates)
            .map((e) {
              final k = e.info.albumKey;
              return (
                group: k == null
                    ? 't${e.info.id.value}'
                    : '${k.artistKey}|${k.titleKey}',
                coverKey: e.info.coverKey,
              );
            }),
      ),
    ),
    entries: entries,
  );
});

/// [entries] by added time, newest first; equal times keep list order, as the
/// summary query does (`sort_key`, `uid`).
List<PlaylistEntryView> _newestFirst(
  List<PlaylistEntryView> entries,
  Map<String, int> addedAt,
) {
  final indexed = [for (var i = 0; i < entries.length; i++) (i, entries[i])];
  indexed.sort((a, b) {
    final byTime = (addedAt[b.$2.uid] ?? 0).compareTo(addedAt[a.$2.uid] ?? 0);
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Distinct tracks of [tracks] each live playlist already holds.
Future<Map<String, int>> countExistingTracks(
  AppDatabase db,
  List<TrackId> tracks,
) async {
  if (tracks.isEmpty) return const {};
  final rows = await db
      .customSelect(
        'SELECT p.uid AS uid, COUNT(DISTINCT e.track_id) AS c '
        'FROM playlist_entries e JOIN playlists p ON p.id = e.playlist_id '
        "WHERE p.deleted_at IS NULL AND (p.kind IS NULL OR p.kind = 'favorites') "
        'AND e.deleted_at IS NULL AND e.track_id IN $jsonEach '
        'GROUP BY p.id',
        variables: [
          jsonList({for (final t in tracks) t.value}),
        ],
      )
      .get();
  return {for (final r in rows) r.read<String>('uid'): r.read<int>('c')};
}
