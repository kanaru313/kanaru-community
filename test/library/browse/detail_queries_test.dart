import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/browse/detail_queries.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

import '../../database/support/test_db.dart';
import 'support/library_fixture.dart';

void main() {
  late AppDatabase db;
  late int src;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    src = await addSource(db);
  });

  Future<int> add(
    String locator, {
    List<String> artists = const [],
    String? album,
    String? albumArtist,
    String? genre,
    String? language,
    bool detected = false,
    int? year,
    int? durationMs,
  }) => addLibraryTrack(
    db,
    source: src,
    locator: locator,
    artists: artists,
    album: album,
    albumArtist: albumArtist,
    genre: genre,
    language: language,
    languageDetected: detected,
    year: year,
    durationMs: durationMs,
  );

  test(
    'artist albums: own newest first, appears-on from other artists',
    () async {
      await add('1.flac', artists: ['Mia'], album: 'Old', year: 2001);
      await add('2.flac', artists: ['Mia'], album: 'New', year: 2020);
      await add('3.flac', artists: ['Mia'], album: 'Undated');
      await add(
        '4.flac',
        artists: ['Mia', 'Zed'],
        album: 'Duet',
        albumArtist: 'Zed',
        year: 2030,
      );
      await add('5.flac', artists: ['Zed'], album: 'Own of Zed');
      await add(
        '6.flac',
        artists: ['Zed'],
        album: 'Duet',
        albumArtist: 'Zed',
        year: 2030,
      );
      final r = await artistAlbums(db, ArtistKey('mia'));
      expect(r.own.map((a) => a.title), ['New', 'Old', 'Undated']);
      expect(r.appears.map((a) => a.title), ['Duet']);
      // An appears-on album shows its whole size, not the artist's share.
      expect(r.appears.single.trackCount, 2);
      final zed = await artistAlbums(db, ArtistKey('zed'));
      expect(zed.own.map((a) => a.title), ['Duet', 'Own of Zed']);
      expect(zed.appears, isEmpty);
    },
  );

  test('group shelves: artists by track count, albums newest first', () async {
    await add('1.flac', artists: ['A'], album: 'X', year: 2000, genre: 'Pop');
    await add('2.flac', artists: ['A'], album: 'X', year: 2000, genre: 'Pop');
    await add('3.flac', artists: ['B'], album: 'Y', year: 2010, genre: 'Pop');
    await add('4.flac', artists: ['C'], album: 'Z', genre: 'Rock');
    final s = await groupShelves(db, const SongScope.genre('pop'));
    expect(s.artists.map((a) => (a.name, a.trackCount)), [('A', 2), ('B', 1)]);
    expect(s.albums.map((a) => a.title), ['Y', 'X']);
    // Counts inside the group only.
    expect(s.albums.last.trackCount, 2);
    final rock = await groupShelves(db, const SongScope.genre('rock'));
    expect(rock.albums.single.title, 'Z');
  });

  test('group totals with detected languages', () async {
    await add(
      '1.flac',
      artists: ['A', 'B'],
      language: 'vi',
      detected: true,
      durationMs: 100,
    );
    await add('2.flac', artists: ['A'], language: 'vi', durationMs: 50);
    await add('3.flac', artists: ['C'], language: 'en', durationMs: 7);
    final t = await groupTotals(db, const SongScope.language('vie'));
    expect((t.tracks, t.artists, t.durationMs, t.detected), (2, 2, 150, 1));
    final none = await groupTotals(db, const SongScope.language('xxx'));
    expect(
      (none.tracks, none.artists, none.durationMs, none.detected),
      (0, 0, 0, 0),
    );
    final unknown = await add('4.flac');
    expect(unknown, greaterThan(0));
    expect((await groupTotals(db, const SongScope.language(null))).tracks, 1);
  });
}
