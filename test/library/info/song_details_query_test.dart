import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/info/song_details_query.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
import 'package:kanaru/src/library/domain/tags/extra_tags.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late int source;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    source = await addSource(db, name: 'Nhạc');
    await addMount(db, source, root: '/home/u/Music/');
  });

  Future<SongDetails?> read(int id) => watchSongDetails(db, TrackId(id)).first;

  Future<void> artists(int id, List<String> names) async {
    for (var i = 0; i < names.length; i++) {
      await db
          .into(db.trackArtists)
          .insert(
            TrackArtistsCompanion.insert(
              trackId: id,
              artistKey: 'k-${names[i]}',
              artistName: names[i],
              position: i,
            ),
          );
    }
  }

  test('a present track gives every field', () async {
    final id = await addTrack(
      db,
      source,
      locator: 'Rock/Band/a.flac',
      title: 'Song',
      rating: 4,
    );
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(
        album: Value('Album'),
        albumArtist: Value('Band'),
        albumArtistKey: Value('band'),
        albumTitleKey: Value('album'),
        albumDisplayArtist: Value('The Band'),
        genre: Value('Rock'),
        genreKey: Value('rock'),
        composer: Value('Me'),
        language: Value('vi'),
        languageDetected: Value(1),
        year: Value(2019),
        trackNo: Value(3),
        trackTotal: Value(10),
        discNo: Value(1),
        discTotal: Value(2),
        durationMs: Value(215000),
        codec: Value('FLAC'),
        bitrate: Value(900),
        sampleRate: Value(44100),
        bitDepth: Value(16),
        channels: Value(2),
        sizeBytes: Value(123),
        mtimeMs: Value(777),
        coverKey: Value('cover'),
        scanError: Value('bad frame'),
      ),
    );
    await db
        .into(db.trackDetails)
        .insert(
          TrackDetailsCompanion.insert(
            trackId: Value(id),
            comment: const Value('note'),
            lrcLocator: const Value('Rock/Band/a.lrc'),
            extraTags: Value(
              encodeExtraTags(releaseDate: '2019-07-15', description: 'desc'),
            ),
          ),
        );
    final d = (await read(id))!;
    expect(d.title, 'Song');
    expect(d.id, TrackId(id));
    expect(d.albumArtist, 'Band');
    expect(d.genre, 'Rock');
    expect(d.coverSeed, AlbumKey('band', 'album').encode());
    expect(d.status, SongFileStatus.present);
    expect(d.missingSince, isNull);
    expect(d.album, 'Album');
    expect(d.albumKey, AlbumKey('band', 'album'));
    expect(d.albumArtistKey, ArtistKey('band'));
    expect(d.albumArtistDisplay, 'The Band');
    expect(d.genreKey, 'rock');
    expect(d.composer, 'Me');
    expect((d.language, d.languageDetected), ('vi', true));
    expect((d.year, d.releaseDate?.month, d.releaseDate?.day), (2019, 7, 15));
    expect((d.trackNo, d.trackTotal, d.discNo, d.discTotal), (3, 10, 1, 2));
    expect(d.comment, 'note');
    expect(d.description, 'desc');
    expect(d.lrcLocator, 'Rock/Band/a.lrc');
    expect((d.durationMs, d.codec, d.format), (215000, 'FLAC', 'FLAC'));
    expect(
      (d.bitrate, d.sampleRate, d.bitDepth, d.channels),
      (900, 44100, 16, 2),
    );
    expect(d.path, '/home/u/Music/Rock/Band/a.flac');
    expect(d.sourceRoot, '/home/u/Music');
    expect(d.sourceName, 'Nhạc');
    expect((d.folder.folderKey, d.folder.name), ('Rock/Band', 'Band'));
    expect((d.sizeBytes, d.mtimeMs, d.addedAt), (123, 777, 1000));
    expect(d.scanError, 'bad frame');
    expect(d.rating, 4);
    expect(d.coverKey, 'cover');
  });

  test('a track in the music folder root names the source as folder', () async {
    final id = await addTrack(db, source, locator: 'a.mp3');
    final d = (await read(id))!;
    expect((d.folder.folderKey, d.folder.name), ('', 'Nhạc'));
  });

  test('a missing track is read with its missingSince', () async {
    final id = await addTrack(
      db,
      source,
      locator: 'a.mp3',
      status: TrackStatus.missing,
      now: 555,
    );
    final d = (await read(id))!;
    expect(d.status, SongFileStatus.missing);
    expect(d.missingSince, 555);
    expect(d.path, '/home/u/Music/a.mp3');
  });

  test('hidden, remote and unknown tracks give null', () async {
    final hidden = await addTrack(
      db,
      source,
      locator: 'h.mp3',
      status: TrackStatus.hidden,
    );
    final remote = await addTrack(
      db,
      source,
      locator: 'r.mp3',
      status: TrackStatus.remote,
    );
    expect(await read(hidden), isNull);
    expect(await read(remote), isNull);
    expect(await read(9999), isNull);
  });

  test('no play_stats row gives zero counts and null dates', () async {
    final d = (await read(await addTrack(db, source, locator: 'a.mp3')))!;
    expect((d.playCount, d.skipCount), (0, 0));
    expect((d.firstPlayedAt, d.lastPlayedAt), (null, null));
    expect(d.comment, isNull);
    expect(d.releaseDate, isNull);
  });

  test('artists keep their position and the album artist stays', () async {
    final id = await addTrack(db, source, locator: 'a.mp3');
    await artists(id, ['Zed', 'Amy', 'Max']);
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(
        albumArtist: Value('Zed'),
        albumArtistKey: Value('k-Zed'),
      ),
    );
    final d = (await read(id))!;
    expect([for (final a in d.artists) a.name], ['Zed', 'Amy', 'Max']);
    expect(d.artists.first.key, ArtistKey('k-Zed'));
    expect(d.albumArtist, 'Zed');
    expect(d.albumArtistKey, ArtistKey('k-Zed'));
  });

  test('a cue suffix is stripped from the path and the format', () async {
    final id = await addTrack(db, source, locator: 'cd/album.flac#3');
    final d = (await read(id))!;
    expect(d.path, '/home/u/Music/cd/album.flac');
    expect(d.format, 'FLAC');
  });

  test('a source without a mount has no path', () async {
    final other = await addSource(db, name: 'Cloud');
    final id = await addTrack(db, other, locator: 'x/a.mp3');
    final d = (await read(id))!;
    expect((d.path, d.sourceRoot), (null, null));
    expect(d.sourceName, 'Cloud');
  });
}
