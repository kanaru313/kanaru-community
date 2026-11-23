import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/info/song_details_query.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
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

  test(
    'an album without an album artist tag has no album artist key',
    () async {
      final id = await addTrack(db, source, locator: 'a.mp3', title: 'Solo');
      await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
        const TracksCompanion(
          album: Value('Album'),
          albumArtistKey: Value('amy'),
          albumTitleKey: Value('album'),
        ),
      );
      final d = (await read(id))!;
      expect(d.albumArtist, isNull);
      expect(d.albumArtistKey, isNull);
      expect(d.albumKey, AlbumKey('amy', 'album'));
    },
  );

  test('a track without an album seeds its cover with the title', () async {
    final id = await addTrack(db, source, locator: 'a.mp3', title: 'Solo');
    expect((await read(id))!.coverSeed, 'Solo');
  });
}
