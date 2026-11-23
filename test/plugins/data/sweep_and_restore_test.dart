import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_run_log.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:kanaru/src/plugins/data/store/plugin_files.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';

import '../../database/support/test_db.dart';
import 'services_test_support.dart';
import 'store_test_support.dart';

void main() {
  late AppDatabase db;
  late PluginRows rows;
  late PluginFiles files;
  late PluginSweeper sweeper;
  late Directory dir;
  var now = 1000;

  setUp(() {
    db = openTestDb();
    now = 1000;
    rows = PluginRows(db, clock: () => now);
    dir = tempDir();
    files = PluginFiles(dir, clock: () => ++now);
    sweeper = PluginSweeper(rows, files);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  /// Writes the package folder and the live row that points at it.
  Future<String> install(int n, PluginSource source) async {
    final id = testInstallId(n);
    final package = packageOf();
    final folder = await files.write(id, package);
    await rows.installOrRevive(id, draftOf(package, folder), source);
    return folder;
  }

  const repo = PluginSource.repo('https://repo.example.com/p.json', 'demo');

  group('sweep', () {
    test(
      'deletes folders no live row points to and keeps the live ones',
      () async {
        final keep = await install(1, repo);
        final orphanId = testInstallId(2);
        final orphan = await files.write(orphanId, packageOf());
        // An older version of a live plugin, left by a crash.
        final stale = await files.write(testInstallId(1), packageOf());

        expect(await sweeper.sweep(), 2);

        final left = await files.listFolders();
        expect([for (final f in left) f.key], ['${testInstallId(1)}/$keep']);
        expect(orphan, isNot(keep));
        expect(stale, isNot(keep));
      },
    );

    test('a removed plugin loses its folder', () async {
      await install(1, repo);
      await rows.remove(testInstallId(1));
      expect(await sweeper.sweep(), 1);
      expect(await files.listFolders(), isEmpty);
    });

    test('deletes nothing when the live rows cannot be read', () async {
      await install(1, repo);
      await files.write(testInstallId(2), packageOf());
      sweeper = PluginSweeper(_BrokenRows(db), files);
      expect(await sweeper.sweep(), 0);
      expect(await files.listFolders(), hasLength(2));
    });
  });

  group('run logs', () {
    RunLogEvent ev(String id) => RunLogEvent(
      time: DateTime.now(),
      installId: id,
      pluginName: 'Demo',
      version: '1',
      script: 'search',
      kind: 'server',
    );

    late Directory logDir;
    late PluginRunLog logs;
    File logOf(int n) => File('${logDir.path}/${testInstallId(n)}.jsonl');

    setUp(() async {
      logDir = Directory('${dir.path}-logs');
      logs = PluginRunLog(logDir);
      await install(1, repo);
      logs.append(ev(testInstallId(1)));
      logs.append(ev(testInstallId(2)));
      logs.append(ev(testInstallId(3)));
      await logs.whenIdle();
      await rows.remove(testInstallId(3));
    });
    tearDown(() {
      if (logDir.existsSync()) logDir.deleteSync(recursive: true);
    });

    test(
      'deletes the logs of ids that are not live and keeps live ones',
      () async {
        sweeper = PluginSweeper(rows, files, logs);
        await sweeper.sweep();
        expect(logOf(1).existsSync(), isTrue);
        expect(logOf(2).existsSync(), isFalse);
        expect(logOf(3).existsSync(), isFalse);
      },
    );

    test('deletes nothing when the live rows cannot be read', () async {
      sweeper = PluginSweeper(_BrokenRows(db), files, logs);
      await sweeper.sweep();
      expect(logOf(1).existsSync(), isTrue);
      expect(logOf(2).existsSync(), isTrue);
    });
  });

  group('findMissing', () {
    Future<void> lose(int n, String folder) async {
      expect(await files.deleteFolder(testInstallId(n), folder), isTrue);
    }

    test('lists live rows whose folder is gone, by origin', () async {
      await install(1, repo); // folder still there
      final link = await install(
        2,
        const PluginSource.link('https://x.example.com/a.zip'),
      );
      final file = await install(3, const PluginSource.file('a.zip'));
      final fromRepo = await install(
        4,
        const PluginSource.repo('https://repo.example.com/p.json', 'other'),
      );
      await lose(2, link);
      await lose(3, file);
      await lose(4, fromRepo);

      final missing = await sweeper.findMissing();
      expect(
        {for (final c in missing) c.installId: c.action},
        {
          testInstallId(2): RestoreAction.download,
          testInstallId(3): RestoreAction.pickFile,
          testInstallId(4): RestoreAction.download,
        },
      );
    });

    test('a removed plugin is not a candidate', () async {
      final folder = await install(1, repo);
      await lose(1, folder);
      await rows.remove(testInstallId(1));
      expect(await sweeper.findMissing(), isEmpty);
    });

    test('empty when the rows cannot be read', () async {
      sweeper = PluginSweeper(_BrokenRows(db), files);
      expect(await sweeper.findMissing(), isEmpty);
    });
  });
}

/// Rows whose reads fail, as a broken database would.
class _BrokenRows extends PluginRows {
  _BrokenRows(super.db);

  @override
  Future<Set<String>> livePackageFolders() => throw StateError('db');

  @override
  Future<List<PluginRow>> live() => throw StateError('db');
}
