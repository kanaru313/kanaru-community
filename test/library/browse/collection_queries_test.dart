import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/browse/album_artist_queries.dart';
import 'package:kanaru/src/library/data/browse/genre_language_queries.dart';
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
    String? displayArtist,
    String? genre,
    String? language,
    bool detected = false,
    int? year,
    int? durationMs,
    String? cover,
    int addedAt = 1000,
    String status = TrackStatus.present,
  }) => addLibraryTrack(
    db,
    source: src,
    locator: locator,
    artists: artists,
    album: album,
    albumArtist: albumArtist,
    albumDisplayArtist: displayArtist,
    genre: genre,
    language: language,
    languageDetected: detected,
    year: year,
    durationMs: durationMs,
    coverKey: cover,
    addedAt: addedAt,
    status: status,
  );

  group('albums', () {
    test('aggregate, ordered by stored sort key', () async {
      await add(
        '1.flac',
        album: 'Zulu',
        artists: ['A'],
        year: 2001,
        durationMs: 100,
        cover: 'c1',
        addedAt: 5,
      );
      await add(
        '2.flac',
        album: 'Zulu',
        artists: ['A'],
        year: 2003,
        durationMs: 50,
        addedAt: 9,
      );
      await add('3.flac', album: 'Đảo', artists: ['B']);
      final list = await albumSummaries(db);
      expect(list.map((a) => a.title), ['Đảo', 'Zulu']);
      final zulu = list.last;
      expect(zulu.trackCount, 2);
      expect(zulu.year, 2003);
      expect(zulu.durationMs, 150);
      expect(zulu.coverKey, 'c1');
      expect(zulu.addedAt, 9);
      expect(zulu.key, AlbumKey('a', 'zulu').encode());
    });

    test('a track without an album tag is not listed', () async {
      await add('1.flac', artists: ['A']);
      expect(await albumSummaries(db), isEmpty);
    });

    test(
      'display artist: display tag, album artist, then first artist',
      () async {
        await add(
          '1.flac',
          album: 'One',
          albumArtist: 'AA',
          displayArtist: 'AA & Co',
        );
        await add('2.flac', album: 'Two', albumArtist: 'AA');
        // No album artist: grouped by the first track artist; the lowest track
        // id decides, whatever the other tracks list.
        await add('3.flac', album: 'Three', artists: ['First', 'Second']);
        await add('4.flac', album: 'Three', artists: ['First', 'Other']);
        await add('5.flac', album: 'Four');
        final byTitle = {for (final a in await albumSummaries(db)) a.title: a};
        expect(byTitle['One']!.artist, 'AA & Co');
        expect(byTitle['Two']!.artist, 'AA');
        expect(byTitle['Three']!.artist, 'First');
        expect(byTitle['Four']!.artist, isNull);
      },
    );

    test('hidden tracks do not count', () async {
      await add('1.flac', album: 'X', artists: ['A']);
      await add(
        '2.flac',
        album: 'X',
        artists: ['A'],
        status: TrackStatus.hidden,
      );
      expect((await albumSummaries(db)).single.trackCount, 1);
    });
  });

  group('artists', () {
    test('a multi-artist track counts once for each artist', () async {
      await add('1.flac', artists: ['Vũ', 'Mia'], durationMs: 10);
      await add('2.flac', artists: ['Mia'], durationMs: 5);
      final by = {for (final a in await artistSummaries(db)) a.name: a};
      expect(by['Vũ']!.trackCount, 1);
      expect(by['Mia']!.trackCount, 2);
      expect(by['Mia']!.durationMs, 15);
      expect(by['Mia']!.key, ArtistKey('mia').encode());
    });

    test('album count and photo come from own albums only', () async {
      // Own albums of "mia" (album artist = mia).
      await add(
        '1.flac',
        artists: ['Mia'],
        album: 'Old',
        year: 2001,
        cover: 'old',
      );
      await add(
        '2.flac',
        artists: ['Mia'],
        album: 'New',
        year: 2020,
        cover: 'new',
      );
      await add('3.flac', artists: ['Mia'], album: 'Newest', year: 2022);
      // Appears on someone else's album: not an own album, not the photo.
      await add(
        '4.flac',
        artists: ['Mia', 'Zed'],
        album: 'Duet',
        albumArtist: 'Zed',
        year: 2030,
        cover: 'duet',
      );
      final by = {for (final a in await artistSummaries(db)) a.name: a};
      expect(by['Mia']!.albumCount, 3);
      // Newest album that has a cover; "Newest" has none.
      expect(by['Mia']!.coverKey, 'new');
      expect(by['Zed']!.albumCount, 1);
      expect(by['Zed']!.coverKey, 'duet');
    });

    test('an artist without own albums has none and no photo', () async {
      await add('1.flac', artists: ['Solo'], cover: 'x');
      final solo = (await artistSummaries(db)).single;
      expect(solo.albumCount, 0);
      expect(solo.coverKey, isNull);
    });
  });

  test('genres: grouped by key, tracks without genre absent', () async {
    await add('1.flac', genre: 'Pop');
    await add('2.flac', genre: 'pop');
    await add('3.flac', genre: 'Đồng quê');
    await add('4.flac');
    final list = await genreSummaries(db);
    expect(list.map((g) => g.key), ['đồng quê', 'pop']);
    expect(list.last.trackCount, 2);
  });

  test('languages: unknown group has a null code, detected counted', () async {
    await add('1.flac', language: 'vi', detected: true);
    await add('2.flac', language: 'vie');
    await add('3.flac', language: 'en', detected: true);
    await add('4.flac');
    await add('5.flac', language: 'und');
    final by = {for (final l in await languageSummaries(db)) l.code: l};
    expect(by['vie']!.trackCount, 2);
    expect(by['vie']!.detectedCount, 1);
    expect(by['eng']!.detectedCount, 1);
    expect(by[null]!.trackCount, 2);
    expect(by[null]!.detectedCount, 0);
  });
}
