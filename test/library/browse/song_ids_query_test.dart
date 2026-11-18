import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/browse/song_ids_query.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

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
    String? title,
    List<String> artists = const [],
    String? album,
    int? year,
    int? durationMs,
    int addedAt = 1000,
    String? genre,
    String? language,
    int? trackNo,
    int? discNo,
    String status = TrackStatus.present,
    String? albumArtist,
  }) => addLibraryTrack(
    db,
    source: src,
    locator: locator,
    title: title,
    artists: artists,
    album: album,
    albumArtist: albumArtist,
    year: year,
    durationMs: durationMs,
    addedAt: addedAt,
    genre: genre,
    language: language,
    trackNo: trackNo,
    discNo: discNo,
    status: status,
  );

  Future<List<int>> ids(
    SongScope scope,
    SortOrder sort, [
    String filter = '',
  ]) async => [
    for (final id in await songIds(db, scope, sort, filter)) id.value,
  ];

  const all = SongScope.all();
  SortOrder asc(SortCriterion c) => SortOrder.by(c);
  SortOrder desc(SortCriterion c) => SortOrder.by(c, descending: true);

  test('title sort orders by folded title, ties by id', () async {
    final b = await add('b.flac', title: 'beta');
    final a = await add('a.flac', title: 'Đảo');
    final c = await add('c.flac', title: 'Alpha');
    final d = await add('d.flac', title: 'alpha');
    expect(await ids(all, asc(SortCriterion.title)), [c, d, b, a]);
    expect(await ids(all, desc(SortCriterion.title)), [a, b, c, d]);
  });

  group('nullable keys sort NULL last in both directions', () {
    for (final entry in {
      SortCriterion.year: (int i) =>
          add('y$i.flac', year: [2000, null, 1990][i]),
      SortCriterion.duration: (int i) =>
          add('d$i.flac', durationMs: [200, null, 100][i]),
      SortCriterion.artist: (int i) => add(
        'a$i.flac',
        artists: [
          ['Mia'],
          <String>[],
          ['Abe'],
        ][i],
      ),
      SortCriterion.album: (int i) =>
          add('l$i.flac', album: ['Mia', null, 'Abe'][i]),
    }.entries) {
      test(entry.key.name, () async {
        final first = await entry.value(0);
        final none = await entry.value(1);
        final last = await entry.value(2);
        expect(await ids(all, asc(entry.key)), [last, first, none]);
        expect(await ids(all, desc(entry.key)), [first, last, none]);
      });
    }
  });

  test('track number sorts disc then track, NULL last', () async {
    final d2t1 = await add('1.flac', discNo: 2, trackNo: 1);
    final d1t2 = await add('2.flac', discNo: 1, trackNo: 2);
    final d1t1 = await add('3.flac', discNo: 1, trackNo: 1);
    final none = await add('4.flac');
    expect(await ids(all, asc(SortCriterion.trackNumber)), [
      d1t1,
      d1t2,
      d2t1,
      none,
    ]);
    expect(await ids(all, desc(SortCriterion.trackNumber)), [
      d2t1,
      d1t2,
      d1t1,
      none,
    ]);
  });

  test('date added and play count', () async {
    final old = await add('o.flac', addedAt: 10);
    final mid = await add('m.flac', addedAt: 20);
    final fresh = await add('f.flac', addedAt: 30);
    expect(await ids(all, asc(SortCriterion.dateAdded)), [old, mid, fresh]);
    expect(await ids(all, desc(SortCriterion.dateAdded)), [fresh, mid, old]);
    await addPlays(db, mid, 3);
    await addPlays(db, old, 1);
    expect(await ids(all, desc(SortCriterion.playCount)), [mid, old, fresh]);
    // Unplayed tracks count 0 and keep title order among themselves.
    expect(await ids(all, asc(SortCriterion.playCount)), [fresh, old, mid]);
  });

  group('several criteria', () {
    SortOrder order(List<SortSpec> specs) => SortOrder(specs);
    const artist = SortSpec(SortCriterion.artist);
    const yearDesc = SortSpec(SortCriterion.year, descending: true);

    test('artist ascending then year descending', () async {
      final b2000 = await add(
        '1.flac',
        title: 'x',
        artists: ['Bo'],
        year: 2000,
      );
      final a1990 = await add(
        '2.flac',
        title: 'y',
        artists: ['Abe'],
        year: 1990,
      );
      final a2010 = await add(
        '3.flac',
        title: 'z',
        artists: ['Abe'],
        year: 2010,
      );
      final b2005 = await add(
        '4.flac',
        title: 'w',
        artists: ['Bo'],
        year: 2005,
      );
      expect(await ids(all, order([artist, yearDesc])), [
        a2010,
        a1990,
        b2005,
        b2000,
      ]);
    });

    test(
      'a NULL artist stays last in both directions with a second key',
      () async {
        final none = await add('1.flac', title: 'a', year: 2020);
        final abe = await add('2.flac', title: 'b', artists: ['Abe'], year: 1);
        final bo = await add('3.flac', title: 'c', artists: ['Bo'], year: 1);
        const year = SortSpec(SortCriterion.year);
        expect(await ids(all, order([artist, year])), [abe, bo, none]);
        expect(
          await ids(
            all,
            order([
              const SortSpec(SortCriterion.artist, descending: true),
              year,
            ]),
          ),
          [bo, abe, none],
        );
      },
    );

    test('play count as second key joins the plays', () async {
      final a = await add('1.flac', title: 'a', artists: ['Abe']);
      final b = await add('2.flac', title: 'b', artists: ['Abe']);
      final c = await add('3.flac', title: 'c', artists: ['Bo']);
      await addPlays(db, b, 5);
      await addPlays(db, a, 1);
      await addPlays(db, c, 9);
      expect(
        await ids(
          all,
          order([
            artist,
            const SortSpec(SortCriterion.playCount, descending: true),
          ]),
        ),
        [b, a, c],
      );
    });

    test('track number then title still runs', () async {
      final second = await add('1.flac', title: 'a', discNo: 1, trackNo: 2);
      final first = await add('2.flac', title: 'z', discNo: 1, trackNo: 1);
      expect(
        await ids(
          all,
          order([
            const SortSpec(SortCriterion.trackNumber),
            const SortSpec(SortCriterion.title),
          ]),
        ),
        [first, second],
      );
    });

    test('reversing mirrors the order, ties keep title then id', () async {
      final a = await add('1.flac', title: 'beta', artists: ['Abe'], year: 1);
      final b = await add('2.flac', title: 'alpha', artists: ['Abe'], year: 1);
      final c = await add('3.flac', title: 'gamma', artists: ['Bo'], year: 1);
      final forward = order([artist, const SortSpec(SortCriterion.year)]);
      expect(await ids(all, forward), [b, a, c]);
      // Directions flip; the equal pair (a, b) keeps title order.
      expect(await ids(all, forward.reversed()), [c, b, a]);
    });
  });

  group('filter', () {
    test('plain text matches a name with accents (son tung)', () async {
      final id = await add('1.flac', title: 'x', artists: ['Sơn Tùng']);
      await add('2.flac', title: 'y', artists: ['Other']);
      expect(await ids(all, asc(SortCriterion.title), 'son tung'), [id]);
    });
    test('ignores accents and case, matches title artist and album', () async {
      final vu = await add('1.flac', title: 'Sóng', artists: ['Vũ']);
      final al = await add('2.flac', title: 'Other', album: 'Vũ Trụ');
      await add('3.flac', title: 'Nothing');
      expect(await ids(all, asc(SortCriterion.title), 'vu'), [al, vu]);
      expect(await ids(all, asc(SortCriterion.title), 'SONG'), [vu]);
    });

    test('tokens are ANDed and may sit in different fields', () async {
      final hit = await add('1.flac', title: 'Sóng', artists: ['Vũ']);
      await add('2.flac', title: 'Sóng', artists: ['Other']);
      expect(await ids(all, asc(SortCriterion.title), 'vu  song'), [hit]);
    });

    test('percent and underscore are literal', () async {
      final pct = await add('1.flac', title: '100% pure');
      final und = await add('2.flac', title: 'a_b');
      await add('3.flac', title: 'axb');
      expect(await ids(all, asc(SortCriterion.title), '%'), [pct]);
      expect(await ids(all, asc(SortCriterion.title), 'a_b'), [und]);
      expect(await ids(all, asc(SortCriterion.title), "'; DROP"), isEmpty);
    });

    test('a token does not match across two fields', () async {
      await add('1.flac', title: 'ab', artists: ['cd']);
      expect(await ids(all, asc(SortCriterion.title), 'bc'), isEmpty);
    });

    test('blank filter keeps everything', () async {
      await add('1.flac');
      expect(await ids(all, asc(SortCriterion.title), '   '), hasLength(1));
    });
  });

  test('hidden and missing tracks are excluded', () async {
    final ok = await add('ok.flac');
    await add('h.flac', status: TrackStatus.hidden);
    await add('m.flac', status: TrackStatus.missing);
    expect(await ids(all, asc(SortCriterion.title)), [ok]);
    expect(await songCount(db, all), 1);
  });

  group('scopes', () {
    test('album, artist, genre, language', () async {
      final a1 = await add(
        '1.flac',
        artists: ['Vũ', 'Mia'],
        album: 'Al',
        albumArtist: 'Vũ',
        genre: 'Pop',
        language: 'vi',
        trackNo: 1,
      );
      final a2 = await add(
        '2.flac',
        artists: ['Mia'],
        album: 'Al',
        albumArtist: 'Vũ',
        genre: 'Rock',
        trackNo: 2,
      );
      final other = await add('3.flac', artists: ['Zed'], album: 'Al');
      final order = asc(SortCriterion.trackNumber);
      expect(await ids(SongScope.album(AlbumKey('vũ', 'al')), order), [a1, a2]);
      expect(await ids(SongScope.album(AlbumKey('zed', 'al')), order), [other]);
      expect(await ids(SongScope.artist(ArtistKey('mia')), order), [a1, a2]);
      expect(await ids(SongScope.artist(ArtistKey('vũ')), order), [a1]);
      expect(await ids(const SongScope.genre('pop'), order), [a1]);
      expect(await ids(const SongScope.language('vie'), order), [a1]);
      expect(await ids(const SongScope.language(null), order), [a2, other]);
    });

    test('folder: direct vs deep, siblings with a shared prefix', () async {
      final live1 = await add('Live/1.flac');
      final live2 = await add('Live/sub/2.flac');
      final albums = await add('Live Albums/3.flac');
      final top = await add('top.flac');
      // Non-BMP characters: UTF-16 length differs from SQLite's character count.
      final emoji = await add('🎵🎵/x.flac');
      await add('🎵🎵/A/y.flac');
      final order = asc(SortCriterion.dateAdded);
      Future<List<int>> folder(String key, {bool direct = false}) =>
          ids(SongScope.folder(src, key, direct: direct), order);
      expect(await folder('Live'), [live1, live2]);
      expect(await folder('Live', direct: true), [live1]);
      expect(await folder('Live Albums'), [albums]);
      expect(await folder('Live/sub', direct: true), [live2]);
      expect(await folder('🎵🎵', direct: true), [emoji]);
      expect((await folder('')).length, 6);
      expect(await folder('', direct: true), [top]);
      expect(await ids(SongScope.folder(src + 1, ''), order), isEmpty);
    });
  });

  test('songCount counts the scope without a filter', () async {
    await add('1.flac', genre: 'Pop');
    await add('2.flac', genre: 'Pop');
    await add('3.flac', genre: 'Rock');
    expect(await songCount(db, const SongScope.genre('pop')), 2);
    expect(await songCount(db, const SongScope.all()), 3);
  });

  test('a track criterion that songs cannot sort by throws', () {
    expect(
      songIds(db, all, asc(SortCriterion.trackCount), ''),
      throwsArgumentError,
    );
  });

  test('playlist-only criteria throw', () {
    for (final c in [
      SortCriterion.name,
      SortCriterion.dateModified,
      SortCriterion.playlistOrder,
    ]) {
      expect(songIds(db, all, asc(c), ''), throwsArgumentError, reason: '$c');
    }
  });

  test('result type is TrackId', () async {
    final id = await add('1.flac');
    expect(await songIds(db, all, asc(SortCriterion.title), ''), [TrackId(id)]);
  });
}
