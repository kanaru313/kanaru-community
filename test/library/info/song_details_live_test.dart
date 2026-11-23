import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/info/song_details_query.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
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

  group('live updates', () {
    late List<SongDetails?> seen;
    late StreamSubscription<SongDetails?> sub;

    Future<int> watching(String locator) async {
      final id = await addTrack(db, source, locator: locator);
      seen = [];
      sub = watchSongDetails(db, TrackId(id)).listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      return id;
    }

    test('a track_details update emits the new value', () async {
      final id = await watching('a.mp3');
      await db
          .into(db.trackDetails)
          .insert(
            TrackDetailsCompanion.insert(
              trackId: Value(id),
              comment: const Value('one'),
            ),
          );
      await pumpEventQueue();
      await (db.update(db.trackDetails)..where((t) => t.trackId.equals(id)))
          .write(const TrackDetailsCompanion(comment: Value('two')));
      await pumpEventQueue();
      expect(seen.last!.comment, 'two');
    });

    test('a play_log insert emits the new playCount', () async {
      final id = await watching('a.mp3');
      expect(seen.last!.playCount, 0);
      await addPlay(db, id, playedAt: 5000);
      await pumpEventQueue();
      expect(seen.last!.playCount, 1);
      expect(seen.last!.lastPlayedAt, 5000);
      await addPlay(db, id, playedAt: 6000, skipped: true);
      await pumpEventQueue();
      expect(seen.last!.skipCount, 1);
    });

    test(
      'rows of other tracks and playlists leave the value unchanged',
      () async {
        await watching('a.mp3');
        final before = seen.length;
        final other = await addTrack(db, source, locator: 'b.mp3');
        final pl = await addPlaylist(db);
        await addEntry(db, pl, other, sortKey: 'a');
        await pumpEventQueue();
        expect(seen.length, before);
      },
    );

    test('an identical re-read is not emitted twice', () async {
      final id = await watching('a.mp3');
      final before = seen.length;
      // Rewrites the row with the same values: the table notifies, the
      // mapped value is equal.
      await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
        const TracksCompanion(title: Value('Title')),
      );
      await pumpEventQueue();
      expect(seen.length, before);
    });

    test('artists changed emit the new list', () async {
      final id = await watching('a.mp3');
      await artists(id, ['One', 'Two']);
      await pumpEventQueue();
      expect([for (final a in seen.last!.artists) a.name], ['One', 'Two']);
    });

    test('hiding the track emits null', () async {
      final id = await watching('a.mp3');
      await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
        const TracksCompanion(status: Value(TrackStatus.hidden)),
      );
      await pumpEventQueue();
      expect(seen.last, isNull);
    });
  });
}
