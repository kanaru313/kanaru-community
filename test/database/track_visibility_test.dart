import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int local;
  late int removed;
  late int disabled;
  late int plugin;

  setUp(() async {
    db = openTestDb();
    local = await addSource(db, name: 'local');
    removed = await addSource(db, name: 'removed');
    disabled = await addSource(db, name: 'disabled');
    plugin = await addSource(db, kind: SourceKind.plugin, name: 'plugin');
    for (final s in [local, removed, disabled]) {
      await addMount(db, s, root: '/m/$s');
    }
    await addTrack(db, local, locator: 'present.flac');
    await addTrack(
      db,
      local,
      locator: 'missing.flac',
      status: TrackStatus.missing,
    );
    await addTrack(db, removed, locator: 'removed.flac');
    await addTrack(db, disabled, locator: 'disabled.flac');
    await addTrack(db, plugin, locator: 'remote-1', status: TrackStatus.remote);
  });
  tearDown(() => db.close());

  Future<Set<String>> typed() async => {
    for (final t in await (db.select(db.tracks)..where(isVisibleTrack)).get())
      t.locator,
  };

  Future<Set<String>> sql() async => {
    for (final r
        in await db
            .customSelect(
              'SELECT t.locator FROM tracks t WHERE ${visibleTrackWhere('t')}',
            )
            .get())
      r.read<String>('locator'),
  };

  test('only present rows are visible; remote never is', () async {
    expect(await typed(), {'present.flac', 'removed.flac', 'disabled.flac'});
  });

  test('removing a source or disabling a mount hides its tracks', () async {
    await removeSource(db, removed, 2000);
    await setMountEnabled(db, disabled, false, 2000);
    expect(await typed(), {'present.flac'});
  });

  test('SQL and typed forms return the same rows', () async {
    expect(await sql(), await typed());
    await removeSource(db, removed, 2000);
    expect(await sql(), await typed());
  });

  test('a typed watch re-emits after a mount is disabled', () async {
    final seen = <int>[];
    final sub = (db.select(
      db.tracks,
    )..where(isVisibleTrack)).watch().listen((rows) => seen.add(rows.length));
    await pumpEventQueue();
    await setMountEnabled(db, disabled, false, 2000);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [3, 2]);
  });

  test('the SQL form is a plain comparison usable with variables', () async {
    final rows = await db
        .customSelect(
          'SELECT count(*) AS n FROM tracks t WHERE ${visibleTrackWhere('t')} AND t.source_id = ?',
          variables: [Variable.withInt(local)],
        )
        .getSingle();
    expect(rows.read<int>('n'), 1);
  });

  test('an alias that is not an identifier is rejected', () {
    for (final bad in ['', 't; DROP TABLE tracks', 'a b', '1t', 't.x', '"t"']) {
      expect(() => visibleTrackWhere(bad), throwsArgumentError, reason: bad);
    }
  });
}
