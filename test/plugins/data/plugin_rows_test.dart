import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';

import '../../database/support/test_db.dart';
import '../domain/plugin_test_support.dart';
import 'store_test_support.dart';

void main() {
  late AppDatabase db;
  late PluginRows rows;
  var now = 1000;
  final id = testInstallId();
  const repo = PluginSource.repo(
    'https://repo.example.com/plugins.json',
    'demo',
  );

  setUp(() {
    db = openTestDb();
    now = 1000;
    rows = PluginRows(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<PluginRow> installed({PluginSource source = repo}) async {
    final (_, row) = await rows.installOrRevive(
      id,
      draftOf(packageOf()),
      source,
    );
    return row;
  }

  group('install', () {
    test('inserts a live row with its data row and consented hosts', () async {
      final (outcome, row) = await rows.installOrRevive(
        id,
        draftOf(packageOf()),
        repo,
      );
      expect(outcome, PluginInstallWrite.inserted);
      expect(row.isLive, isTrue);
      expect(row.kind, 'lyrics');
      expect(row.version, 3);
      expect(row.author, 'someone');
      expect(row.packageDir, 'v3-1000');
      expect(row.consentedHosts, ['music.example.com']);
      expect(row.source?.origin, PluginOrigin.repo);
      expect(row.installedAt, 1000);
      expect(await db.select(db.pluginData).get(), hasLength(1));
    });

    test('keeps the original manifest text', () async {
      final text =
          '{"metadata":{"apiVersion":1,"type":"lyrics","name":"X",'
          '"version":1,"hosts":["a.example.com"],"future":{"a":1}},'
          '"script":{"search":"search.js","lyrics":"lyrics.js"}}';
      final package = packageOf(null, {'plugin.json': text});
      final (_, row) = await rows.installOrRevive(id, draftOf(package), repo);
      expect(row.manifestJson, text);
    });

    test('a live plugin is left alone', () async {
      final first = await installed();
      now = 5000;
      final (outcome, row) = await rows.installOrRevive(
        id,
        draftOf(packageOf(), 'v3-5000'),
        const PluginSource.link('https://x.example.com/p.zip'),
      );
      expect(outcome, PluginInstallWrite.alreadyLive);
      expect(row.packageDir, first.packageDir);
      expect(row.origin, 'repo');
    });

    test('rejects bad ids, folders and hashes before writing', () async {
      Future<void> bad(String installId, PluginDraft draft) => expectLater(
        rows.installOrRevive(installId, draft, repo),
        throwsArgumentError,
      );
      final draft = draftOf(packageOf());
      await bad('plugin-123', draft);
      await bad('../../etc', draft);
      await bad(id, draftOf(packageOf(), '../v1-1'));
      await bad(id, draftOf(packageOf(), 'v1-1/'));
      expect(await db.select(db.plugins).get(), isEmpty);
    });

    test('rejects an incomplete source and an oversized manifest', () async {
      await expectLater(
        rows.installOrRevive(
          id,
          draftOf(packageOf()),
          const PluginSource.file(''),
        ),
        throwsArgumentError,
      );
      final big = PluginDraft(
        kind: draftOf(packageOf()).kind,
        name: 'n',
        version: 1,
        apiVersion: 1,
        manifestJson: 'x' * (64 * 1024 + 1),
        packageDir: 'v1-1',
        packageSha256: 'a' * 64,
        consentedHosts: const [],
      );
      await expectLater(
        rows.installOrRevive(id, big, repo),
        throwsArgumentError,
      );
      expect(await db.select(db.plugins).get(), isEmpty);
    });
  });

  group('remove and revive', () {
    test('a tombstone has no data, no folder, and is not live', () async {
      await installed();
      now = 2000;
      final (outcome, dir) = await rows.remove(id);
      expect(outcome, PluginRemoval.removed);
      expect(dir, 'v3-1000');
      final row = (await rows.byId(id))!;
      expect(row.removedAt, 2000);
      expect(row.packageDir, isNull);
      expect(row.isLive, isFalse);
      expect(await rows.live(), isEmpty);
      expect(await db.select(db.pluginData).get(), isEmpty);
      expect((await rows.remove(id)).$1, PluginRemoval.alreadyRemoved);
      expect((await rows.remove(testInstallId(9))).$1, PluginRemoval.missing);
    });

    test('revive gives clean config, new hosts and the new source', () async {
      await installed();
      await db.customStatement(
        "UPDATE plugin_data SET config_json = '{\"a\":1}', "
        "custom_choices_json = '{\"m\":[{\"value\":\"x\"}]}'",
      );
      now = 2000;
      await rows.remove(id);
      now = 3000;
      final manifest = withMeta((m) => m['hosts'] = ['other.example.com']);
      final (outcome, row) = await rows.installOrRevive(
        id,
        draftOf(packageOf(manifest), 'v3-3000'),
        const PluginSource.link('https://x.example.com/p.zip'),
      );
      expect(outcome, PluginInstallWrite.revived);
      expect(row.isLive, isTrue);
      expect(row.removedAt, isNull);
      expect(row.consentedHosts, ['other.example.com']);
      expect(row.origin, 'link');
      expect(row.repoUrl, isNull);
      expect(row.originLabel, 'https://x.example.com/p.zip');
      expect(row.installedAt, 3000);
      expect(row.packageDir, 'v3-3000');
      final data = (await db.select(db.pluginData).get()).single;
      expect(data.configJson, '{}');
      expect(data.customChoicesJson, '{}');
    });

    test('updated_at keeps rising through remove and revive', () async {
      await installed();
      final seen = <int>[1000];
      Future<void> mark() async => seen.add((await rows.byId(id))!.updatedAt);
      // The clock stands still: every write still moves updated_at up.
      await rows.remove(id);
      await mark();
      await rows.installOrRevive(id, draftOf(packageOf()), repo);
      await mark();
      await rows.switchPackage(id, draftOf(packageOf(), 'v3-1001'));
      await mark();
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThan(seen[i - 1]), reason: '$seen');
      }
    });
  });

  group('switch package', () {
    test('keeps source, install time and config; moves updated_at', () async {
      final first = await installed();
      await db.customStatement(
        "UPDATE plugin_data SET config_json = '{\"a\":1}'",
      );
      now = 5000;
      final manifest = withMeta((m) {
        m['version'] = 4;
        m['hosts'] = ['music.example.com', 'new.example.com'];
      });
      final row = (await rows.switchPackage(
        id,
        draftOf(packageOf(manifest), 'v4-5000'),
      ))!.now;
      expect(row.version, 4);
      expect(row.packageDir, 'v4-5000');
      expect(row.consentedHosts, ['music.example.com', 'new.example.com']);
      expect(row.updatedAt, 5000);
      expect(row.installedAt, first.installedAt);
      expect(row.origin, 'repo');
      expect(
        (await db.select(db.pluginData).get()).single.configJson,
        '{"a":1}',
      );
    });

    test('returns the row before and after the switch', () async {
      final first = await installed();
      now = 5000;
      final result = (await rows.switchPackage(
        id,
        draftOf(packageOf(), 'v3-5000'),
      ))!;
      expect(result.old.packageDir, first.packageDir);
      expect(result.old.updatedAt, first.updatedAt);
      expect(result.now.packageDir, 'v3-5000');
    });

    test('a second plugin cannot take the same repository entry', () async {
      await installed();
      await expectLater(
        rows.installOrRevive(testInstallId(2), draftOf(packageOf()), repo),
        throwsConstraint('UNIQUE'),
      );
      // Non-repository rows (both columns NULL) never collide.
      await rows.installOrRevive(
        testInstallId(3),
        draftOf(packageOf()),
        const PluginSource.file('a.zip'),
      );
      await rows.installOrRevive(
        testInstallId(4),
        draftOf(packageOf()),
        const PluginSource.file('b.zip'),
      );
      expect(await rows.live(), hasLength(3));
    });

    test('updated_at is MAX(now, updated_at + 1)', () async {
      await installed();
      now = 500; // the clock went back
      final row = (await rows.switchPackage(
        id,
        draftOf(packageOf(), 'v3-2'),
      ))!.now;
      expect(row.updatedAt, 1001);
    });

    test('a missing or removed plugin is not written', () async {
      expect(await rows.switchPackage(id, draftOf(packageOf())), isNull);
      await installed();
      await rows.remove(id);
      expect(await rows.switchPackage(id, draftOf(packageOf())), isNull);
      expect((await rows.byId(id))!.packageDir, isNull);
    });
  });

  group('reads', () {
    test('live, byRepo and livePackageFolders', () async {
      await installed();
      final other = testInstallId(2);
      await rows.installOrRevive(
        other,
        draftOf(packageOf(), 'v3-2000'),
        const PluginSource.file('demo.zip'),
      );
      expect((await rows.live()).map((r) => r.installId), [id, other]);
      expect((await rows.byRepo(repo.repoUrl!, 'demo'))?.installId, id);
      expect(await rows.byRepo(repo.repoUrl!, 'nope'), isNull);
      expect(await rows.livePackageFolders(), {
        '$id/v3-1000',
        '$other/v3-2000',
      });
      await rows.remove(id);
      expect(await rows.livePackageFolders(), {'$other/v3-2000'});
      expect(await rows.byRepo(repo.repoUrl!, 'demo'), isNotNull);
    });

    test('watchLive emits on install and remove', () async {
      final seen = <int>[];
      final sub = rows.watchLive().listen((r) => seen.add(r.length));
      await pumpEventQueue();
      await installed();
      await pumpEventQueue();
      await rows.remove(id);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [0, 1, 0]);
    });
  });

  group('manifest memo', () {
    test('parsed once per row revision', () async {
      final row = await installed();
      final a = rows.manifestOf(row);
      expect(a?.name, 'Demo');
      expect(identical(rows.manifestOf(row), a), isTrue);
    });

    test('a package switch gives a new manifest', () async {
      final before = await installed();
      final old = rows.manifestOf(before)!;
      now = 2000;
      final after = (await rows.switchPackage(
        id,
        draftOf(packageOf(withMeta((m) => m['name'] = 'Renamed')), 'v3-2'),
      ))!.now;
      expect(rows.manifestOf(after)?.name, 'Renamed');
      expect(old.name, 'Demo');
    });

    test('a stored text that does not parse is null, not a throw', () async {
      final row = await installed();
      final broken = row.copyWith(manifestJson: '{not json', updatedAt: 9999);
      expect(rows.manifestOf(broken), isNull);
    });
  });

  group('transactions', () {
    test('a failure inside rolls back every write', () async {
      await installed();
      await expectLater(
        rows.transaction(() async {
          await rows.switchPackage(id, draftOf(packageOf(), 'v3-7'));
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect((await rows.byId(id))!.packageDir, 'v3-1000');
    });
  });
}
