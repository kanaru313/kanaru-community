import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/online/data/tracks/plugin_source_rows.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';

import '../../database/support/test_db.dart';
import '../../plugins/data/store_test_support.dart';
import 'tracks_test_support.dart';

void main() {
  late AppDatabase db;
  late PluginRows rows;
  var clock = 1000;

  setUp(() {
    clock = 1000;
    db = openTestDb();
    rows = PluginRows(db, clock: () => clock);
  });
  tearDown(() => db.close());

  Future<PluginSourceRef> ensure(PluginRow row) =>
      ensurePluginSource(db, row, now: clock);

  Future<List<Source>> sourceRows() => db.select(db.sources).get();

  test('a repository install has no account', () async {
    final row = await installStreaming(rows);
    expect(pluginSourceAccount(row), isNull);
    final ref = await ensure(row);
    final stored = (await sourceRows()).single;
    expect(stored.uid, ref.sourceUid);
    expect(stored.account, isNull);
    expect(stored.root, row.installId);
    expect(stored.kind, 'plugin');
    expect(await db.select(db.sourceMounts).get(), isEmpty);
  });

  test('remove and install again from the repository keeps the uid', () async {
    final first = await ensure(await installStreaming(rows));
    await rows.remove(testInstallId());
    clock = 5000;
    final second = await ensure(await installStreaming(rows));
    expect(second.sourceUid, first.sourceUid);
    expect(second.sourceId, first.sourceId);
    expect(await sourceRows(), hasLength(1));
  });

  test('a file install is tied to its install time', () async {
    final id = fileId('Audius');
    final row = await installStreaming(
      rows,
      installId: id,
      source: const PluginSource.file('audius.zip'),
    );
    expect(pluginSourceAccount(row), 'install:1000');
    await ensure(row);
    expect((await sourceRows()).single.account, 'install:1000');
  });

  test('remove and install again from a link gives a new source', () async {
    final id = fileId('Audius');
    final old = await ensure(
      await installStreaming(
        rows,
        installId: id,
        source: const PluginSource.file('audius.zip'),
      ),
    );
    await rows.remove(id);
    clock = 9000;
    final fresh = await ensure(
      await installStreaming(
        rows,
        installId: id,
        source: const PluginSource.link('https://example.com/a.zip'),
      ),
    );
    expect(fresh.sourceUid, isNot(old.sourceUid));
    expect(fresh.sourceId, isNot(old.sourceId));
    final all = await sourceRows();
    expect(all, hasLength(2));
    expect(all.map((s) => s.root).toSet(), {id});
    expect(all.map((s) => s.account).toSet(), {'install:1000', 'install:9000'});
  });

  test('an update keeps the uid', () async {
    final row = await installStreaming(rows);
    final before = await ensure(row);
    clock = 7000;
    final package = packageOf(streamingWith(), {
      'src/stream.js': 'function execute(i) { return i + 1; }',
    });
    final switched = await rows.switchPackage(
      row.installId,
      draftOf(package, 'v4-7000'),
    );
    expect(switched, isNotNull);
    final after = await ensure(switched!.now);
    expect(after.sourceUid, before.sourceUid);
    expect(after.sourceId, before.sourceId);
  });

  test('a non-streaming or removed row is refused', () async {
    final lyrics = await rows.installOrRevive(
      testInstallId(2),
      draftOf(packageOf()),
      const PluginSource.file('lyrics.zip'),
    );
    await expectLater(ensure(lyrics.$2), throwsArgumentError);

    final streaming = await installStreaming(rows);
    await rows.remove(streaming.installId);
    final removed = (await rows.byId(streaming.installId))!;
    await expectLater(ensure(removed), throwsArgumentError);
    expect(await sourceRows(), isEmpty);
  });

  test('every install id is safe as a source root', () async {
    // sourceUidForRemote refuses a root with a query or user info.
    final row = await installStreaming(rows);
    expect(row.installId, matches(RegExp(r'^plugin-[0-9a-f]{32}$')));
    await ensure(row);
  });
}
