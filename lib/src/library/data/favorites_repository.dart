import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../../media/domain/track_id.dart';
import '../domain/favorites.dart';
import 'playlists/favorite_entries.dart';

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
    var removed = 0;
    await for (final chunk in _chunks(ids)) {
      removed += await _db.customUpdate(
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
    if (removed == 0) return;
    // Same strictly-increasing rule as every other playlist write.
    await _db.customUpdate(
      'UPDATE playlists SET updated_at = MAX(?, updated_at + 1) '
      'WHERE uid = ?',
      variables: [
        Variable.withInt(_now()),
        Variable.withString(favoritesPlaylistUid),
      ],
      updates: {_db.playlists},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> _add(List<int> ids) =>
      appendFavoriteEntries(_db, ids, _now()).then((_) {});

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
