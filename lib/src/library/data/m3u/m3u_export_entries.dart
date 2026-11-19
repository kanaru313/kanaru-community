import 'package:drift/drift.dart' show Variable;

import '../../../database/database.dart';
import '../../domain/playlists/playlist_ids.dart';

final _cueLocator = RegExp(r'#\d+$');

/// One playlist entry as the exporter needs it.
class M3uExportEntry {
  const M3uExportEntry({
    required this.trackId,
    required this.root,
    required this.locator,
    required this.title,
    this.artist,
    this.durationMs,
  });

  final int trackId;

  /// Local root of the track's source; null for a remote or plugin source.
  final String? root;
  final String locator;
  final String title;
  final String? artist;
  final int? durationMs;

  /// Absolute file path; null when the entry has no file of its own (remote
  /// source, or a CUE track whose locator ends in `#<n>`).
  String? get absolutePath {
    final r = root;
    if (r == null || _cueLocator.hasMatch(locator)) return null;
    return r.endsWith('/') ? '$r$locator' : '$r/$locator';
  }
}

/// The live entries of [playlistUid] in playlist order (the order of
/// `PlaylistStore.loadPlaylist`); null when the playlist is gone. Favorites
/// always exists. Tombstoned sources count: their mount row survives.
Future<List<M3uExportEntry>?> loadM3uExportEntries(
  AppDatabase db,
  String playlistUid,
) => db.transaction(() async {
  final playlist = await db
      .customSelect(
        'SELECT id FROM playlists WHERE uid = ? AND deleted_at IS NULL',
        variables: [Variable.withString(playlistUid)],
      )
      .get();
  if (playlist.isEmpty) {
    return playlistUid == PlaylistUids.favorites
        ? const <M3uExportEntry>[]
        : null;
  }
  final rows = await db
      .customSelect(
        'SELECT t.id AS id, m.root AS root, t.locator, t.title, t.artist, t.duration_ms '
        'FROM playlist_entries e JOIN tracks t ON t.id = e.track_id '
        'LEFT JOIN source_mounts m ON m.source_id = t.source_id '
        'WHERE e.playlist_id = ? AND e.deleted_at IS NULL '
        'ORDER BY e.sort_key, e.uid',
        variables: [Variable.withInt(playlist.single.read<int>('id'))],
      )
      .get();
  return [
    for (final r in rows)
      M3uExportEntry(
        trackId: r.read<int>('id'),
        root: r.readNullable<String>('root'),
        locator: r.read<String>('locator'),
        title: r.read<String>('title'),
        artist: r.readNullable<String>('artist'),
        durationMs: r.readNullable<int>('duration_ms'),
      ),
  ];
});
