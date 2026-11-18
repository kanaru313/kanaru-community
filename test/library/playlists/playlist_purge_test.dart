import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/library/data/playlists/playlist_entry_writes.dart';
import 'package:kanaru/src/library/data/scan/track_gc_runner.dart';

import '../../database/support/test_db.dart';
import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  setUp(() async => f = await PlaylistFixture.open());

  test('purge deletes only tombstones at or before the bound', () async {
    final t = await f.tracks(3);
    final p = await f.repo.createPlaylist(name: 'P', tracks: t);
    final e = [for (final x in await f.live(p)) x.uid];
    f.clock = 20000;
    await f.repo.removeEntries(p, [e[0]]);
    f.clock = 30000;
    await f.repo.removeEntries(p, [e[1]]);
    expect(await purgeRemovedPlaylistEntries(f.db, before: 20000), 1);
    expect(await f.allKeys(p), hasLength(2));
    expect(await f.liveTracks(p), [t[2].value]);
  });

  test('runTrackGc purges removals older than the grace period', () async {
    final t = await f.tracks(2);
    final p = await f.repo.createPlaylist(name: 'P', tracks: t);
    final e = [for (final x in await f.live(p)) x.uid];
    f.clock = 1000;
    await f.repo.removeEntries(p, [e[0]]);
    f.clock = 1000 + removedEntryGraceMs;
    await f.repo.removeEntries(p, [e[1]]);
    expect(await runTrackGc(f.db, now: 1000 + removedEntryGraceMs), isNotNull);
    expect(await f.allKeys(p), hasLength(1), reason: 'only the old tombstone');
  });

  test('purge with no rows sends no table update', () async {
    final seen = <Object>[];
    final sub = f.db
        .tableUpdates(TableUpdateQuery.onTable(f.db.playlistEntries))
        .listen(seen.add);
    addTearDown(sub.cancel);
    expect(await purgeRemovedPlaylistEntries(f.db, before: 99999), 0);
    await pumpEventQueue();
    expect(seen, isEmpty);
  });

  test('a pending removal pins its track until purged', () async {
    final m = await addAgedTrack(
      f.db,
      f.source,
      'old.flac',
      TrackStatus.missing,
      at: 1000,
    );
    final keep = await f.track('keep');
    final p = await f.repo.createPlaylist(
      name: 'P',
      tracks: [TrackId(m), keep],
    );
    final e = (await f.live(p)).first.uid;
    final removedAt = 1000 + missingGraceMs + 10;
    f.clock = removedAt;
    await f.repo.removeEntries(p, [e]);
    // Past the missing grace, but the tombstone is fresh: the track stays.
    expect(await runTrackGc(f.db, now: removedAt + 1), isNotNull);
    expect(await _trackExists(f.db, m), isTrue);
    // After the removal grace the entry is purged and the track collected.
    expect(await runTrackGc(f.db, now: removedAt + removedEntryGraceMs), 1);
    expect(await _trackExists(f.db, m), isFalse);
    expect(await f.liveTracks(p), [keep.value]);
  });
}

Future<bool> _trackExists(AppDatabase db, int id) async => (await (db.select(
  db.tracks,
)..where((t) => t.id.equals(id))).get()).isNotEmpty;
