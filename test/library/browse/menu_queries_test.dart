import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/browse/menu_queries.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
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
    src = await addSource(db, name: 'My Music');
  });

  Future<int> add(
    String locator, {
    List<String> artists = const [],
    String? album,
    String? albumArtist,
    int? durationMs,
    String status = TrackStatus.present,
  }) => addLibraryTrack(
    db,
    source: src,
    locator: locator,
    artists: artists,
    album: album,
    albumArtist: albumArtist,
    durationMs: durationMs,
    status: status,
  );

  group('track links', () {
    test('album, artists in tag order, folder', () async {
      await add(
        'Lossless/Hi-Res/1.flac',
        artists: ['Zed', 'Abe'],
        album: 'Al',
        albumArtist: 'Zed',
      );
      final id = await add(
        'Lossless/Hi-Res/2.flac',
        artists: ['Zed', 'Abe'],
        album: 'Al',
        albumArtist: 'Zed',
      );
      final l = (await trackLinks(db, TrackId(id)))!;
      expect(l.albumKey, AlbumKey('zed', 'al'));
      expect(l.albumTitle, 'Al');
      expect(l.artists.map((a) => a.name), ['Zed', 'Abe']);
      expect(l.artists.first.key, ArtistKey('zed'));
      expect(l.albumArtists, isEmpty);
      expect(l.folder.folderKey, 'Lossless/Hi-Res');
      expect(l.folder.name, 'Hi-Res');
      expect(l.folder.songCount, 2);
      expect(l.folder.sourceId, src);
    });

    test('album artist shows only when no track artist is it', () async {
      final various = await add(
        '1.flac',
        artists: ['A', 'B'],
        album: 'Mix',
        albumArtist: 'Various',
      );
      final inside = await add(
        '2.flac',
        artists: ['A', 'B'],
        album: 'Mix',
        albumArtist: 'a',
      );
      expect(
        (await trackLinks(db, TrackId(various)))!.albumArtists.single.name,
        'Various',
      );
      expect((await trackLinks(db, TrackId(inside)))!.albumArtists, isEmpty);
    });

    test('no album, root folder takes the source name', () async {
      final id = await add('loose.flac', artists: ['A']);
      final l = (await trackLinks(db, TrackId(id)))!;
      expect(l.albumKey, isNull);
      expect(l.albumTitle, isNull);
      expect(l.folder.folderKey, '');
      expect(l.folder.name, 'My Music');
    });

    test('gone or hidden track gives null', () async {
      final hidden = await add('h.flac', status: TrackStatus.hidden);
      expect(await trackLinks(db, TrackId(hidden)), isNull);
      expect(await trackLinks(db, const TrackId(999)), isNull);
    });
  });

  test('folders of a scope: counts per folder, most files first', () async {
    await add('CD1/1.flac', artists: ['A'], album: 'Al', albumArtist: 'A');
    await add('CD1/2.flac', artists: ['A'], album: 'Al', albumArtist: 'A');
    await add('CD2/3.flac', artists: ['A'], album: 'Al', albumArtist: 'A');
    await add('3.flac', artists: ['A'], album: 'Al', albumArtist: 'A');
    await add('CD1/other.flac', artists: ['B'], album: 'Else');
    final f = await foldersOf(db, SongScope.album(AlbumKey('a', 'al')));
    expect(f.map((r) => (r.folderKey, r.name, r.songCount)), [
      ('CD1', 'CD1', 2),
      ('', 'My Music', 1),
      ('CD2', 'CD2', 1),
    ]);
  });

  group('song info', () {
    test('absolute path from the mount root, size null when unknown', () async {
      await addMount(db, src, root: '/home/me/Music/');
      final id = await add('Rock/a.flac');
      final i = (await songInfo(db, TrackId(id)))!;
      expect(i.path, '/home/me/Music/Rock/a.flac');
      expect(i.sizeBytes, isNull);
      expect(i.format, 'FLAC');
      expect(i.playCount, 0);
    });

    test('codec, sizes, plays, CUE suffix', () async {
      await addMount(db, src, root: '/m');
      final id = await add('Rock/b.flac#2');
      await db.customUpdate(
        'UPDATE tracks SET codec = ?, size_bytes = 99, bitrate = 900, '
        'sample_rate = 44100, bit_depth = 16 WHERE id = ?',
        variables: [Variable.withString('ALAC'), Variable.withInt(id)],
        updates: {db.tracks},
      );
      await addPlays(db, id, 3);
      final i = (await songInfo(db, TrackId(id)))!;
      expect(i.path, '/m/Rock/b.flac');
      expect(
        (i.format, i.sizeBytes, i.bitrate, i.sampleRate, i.bitDepth),
        ('ALAC', 99, 900, 44100, 16),
      );
      expect(i.playCount, 3);
    });

    test('no mount: no path; unknown track: null', () async {
      final id = await add('a.flac');
      expect((await songInfo(db, TrackId(id)))!.path, isNull);
      expect(await songInfo(db, const TrackId(999)), isNull);
    });
  });

  group('selection duration', () {
    test('sums visible tracks and reports the others', () async {
      final a = await add('a.flac', durationMs: 100);
      final b = await add('b.flac', durationMs: 20);
      final none = await add('c.flac');
      final hidden = await add(
        'h.flac',
        durationMs: 5,
        status: TrackStatus.hidden,
      );
      final r = await selectionDuration(db, [
        for (final i in [a, b, none, hidden, 999]) TrackId(i),
      ]);
      expect(r.durationMs, 120);
      expect(r.absent, [TrackId(hidden), const TrackId(999)]);
    });

    test('20k ids are read in chunks without loading rows', () async {
      final a = await add('a.flac', durationMs: 7);
      final ids = [TrackId(a), for (var i = 1000; i < 21000; i++) TrackId(i)];
      final r = await selectionDuration(db, ids);
      expect(r.durationMs, 7);
      expect(r.absent, hasLength(20000));
    });
  });
}
