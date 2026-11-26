import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../domain/playlists/playlist_import.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_store.dart';
import '../../domain/playlists/playlist_text_rules.dart';
import '../browse/throttled_query.dart';
import 'playlist_add_writes.dart';
import 'playlist_copy_writes.dart';
import 'playlist_edit_writes.dart';
import 'playlist_entry_writes.dart';
import 'playlist_import_writes.dart';
import 'playlist_reads.dart';
import 'playlist_sql.dart';

/// [PlaylistStore] on the `playlists` / `playlist_entries` tables. Every write
/// method is one transaction; [now] is injectable for tests.
class PlaylistRepository implements PlaylistStore {
  PlaylistRepository(this._db, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final int Function() _now;

  @override
  Stream<PlaylistSummaries> watchSummaries() => throttledQuery(
    _db,
    // `tracks` too: a scan writes covers and durations there. The value
    // equality below drops emissions that change nothing shown.
    {_db.playlists, _db.playlistEntries, _db.tracks},
    () => loadSummaries(_db),
    equals: (a, b) => a == b,
  );

  @override
  Stream<PlaylistDetail?> watchPlaylist(String uid) => throttledQuery(
    _db,
    {
      _db.playlists,
      _db.playlistEntries,
      _db.tracks,
      _db.trackArtists,
      _db.playStats,
    },
    () => loadDetail(_db, uid),
    equals: (a, b) => a == b,
  );

  @override
  Future<PlaylistDetail?> loadPlaylist(String uid) => loadDetail(_db, uid);

  @override
  Future<Map<String, int>> countExisting(List<TrackId> tracks) =>
      countExistingTracks(_db, tracks);

  @override
  Future<String> createPlaylist({
    required String name,
    String description = '',
    List<TrackId> tracks = const [],
  }) async {
    final cleanName = checkedPlaylistName(name);
    final cleanDescription = checkedPlaylistDescription(description);
    return _db.transaction(() async {
      final ids = [for (final t in tracks) t.value];
      await requireTracksExist(_db, ids);
      final now = _now();
      final id = await insertPlaylistRow(
        _db,
        name: cleanName,
        description: cleanDescription,
        now: now,
      );
      await appendEntries(_db, id, ids, now);
      return playlistUidOf(_db, id);
    });
  }

  @override
  Future<ImportedPlaylist> createImportedPlaylist({
    required String name,
    required List<ImportedEntry> entries,
  }) => _db.transaction(
    () => createImportedPlaylistWrite(
      _db,
      name: name,
      entries: entries,
      now: _now(),
    ),
  );

  @override
  Future<PlaylistUpdate> updatePlaylist(
    String uid, {
    String? name,
    String? description,
  }) async {
    if (uid == PlaylistUids.favorites && name != null) {
      throw ArgumentError.value(uid, 'uid', 'Favorites cannot be renamed');
    }
    final cleanName = name == null ? null : checkedPlaylistName(name);
    final cleanDescription = description == null
        ? null
        : checkedPlaylistDescription(description);
    return _db.transaction(
      () => updatePlaylistWrite(
        _db,
        uid,
        name: cleanName,
        description: cleanDescription,
        now: _now(),
      ),
    );
  }

  @override
  Future<bool> deletePlaylist(String uid) async {
    if (uid == PlaylistUids.favorites) {
      throw ArgumentError.value(uid, 'uid', 'Favorites cannot be deleted');
    }
    // The cover row goes with the playlist through a trigger.
    final deleted = await writeNotifyingOnChange(
      _db,
      'DELETE FROM playlists WHERE uid = ? AND deleted_at IS NULL '
      'AND kind IS NULL',
      [Variable.withString(uid)],
      {_db.playlists, _db.playlistEntries, _db.customCovers},
      UpdateKind.delete,
    );
    return deleted > 0;
  }

  @override
  Future<AddToPlaylistsResult> addToPlaylists({
    required List<TrackId> tracks,
    List<String> playlistUids = const [],
    List<String> newPlaylistNames = const [],
    DuplicatePolicy policy = DuplicatePolicy.skipExisting,
  }) => _db.transaction(
    () => addToPlaylistsWrite(
      _db,
      tracks: tracks,
      playlistUids: playlistUids,
      newPlaylistNames: newPlaylistNames,
      policy: policy,
      now: _now(),
    ),
  );

  @override
  Future<PlaylistMove> moveEntry(
    String playlistUid,
    String entryUid, {
    required String? afterEntryUid,
  }) => _db.transaction(
    () => moveEntryWrite(_db, playlistUid, entryUid, afterEntryUid, _now()),
  );

  @override
  Future<PlaylistRemoval?> removeEntries(
    String playlistUid,
    List<String> entryUids,
  ) => _db.transaction(
    () => removeEntriesWrite(_db, playlistUid, entryUids, _now()),
  );

  @override
  Future<PlaylistRemoval?> removeDuplicates(String playlistUid) =>
      _db.transaction(() => removeDuplicatesWrite(_db, playlistUid, _now()));

  @override
  Future<int> undoRemoval(PlaylistRemoval removal) =>
      _db.transaction(() => undoRemovalWrite(_db, removal, _now()));

  @override
  Future<void> commitRemoval(PlaylistRemoval removal) =>
      _db.transaction(() => commitRemovalWrite(_db, removal));

  @override
  Future<String?> duplicatePlaylist(
    String uid, {
    required String name,
    bool copyCover = false,
  }) async {
    // The caller builds "<name> (copy)": cut it to fit, keeping the suffix.
    final cleanName = capPlaylistName(cleanPlaylistName(name));
    if (cleanName.isEmpty) throw ArgumentError.value(name, 'name', 'empty');
    return _db.transaction(
      () => duplicatePlaylistWrite(
        _db,
        uid,
        name: cleanName,
        copyCover: copyCover,
        now: _now(),
      ),
    );
  }

  @override
  Future<AddToPlaylistsResult> addAllToFavorites(String uid) =>
      _db.transaction(() => addAllToFavoritesWrite(_db, uid, _now()));

  @override
  Future<Map<int, String>> resolvePlaylistIds(List<int> ids) async {
    final result = <int, String>{
      if (ids.contains(favoritesPlaylistId))
        favoritesPlaylistId: PlaylistUids.favorites,
    };
    final rowIds = ids.toSet()..remove(favoritesPlaylistId);
    if (rowIds.isEmpty) return result;
    final rows = await _db
        .customSelect(
          'SELECT id, uid FROM playlists WHERE id IN $jsonEach '
          'AND uid != ? AND $writablePlaylistPredicate',
          variables: [
            jsonList(rowIds),
            Variable.withString(PlaylistUids.favorites),
          ],
        )
        .get();
    for (final r in rows) {
      result[r.read<int>('id')] = r.read<String>('uid');
    }
    return result;
  }

  @override
  Future<List<WritablePlaylist>> listWritable() async {
    final rows = await _db
        .customSelect(
          'SELECT id, uid, name FROM playlists WHERE uid != ? '
          'AND $writablePlaylistPredicate ORDER BY created_at, id',
          variables: [Variable.withString(PlaylistUids.favorites)],
        )
        .get();
    return [
      const WritablePlaylist(
        id: favoritesPlaylistId,
        uid: PlaylistUids.favorites,
        name: 'Favorites',
      ),
      for (final r in rows)
        WritablePlaylist(
          id: r.read<int>('id'),
          uid: r.read<String>('uid'),
          name: r.read<String>('name'),
        ),
    ];
  }

  @override
  Future<Map<int, String>> resolveEntryIds(
    String playlistUid,
    List<int> entryIds,
  ) => _db.transaction(() async {
    final playlistId = await livePlaylistId(_db, playlistUid);
    if (playlistId == null || entryIds.isEmpty) return const <int, String>{};
    final rows = await _db
        .customSelect(
          'SELECT id, uid FROM playlist_entries WHERE playlist_id = ? '
          'AND deleted_at IS NULL AND id IN $jsonEach',
          variables: [Variable.withInt(playlistId), jsonList(entryIds.toSet())],
        )
        .get();
    return {for (final r in rows) r.read<int>('id'): r.read<String>('uid')};
  });

  @override
  Future<List<PlaylistEntryView>> removeEntriesNow(
    String playlistUid,
    List<String> entryUids,
  ) => _db.transaction(
    () => removeEntriesNowWrite(_db, playlistUid, entryUids, _now()),
  );
}
