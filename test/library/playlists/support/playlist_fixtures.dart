import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../database/support/test_db.dart';

/// An in-memory database, a repository with a controllable clock and one
/// local source.
class PlaylistFixture {
  PlaylistFixture._(this.db, this.source);

  final AppDatabase db;
  final int source;
  int clock = 10000;
  late final PlaylistRepository repo = PlaylistRepository(db, now: () => clock);

  static Future<PlaylistFixture> open() async {
    final db = openTestDb();
    addTearDown(db.close);
    return PlaylistFixture._(db, await addSource(db, uid: 'src-pl'));
  }

  Future<TrackId> track(String name, {String? status}) async => TrackId(
    await addTrack(
      db,
      source,
      locator: '$name.flac',
      title: name,
      status: status ?? TrackStatus.present,
    ),
  );

  Future<List<TrackId>> tracks(int n) async => [
    for (var i = 0; i < n; i++) await track('t$i'),
  ];

  /// Live entries of [playlistUid]: (entry uid, track id) in playlist order.
  Future<List<({String uid, int track})>> live(String playlistUid) async => [
    for (final r
        in await db
            .customSelect(
              'SELECT e.uid, e.track_id FROM playlist_entries e '
              'JOIN playlists p ON p.id = e.playlist_id '
              'WHERE p.uid = ? AND e.deleted_at IS NULL '
              'ORDER BY e.sort_key, e.uid',
              variables: [Variable.withString(playlistUid)],
            )
            .get())
      (uid: r.read<String>('uid'), track: r.read<int>('track_id')),
  ];

  Future<List<int>> liveTracks(String playlistUid) async => [
    for (final e in await live(playlistUid)) e.track,
  ];

  /// Every sort key of the playlist (tombstones included).
  Future<List<String>> allKeys(String playlistUid) async => [
    for (final r
        in await db
            .customSelect(
              'SELECT e.sort_key FROM playlist_entries e '
              'JOIN playlists p ON p.id = e.playlist_id WHERE p.uid = ?',
              variables: [Variable.withString(playlistUid)],
            )
            .get())
      r.read<String>('sort_key'),
  ];

  void expectUniqueKeys(List<String> keys) =>
      expect(keys.toSet().length, keys.length, reason: 'equal sort keys');

  Future<int> updatedAt(String uid) async => (await (db.select(
    db.playlists,
  )..where((p) => p.uid.equals(uid))).getSingle()).updatedAt;
}
