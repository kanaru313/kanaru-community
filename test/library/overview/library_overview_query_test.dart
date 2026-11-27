import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/library_overview_query.dart';

import '../../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late int source;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    source = await addSource(db);
  });

  /// A track with album keys, length and artist keys set.
  Future<int> song(
    String locator, {
    String status = TrackStatus.present,
    int? durationMs,
    String? albumArtist,
    String? album,
    List<String> artists = const [],
  }) async {
    final id = await addTrack(db, source, locator: locator, status: status);
    await db.customStatement(
      'UPDATE tracks SET duration_ms = ?, album_artist_key = ?, '
      'album_title_key = ? WHERE id = ?',
      [durationMs, albumArtist, album, id],
    );
    for (var i = 0; i < artists.length; i++) {
      await db.customStatement(
        'INSERT INTO track_artists (track_id, artist_key, artist_name, '
        'position) VALUES (?, ?, ?, ?)',
        [id, artists[i], artists[i], i],
      );
    }
    return id;
  }

  test('empty library is all zeros', () async {
    final o = await LibraryOverviewQuery(db).read();
    expect(
      [o.songs, o.albums, o.artists, o.playlists, o.totalDurationMs],
      [0, 0, 0, 0, 0],
    );
  });

  test('counts only visible tracks and ignores null lengths', () async {
    await song(
      'a',
      durationMs: 1000,
      albumArtist: 'ed',
      album: 'x',
      artists: ['ed'],
    );
    await song(
      'b',
      durationMs: 2500,
      albumArtist: 'ed',
      album: 'x',
      artists: ['ed', 'the weeknd'],
    );
    await song('c', artists: ['abba']);
    await song(
      'hidden',
      status: TrackStatus.hidden,
      durationMs: 9000,
      albumArtist: 'z',
      album: 'z',
      artists: ['z'],
    );
    await song(
      'gone',
      status: TrackStatus.missing,
      durationMs: 9000,
      artists: ['q'],
    );
    final dup = await song('dup', durationMs: 9000, artists: ['d']);
    await db.customStatement('UPDATE tracks SET dup_hidden = 1 WHERE id = ?', [
      dup,
    ]);

    final o = await LibraryOverviewQuery(db).read();
    expect(o.songs, 3);
    expect(o.albums, 1);
    expect(o.artists, 3);
    expect(o.totalDurationMs, 3500);
  });

  test('playlists exclude favorites, saved queues and mood', () async {
    await addPlaylist(db, uid: 'favorites', kind: PlaylistKind.favorites);
    await addPlaylist(db, uid: 'mine-1');
    await addPlaylist(db, uid: 'mine-2');
    await addPlaylist(db, uid: 'q-1', kind: PlaylistKind.queue);
    await addPlaylist(db, uid: 'm-1', kind: PlaylistKind.mood, nameKey: 'm');
    final deleted = await addPlaylist(db, uid: 'old');
    await db.customStatement(
      'UPDATE playlists SET deleted_at = 5 WHERE id = ?',
      [deleted],
    );

    expect((await LibraryOverviewQuery(db).read()).playlists, 2);
  });
}
