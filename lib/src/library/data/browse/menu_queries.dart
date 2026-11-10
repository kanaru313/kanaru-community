import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/browse/song_scope.dart';
import 'scope_sql.dart';

const _chunk = 500;
final _cueSuffix = RegExp(r'#\d+$');

String _lastSegment(String key) => key.substring(key.lastIndexOf('/') + 1);

/// Dir of `t.locator` as a key: everything before the last `/`, `''` when
/// there is none. `rtrim` with the locator's own non-slash characters strips
/// the file name.
const _dirSql =
    "CASE WHEN instr(t.locator, '/') = 0 THEN '' ELSE "
    "substr(rtrim(t.locator, replace(t.locator, '/', '')), 1, "
    "length(rtrim(t.locator, replace(t.locator, '/', ''))) - 1) END";

/// Where "Đi tới" of [id] leads. Null when the track is gone or hidden.
Future<TrackLinks?> trackLinks(AppDatabase db, TrackId id) async {
  final row = await db
      .customSelect(
        'SELECT t.source_id, s.uid AS source_uid, s.name AS source_name, '
        't.album, t.album_artist, t.album_display_artist, t.album_artist_key, t.album_title_key, '
        '$_dirSql AS dir FROM tracks t JOIN sources s ON s.id = t.source_id '
        'WHERE t.id = ? AND ${visibleTrackWhere('t')}',
        variables: [Variable.withInt(id.value)],
        readsFrom: {db.tracks, db.sources},
      )
      .getSingleOrNull();
  if (row == null) return null;
  final artistRows = await db
      .customSelect(
        'SELECT artist_key, artist_name FROM track_artists '
        'WHERE track_id = ? ORDER BY position',
        variables: [Variable.withInt(id.value)],
        readsFrom: {db.trackArtists},
      )
      .get();
  final artists = [
    for (final r in artistRows)
      ArtistRef(
        ArtistKey(r.read<String>('artist_key')),
        r.read<String>('artist_name'),
      ),
  ];
  // The stored key links to rows that carry it; the name shown is the
  // display artist when the album has one.
  final albumArtist = row.readNullable<String>('album_artist')?.trim();
  final aKey = row.readNullable<String>('album_artist_key');
  final albumArtists = [
    if (albumArtist != null &&
        albumArtist.isNotEmpty &&
        aKey != null &&
        !artists.any((a) => a.key.key == aKey))
      ArtistRef(
        ArtistKey(aKey),
        row.readNullable<String>('album_display_artist') ?? albumArtist,
      ),
  ];
  final titleKey = row.readNullable<String>('album_title_key');
  final dir = row.read<String>('dir');
  final sourceId = row.read<int>('source_id');
  final siblings = await _directCount(db, sourceId, dir);
  return TrackLinks(
    albumKey: titleKey == null || aKey == null
        ? null
        : AlbumKey(aKey, titleKey),
    albumTitle: row.readNullable<String>('album'),
    artists: artists,
    albumArtists: albumArtists,
    folder: FolderRef(
      sourceId: sourceId,
      sourceUid: row.read<String>('source_uid'),
      folderKey: dir,
      name: dir.isEmpty ? row.read<String>('source_name') : _lastSegment(dir),
      songCount: siblings,
    ),
  );
}

Future<int> _directCount(AppDatabase db, int sourceId, String dir) async {
  final where = SqlWhere()..add(visibleTrackWhere('t'));
  addScope(where, SongScope.folder(sourceId, dir, direct: true));
  final row = await db
      .customSelect(
        'SELECT COUNT(*) AS n FROM tracks t WHERE ${where.sql}',
        variables: where.vars,
        readsFrom: {db.tracks},
      )
      .getSingle();
  return row.read<int>('n');
}

/// The folders that hold the tracks of [scope], each with how many of them
/// sit directly in it; most files first.
Future<List<FolderRef>> foldersOf(AppDatabase db, SongScope scope) async {
  final where = SqlWhere()..add(visibleTrackWhere('t'));
  addScope(where, scope);
  final rows = await db
      .customSelect(
        'SELECT t.source_id, s.uid AS source_uid, s.name AS source_name, '
        '$_dirSql AS dir, COUNT(*) AS n '
        'FROM tracks t JOIN sources s ON s.id = t.source_id '
        'WHERE ${where.sql} GROUP BY t.source_id, dir',
        variables: where.vars,
        readsFrom: {db.tracks, db.trackArtists, db.sources},
      )
      .get();
  final out = [
    for (final r in rows)
      FolderRef(
        sourceId: r.read<int>('source_id'),
        sourceUid: r.read<String>('source_uid'),
        folderKey: r.read<String>('dir'),
        name: r.read<String>('dir').isEmpty
            ? r.read<String>('source_name')
            : _lastSegment(r.read<String>('dir')),
        songCount: r.read<int>('n'),
      ),
  ];
  out.sort((a, b) {
    final c = b.songCount.compareTo(a.songCount);
    return c != 0 ? c : a.folderKey.compareTo(b.folderKey);
  });
  return out;
}

/// File facts of [id] for the song info page; null when the track is gone.
Future<SongInfo?> songInfo(AppDatabase db, TrackId id) async {
  final row = await db
      .customSelect(
        'SELECT t.locator, t.rel_path, t.codec, t.bitrate, t.sample_rate, '
        't.bit_depth, t.size_bytes, m.root AS mount_root, '
        'coalesce(ps.play_count, 0) AS plays FROM tracks t '
        'LEFT JOIN source_mounts m ON m.source_id = t.source_id '
        'LEFT JOIN play_stats ps ON ps.track_id = t.id WHERE t.id = ?',
        variables: [Variable.withInt(id.value)],
        readsFrom: {db.tracks, db.sourceMounts, db.playStats},
      )
      .getSingleOrNull();
  if (row == null) return null;
  final locator = row.read<String>('locator');
  final root = row.readNullable<String>('mount_root');
  final base = root == null
      ? null
      : (root.endsWith('/') ? root.substring(0, root.length - 1) : root);
  return SongInfo(
    format:
        row.readNullable<String>('codec') ??
        formatFromLocator(row.read<String>('rel_path')),
    bitrate: row.readNullable<int>('bitrate'),
    sampleRate: row.readNullable<int>('sample_rate'),
    bitDepth: row.readNullable<int>('bit_depth'),
    sizeBytes: row.readNullable<int>('size_bytes'),
    path: base == null ? null : '$base/${locator.replaceFirst(_cueSuffix, '')}',
    playCount: row.read<int>('plays'),
  );
}

/// Total duration of the visible tracks among [ids], and the ids that are
/// not visible (gone, hidden, missing). Reads in chunks, never rows.
Future<({int durationMs, List<TrackId> absent})> selectionDuration(
  AppDatabase db,
  List<TrackId> ids,
) async {
  var total = 0;
  final absent = <TrackId>[];
  for (var i = 0; i < ids.length; i += _chunk) {
    final chunk = ids.sublist(
      i,
      i + _chunk > ids.length ? ids.length : i + _chunk,
    );
    final rows = await db
        .customSelect(
          'SELECT t.id, t.duration_ms FROM tracks t WHERE ${visibleTrackWhere('t')} '
          'AND t.id IN (${List.filled(chunk.length, '?').join(',')})',
          variables: [for (final id in chunk) Variable.withInt(id.value)],
          readsFrom: {db.tracks},
        )
        .get();
    final present = <int>{};
    for (final r in rows) {
      present.add(r.read<int>('id'));
      total += r.readNullable<int>('duration_ms') ?? 0;
    }
    for (final id in chunk) {
      if (!present.contains(id.value)) absent.add(id);
    }
  }
  return (durationMs: total, absent: absent);
}
