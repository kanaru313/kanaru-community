import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/pro_like_database.dart';
import 'support/test_db.dart';

const _day = 24 * 60 * 60 * 1000;
const _now = 100 * _day;

void main() {
  late AppDatabase db;
  late int local;
  late int plugin;

  setUp(() async {
    db = openTestDb();
    local = await addSource(db, name: 'local');
    plugin = await addSource(db, kind: SourceKind.plugin, name: 'plugin');
  });
  tearDown(() => db.close());

  Future<Set<int>> remaining() async => {
    for (final t in await db.select(db.tracks).get()) t.id,
  };

  test('missing at the grace boundary, kept one ms before', () async {
    final id = await addAgedTrack(
      db,
      local,
      'a',
      TrackStatus.missing,
      at: _now - missingGraceMs,
    );
    final young = await addAgedTrack(
      db,
      local,
      'b',
      TrackStatus.missing,
      at: _now - missingGraceMs + 1,
    );
    expect(await collectOrphanTracks(db, now: _now), 1);
    expect(await remaining(), {young});
    expect(await remaining(), isNot(contains(id)));
  });

  test('hidden at the grace boundary, kept one ms before', () async {
    await addAgedTrack(
      db,
      local,
      'a',
      TrackStatus.hidden,
      at: _now - hiddenGraceMs,
    );
    final young = await addAgedTrack(
      db,
      local,
      'b',
      TrackStatus.hidden,
      at: _now - hiddenGraceMs + 1,
    );
    expect(await collectOrphanTracks(db, now: _now), 1);
    expect(await remaining(), {young});
  });

  test('hidden past grace in a removed source', () async {
    final id = await addAgedTrack(db, local, 'a', TrackStatus.present);
    await addMount(db, local, root: '/m');
    await removeSource(db, local, 1000);
    expect(await collectOrphanTracks(db, now: _now), 1);
    expect(await remaining(), isNot(contains(id)));
  });

  test('hidden past grace in a live source with an enabled mount', () async {
    await addMount(db, local, root: '/m');
    final id = await addAgedTrack(db, local, 'a', TrackStatus.hidden);
    expect(await collectOrphanTracks(db, now: _now), 1);
    expect(await remaining(), isNot(contains(id)));
  });

  test('remote at the grace boundary, kept one ms before', () async {
    await addAgedTrack(
      db,
      plugin,
      'a',
      TrackStatus.remote,
      at: _now - remoteGraceMs,
    );
    final young = await addAgedTrack(
      db,
      plugin,
      'b',
      TrackStatus.remote,
      at: _now - remoteGraceMs + 1,
    );
    expect(await collectOrphanTracks(db, now: _now), 1);
    expect(await remaining(), {young});
  });

  test('children and the search row go with the track', () async {
    final id = await addAgedTrack(db, local, 'a', TrackStatus.missing);
    await db.customStatement(
      'INSERT INTO track_details (track_id) VALUES (?)',
      [id],
    );
    await db
        .into(db.playStats)
        .insert(PlayStatsCompanion.insert(trackId: Value(id), playCount: 0));
    expect(await collectOrphanTracks(db, now: _now), 1);
    for (final t in ['track_details', 'play_stats', 'tracks']) {
      expect(
        await db.customSelect('SELECT 1 FROM $t').get(),
        isEmpty,
        reason: t,
      );
    }
    final fts = await db
        .customSelect(
          'SELECT 1 FROM track_search WHERE rowid = ?',
          variables: [Variable.withInt(id)],
        )
        .get();
    expect(fts, isEmpty);
  });

  test('a stream on tracks re-emits and the count is exact', () async {
    for (var i = 0; i < 3; i++) {
      await addAgedTrack(db, local, 'm$i', TrackStatus.missing);
    }
    await addAgedTrack(db, local, 'keep', TrackStatus.present);
    final seen = <int>[];
    final sub = db.select(db.tracks).watch().listen((r) => seen.add(r.length));
    await pumpEventQueue();
    expect(await collectOrphanTracks(db, now: _now), 3);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [4, 1]);
  });

  test('runs inside a transaction of another database object', () async {
    final pro = ProLikeDatabase.connect(db.sharedConnection);
    addTearDown(pro.close);
    await db.customSelect('SELECT 1').get();
    await pro.createOwnTables();
    await addAgedTrack(db, local, 'a', TrackStatus.missing);
    final deleted = await pro.transaction(
      () => collectOrphanTracks(pro, now: _now),
    );
    expect(deleted, 1);
    expect(await remaining(), isEmpty);
  });
}
