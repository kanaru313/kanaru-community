import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../../foundation/ordering/fractional_keys.dart';
import '../../media/domain/track_id.dart';
import '../domain/favorites.dart';

const _favoritesName = 'Favorites';
const _chunk = 500;

class FavoritesRepository implements FavoritesController {
  FavoritesRepository(this._db, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final int Function() _now;

  /// Ids of every favorite track, live. One query for the whole set.
  Stream<Set<TrackId>> watchIds() => _db
      .customSelect(
        'SELECT e.track_id FROM playlist_entries e '
        'JOIN playlists p ON p.id = e.playlist_id '
        'WHERE p.uid = ? AND p.deleted_at IS NULL AND e.deleted_at IS NULL',
        variables: [Variable.withString(favoritesPlaylistUid)],
        readsFrom: {_db.playlistEntries, _db.playlists},
      )
      .watch()
      .map((rows) => {for (final r in rows) TrackId(r.read<int>('track_id'))})
      .distinct(_sameSet);

  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) {
    final ids = {for (final t in tracks) t.value}.toList();
    if (ids.isEmpty) return Future.value();
    return _db.transaction(() => favorite ? _add(ids) : _remove(ids));
  }

  @override
  Future<void> toggle(TrackId track) => _db.transaction(() async {
    final live = await _liveFavorites([track.value]);
    await (live.isEmpty ? _add([track.value]) : _remove([track.value]));
  });

  Future<void> _remove(List<int> ids) async {
    await for (final chunk in _chunks(ids)) {
      await _db.customUpdate(
        'DELETE FROM playlist_entries WHERE track_id IN '
        '(${_marks(chunk)}) AND playlist_id IN '
        '(SELECT id FROM playlists WHERE uid = ? AND deleted_at IS NULL)',
        variables: [
          for (final id in chunk) Variable.withInt(id),
          Variable.withString(favoritesPlaylistUid),
        ],
        updates: {_db.playlistEntries},
        updateKind: UpdateKind.delete,
      );
    }
  }

  Future<void> _add(List<int> ids) async {
    final uids = await _trackUids(ids);
    final unknown = ids.where((id) => !uids.containsKey(id)).toList();
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(unknown, 'tracks', 'no such track');
    }
    final live = await _liveFavorites(ids);
    final missing = [
      for (final id in ids)
        if (!live.contains(id)) id,
    ];
    if (missing.isEmpty) return;
    final now = _now();
    await _dropStaleEntriesOfDeletedPlaylist();
    final playlist = await insertOrRevive(
      _db,
      _db.playlists,
      PlaylistsCompanion.insert(
        uid: favoritesPlaylistUid,
        name: _favoritesName,
        kind: const Value(PlaylistKind.favorites),
        createdAt: now,
        updatedAt: now,
      ),
      now: now,
    );
    final last = await _db
        .customSelect(
          'SELECT MAX(sort_key) AS k FROM playlist_entries '
          'WHERE playlist_id = ? AND deleted_at IS NULL',
          variables: [Variable.withInt(playlist.id)],
        )
        .getSingle();
    final keys = generateNKeysBetween(
      last.readNullable<String>('k'),
      null,
      missing.length,
    );
    for (var i = 0; i < missing.length; i++) {
      await insertOrRevive(
        _db,
        _db.playlistEntries,
        PlaylistEntriesCompanion.insert(
          uid: favoriteEntryUid(favoritesPlaylistUid, uids[missing[i]]!),
          playlistId: playlist.id,
          trackId: missing[i],
          sortKey: keys[i],
          addedAt: now,
          updatedAt: now,
        ),
        now: now,
        reviveColumns: {'sort_key', 'added_at'},
      );
    }
  }

  /// A tombstoned Favorites playlist is revived by the next favorite; its
  /// old entries must not come back with it.
  Future<void> _dropStaleEntriesOfDeletedPlaylist() => _db.customUpdate(
    'DELETE FROM playlist_entries WHERE playlist_id IN '
    '(SELECT id FROM playlists WHERE uid = ? AND deleted_at IS NOT NULL)',
    variables: [Variable.withString(favoritesPlaylistUid)],
    updates: {_db.playlistEntries},
    updateKind: UpdateKind.delete,
  );

  Future<Map<int, String>> _trackUids(List<int> ids) async {
    final out = <int, String>{};
    await for (final chunk in _chunks(ids)) {
      final rows = await _db
          .customSelect(
            'SELECT id, uid FROM tracks WHERE id IN (${_marks(chunk)})',
            variables: [for (final id in chunk) Variable.withInt(id)],
          )
          .get();
      for (final r in rows) {
        out[r.read<int>('id')] = r.read<String>('uid');
      }
    }
    return out;
  }

  Future<Set<int>> _liveFavorites(List<int> ids) async {
    final out = <int>{};
    await for (final chunk in _chunks(ids)) {
      final rows = await _db
          .customSelect(
            'SELECT e.track_id FROM playlist_entries e '
            'JOIN playlists p ON p.id = e.playlist_id '
            'WHERE p.uid = ? AND p.deleted_at IS NULL AND e.deleted_at IS NULL '
            'AND e.track_id IN (${_marks(chunk)})',
            variables: [
              Variable.withString(favoritesPlaylistUid),
              for (final id in chunk) Variable.withInt(id),
            ],
          )
          .get();
      out.addAll(rows.map((r) => r.read<int>('track_id')));
    }
    return out;
  }
}

/// Chunks of at most [_chunk] ids; yields to the event loop between chunks.
Stream<List<int>> _chunks(List<int> ids) async* {
  for (var i = 0; i < ids.length; i += _chunk) {
    if (i > 0) await Future<void>.delayed(Duration.zero);
    yield ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
  }
}

String _marks(List<int> ids) => List.filled(ids.length, '?').join(',');

bool _sameSet(Set<TrackId> a, Set<TrackId> b) =>
    a.length == b.length && a.containsAll(b);
