import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/info/release_date.dart';
import '../../domain/info/song_details.dart';
import '../../domain/tags/extra_tags.dart';
import '../track_path_sql.dart';

/// One row per track; the artists come from a second query.
///
/// Reads `present` and `missing` rows only: the info page also opens for a
/// file that went missing, never for a hidden or remote one. The favorite
/// mark is not joined: it lives in `playlist_entries`, and a join would
/// rerun this query on every playlist edit.
const _detailsSql =
    'SELECT t.*, td.comment, td.extra_tags, td.lrc_locator, '
    's.uid AS source_uid, s.name AS source_name, m.root AS mount_root, '
    '$trackDirSql AS dir, ps.play_count, ps.skip_count, ps.first_played_at, '
    'ps.last_played_at FROM tracks t '
    'JOIN sources s ON s.id = t.source_id '
    'LEFT JOIN source_mounts m ON m.source_id = t.source_id '
    'LEFT JOIN track_details td ON td.track_id = t.id '
    'LEFT JOIN play_stats ps ON ps.track_id = t.id '
    "WHERE t.id = ? AND t.status IN ('present', 'missing')";

/// Live details of [id]: null while the track is gone, hidden or remote.
/// Emits again when its rows, artists or play stats change, and skips
/// emissions equal to the previous one.
Stream<SongDetails?> watchSongDetails(AppDatabase db, TrackId id) {
  final vars = [Variable.withInt(id.value)];
  return db
      .customSelect(
        _detailsSql,
        variables: vars,
        readsFrom: {
          db.tracks,
          db.sources,
          db.sourceMounts,
          db.trackDetails,
          db.trackArtists,
          db.playStats,
        },
      )
      .watchSingleOrNull()
      .asyncMap((row) async {
        if (row == null) return null;
        final artistRows = await db
            .customSelect(
              'SELECT artist_key, artist_name FROM track_artists '
              'WHERE track_id = ? ORDER BY position',
              variables: vars,
              readsFrom: {db.trackArtists},
            )
            .get();
        return _build(row, [
          for (final r in artistRows)
            ArtistRef(
              ArtistKey(r.read<String>('artist_key')),
              r.read<String>('artist_name'),
            ),
        ]);
      })
      .distinct();
}

SongDetails _build(QueryRow r, List<ArtistRef> artists) {
  final locator = r.read<String>('locator');
  final root = r.readNullable<String>('mount_root');
  final base = trimMountRoot(root);
  final dir = r.read<String>('dir');
  final sourceName = r.read<String>('source_name');
  final extra = decodeExtraTags(r.readNullable<String>('extra_tags'));
  final artistKey = r.readNullable<String>('album_artist_key');
  final titleKey = r.readNullable<String>('album_title_key');
  final albumArtist = r.readNullable<String>('album_artist');
  return SongDetails(
    id: TrackId(r.read<int>('id')),
    title: r.read<String>('title'),
    coverKey: r.readNullable<String>('cover_key'),
    artists: artists,
    album: r.readNullable<String>('album'),
    albumKey: artistKey == null || titleKey == null
        ? null
        : AlbumKey(artistKey, titleKey),
    albumArtist: albumArtist,
    albumArtistKey: artistKey == null || (albumArtist?.trim().isEmpty ?? true)
        ? null
        : ArtistKey(artistKey),
    albumArtistDisplay:
        r.readNullable<String>('album_display_artist') ?? albumArtist,
    genre: r.readNullable<String>('genre'),
    genreKey: r.readNullable<String>('genre_key'),
    composer: r.readNullable<String>('composer'),
    year: r.readNullable<int>('year'),
    releaseDate: extra.releaseDate == null
        ? null
        : parseReleaseDate(extra.releaseDate!),
    trackNo: r.readNullable<int>('track_no'),
    trackTotal: r.readNullable<int>('track_total'),
    discNo: r.readNullable<int>('disc_no'),
    discTotal: r.readNullable<int>('disc_total'),
    language: r.readNullable<String>('language'),
    languageDetected: r.read<int>('language_detected') == 1,
    comment: r.readNullable<String>('comment'),
    description: extra.description,
    lrcLocator: r.readNullable<String>('lrc_locator'),
    durationMs: r.readNullable<int>('duration_ms'),
    codec: r.readNullable<String>('codec'),
    format: formatFromLocator(locator),
    bitrate: r.readNullable<int>('bitrate'),
    sampleRate: r.readNullable<int>('sample_rate'),
    bitDepth: r.readNullable<int>('bit_depth'),
    channels: r.readNullable<int>('channels'),
    path: trackFilePath(root, locator),
    // The page only links to the folder; it never shows a song count.
    folder: FolderRef(
      sourceId: r.read<int>('source_id'),
      sourceUid: r.read<String>('source_uid'),
      folderKey: dir,
      name: dir.isEmpty ? sourceName : dir.substring(dir.lastIndexOf('/') + 1),
      songCount: 0,
    ),
    sourceName: sourceName,
    sourceRoot: base,
    sizeBytes: r.readNullable<int>('size_bytes'),
    mtimeMs: r.readNullable<int>('mtime_ms'),
    addedAt: r.read<int>('added_at'),
    status: r.read<String>('status') == 'missing'
        ? SongFileStatus.missing
        : SongFileStatus.present,
    missingSince: r.readNullable<int>('missing_since'),
    scanError: r.readNullable<String>('scan_error'),
    rating: r.readNullable<int>('rating'),
    playCount: r.readNullable<int>('play_count') ?? 0,
    skipCount: r.readNullable<int>('skip_count') ?? 0,
    firstPlayedAt: r.readNullable<int>('first_played_at'),
    lastPlayedAt: r.readNullable<int>('last_played_at'),
  );
}
