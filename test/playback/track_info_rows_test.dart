import 'package:drift/drift.dart' show OrderingTerm, UpdateKind, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';

import '../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late int source;
  setUp(() async {
    db = openTestDb();
    source = await addSource(db);
  });
  tearDown(() => db.close());

  Future<void> artists(int track, List<String> names) async {
    for (var i = 0; i < names.length; i++) {
      await db
          .into(db.trackArtists)
          .insert(
            TrackArtistsCompanion.insert(
              trackId: track,
              artistKey: groupKey(names[i]),
              artistName: names[i],
              position: i,
            ),
          );
    }
  }

  test('artists keep tag order and play count comes from play_stats', () async {
    final id = await addTrack(db, source, locator: 'a/one.flac');
    await artists(id, ['Zed', 'Adam', 'Moe']);
    await addPlay(db, id, playedAt: 5);
    final info = (await loadTrackInfos(db, [TrackId(id)])).single;
    expect(info.artists, ['Zed', 'Adam', 'Moe']);
    expect(info.playCount, 1);
    expect(info.status, TrackAvailability.present);
  });

  test('format: codec column wins, else the locator extension', () async {
    final plain = await addTrack(db, source, locator: 'a/one.flac');
    final coded = await addTrack(db, source, locator: 'a/two.bin');
    await (db.update(db.tracks)..where((t) => t.id.equals(coded))).write(
      const TracksCompanion(codec: Value('OPUS')),
    );
    final cue = await addTrack(db, source, locator: 'a/disc.cue#02');
    final infos = await loadTrackInfos(db, [
      TrackId(plain),
      TrackId(coded),
      TrackId(cue),
    ]);
    expect(infos.map((i) => i.format), ['FLAC', 'OPUS', null]);
  });

  test('missing album gives a null album key; present album a key', () async {
    final none = await addTrack(db, source, locator: 'a.flac');
    final withAlbum = await addTrack(db, source, locator: 'b.flac');
    await (db.update(db.tracks)..where((t) => t.id.equals(withAlbum))).write(
      const TracksCompanion(
        album: Value('Hybrid  Theory'),
        albumArtist: Value('Linkin Park'),
        albumArtistKey: Value('linkin park'),
        albumTitleKey: Value('hybrid theory'),
      ),
    );
    final infos = await loadTrackInfos(db, [TrackId(none), TrackId(withAlbum)]);
    expect(infos[0].albumKey, isNull);
    expect(
      infos[1].albumKey,
      albumKeyFor(
        album: 'Hybrid Theory',
        albumArtist: 'Linkin Park',
        artists: const [],
      ),
    );
  });

  test('a track with album text but no stored keys has no album key', () async {
    final id = await addTrack(db, source, locator: 'k.flac');
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(album: Value('Only Text')),
    );
    expect((await loadTrackInfos(db, [TrackId(id)])).single.albumKey, isNull);
  });

  test('runs inside a transaction', () async {
    final id = await addTrack(db, source, locator: 't.flac', title: 'Tx');
    final infos = await db.transaction(() => loadTrackInfos(db, [TrackId(id)]));
    expect(infos.single.title, 'Tx');
  });

  test('keeps input order, repeats and drops unknown ids', () async {
    final a = await addTrack(db, source, locator: 'a.flac', title: 'A');
    final b = await addTrack(db, source, locator: 'b.flac', title: 'B');
    final infos = await loadTrackInfos(db, [
      TrackId(b),
      TrackId(9999),
      TrackId(a),
      TrackId(b),
    ]);
    expect(infos.map((i) => i.title), ['B', 'A', 'B']);
    expect(await loadTrackInfos(db, const []), isEmpty);
  });

  test('more ids than one chunk are all loaded in order', () async {
    final ids = <TrackId>[];
    await db.batch((b) {
      for (var i = 0; i < trackInfoChunkSize * 2 + 37; i++) {
        b.insert(
          db.tracks,
          TracksCompanion.insert(
            uid: 'trk-$i',
            sourceId: source,
            locator: 'f$i.mp3',
            relPath: 'f$i.mp3',
            title: 'T$i',
            addedAt: 1,
            updatedAt: 1,
          ),
        );
      }
    });
    final rows = await (db.select(
      db.tracks,
    )..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
    ids.addAll(rows.map((r) => TrackId(r.id)));
    final infos = await loadTrackInfos(db, ids);
    expect(infos.map((i) => i.id), ids);
  });

  test(
    'watchTrackInfo emits on change and null once the row is gone',
    () async {
      final id = await addTrack(db, source, locator: 'a.flac', title: 'Old');
      final events = <String?>[];
      final sub = watchTrackInfo(
        db,
        TrackId(id),
      ).listen((i) => events.add(i?.title));
      await pumpEventQueue();
      await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
        const TracksCompanion(title: Value('New')),
      );
      await pumpEventQueue();
      await db.customUpdate(
        'DELETE FROM tracks WHERE id = $id',
        updates: {db.tracks},
        updateKind: UpdateKind.delete,
      );
      await pumpEventQueue();
      await sub.cancel();
      expect(events, ['Old', 'New', null]);
    },
  );
}
