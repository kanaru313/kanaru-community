import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/install/held_packages.dart';
import 'package:kanaru/src/plugins/data/install/package_sources.dart';
import 'package:kanaru/src/plugins/data/install/plugin_actions.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/data/install/write_queue.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_run_log.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_cache.dart';
import 'package:kanaru/src/plugins/data/repos/catalog_codec.dart';
import 'package:kanaru/src/plugins/data/repos/repo_address_guard.dart';
import 'package:kanaru/src/plugins/data/run/run_gate.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/data/store/plugin_files.dart';
import 'package:kanaru/src/plugins/data/store/plugin_repo_rows.dart';
import 'package:kanaru/src/plugins/data/store/plugin_storage_store.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';

import '../../database/support/test_db.dart';
import '../domain/plugin_test_support.dart';
import '../fixtures/catalog_support.dart';
import '../fixtures/zip_builders.dart';
import 'services_test_support.dart';

const zipUrl = 'https://cdn.example.com/netease/plugin.zip';

/// A file writer that stops at the first write after [arm], so a test can
/// look at the world while an install is half way and then [release] it.
class BlockedWrites {
  bool _armed = false;
  final _entered = Completer<void>();
  final _release = Completer<void>();

  /// Completes when a write is waiting.
  Future<void> get entered => _entered.future;

  void arm() => _armed = true;
  void release() => _release.complete();

  Future<void> write(File file, List<int> bytes) async {
    if (_armed) {
      if (!_entered.isCompleted) _entered.complete();
      await _release.future;
    }
    await file.writeAsBytes(bytes);
  }
}

/// A few turns of the event loop: whatever can run without waiting for
/// something external has run.
Future<void> turns([int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// The install services over an in-memory database, a temp folder and fakes.
/// [zips] maps a download address to the zip served for it.
class InstallHarness {
  InstallHarness({
    this.unlocked = false,
    WriteFileBytes? writeFile,
    Duration exclusiveWait = defaultExclusiveWait,
  }) {
    runGate = RunGate(exclusiveWait: exclusiveWait);
    db = openTestDb();
    dir = tempDir();
    rows = PluginRows(db, clock: () => ++now);
    repoRows = PluginRepoRows(db);
    files = PluginFiles(dir, clock: () => ++now, writeFile: writeFile);
    config = PluginConfigStore(db, rows);
    catalogs = CatalogCache();
    fetcher = FakeFetcher((uri) async {
      final zip = zips[uri.toString()];
      return zip == null ? failed(FetchFailureKind.network) : served(zip);
    });
    checker = FakeChecker();
    picker = FakePicker((doc, max) async => Ok(pickedBytes));
    logs = PluginRunLog(Directory('${dir.path}-logs'));
    sweeper = PluginSweeper(rows, files, logs: logs);
    final restore = Completer<List<RestoreCandidate>>();
    queue = PluginWriteQueue(
      firstJob: () async {
        await sweeper.sweep();
        restore.complete(await sweeper.findMissing());
      },
    );
    storage = PluginStorageStore(db, queue);
    held = HeldPackages(
      sources: PackageSources(
        fetcher: fetcher,
        guard: RepoAddressGuard(resolver: (_) async => [publicIp()]),
        picker: picker,
      ),
      checker: checker,
      rows: rows,
      repoRows: repoRows,
      catalogs: catalogs,
    );
    actions = PluginActions(
      queue: queue,
      rows: rows,
      repoRows: repoRows,
      files: files,
      config: config,
      storage: storage,
      logs: logs,
      held: held,
      catalogs: catalogs,
      runGate: runGate,
      streamingUnlocked: () => unlocked,
      startupRestore: restore.future,
      findMissing: () => queue.run(
        sweeper.findMissing,
        onError: (_, _) => const <RestoreCandidate>[],
      ),
    );
  }

  bool unlocked;
  var now = 1000;
  final zips = <String, Uint8List>{};
  Uint8List pickedBytes = validZip();
  late final RunGate runGate;
  late final AppDatabase db;
  late final Directory dir;
  late final PluginRows rows;
  late final PluginRepoRows repoRows;
  late final PluginFiles files;
  late final PluginConfigStore config;
  late final CatalogCache catalogs;
  late final FakeFetcher fetcher;
  late final FakeChecker checker;
  late final FakePicker picker;
  late final PluginSweeper sweeper;
  late final PluginWriteQueue queue;
  late final PluginStorageStore storage;
  late final PluginRunLog logs;
  late final HeldPackages held;
  late final PluginActions actions;

  /// Stores a repository whose catalog lists one entry per [entries] (slug to
  /// overrides); the zip served for each is [zip].
  Future<int> addRepo(
    Map<String, Map<String, Object?>> entries, {
    Uint8List? zip,
    String url = 'https://repo.example.com/plugins.json',
  }) async {
    final catalog = okCatalog(
      catalogJson([
        for (final e in entries.entries)
          entryJson({
            'slug': e.key,
            'path': 'https://cdn.example.com/${e.key}/plugin.zip',
            'hosts': ['music.example.com'],
            ...e.value,
          }),
      ]),
      url: Uri.parse(url),
    );
    for (final slug in entries.keys) {
      zips['https://cdn.example.com/$slug/plugin.zip'] = zip ?? validZip();
    }
    final (_, id) = await repoRows.add(
      url: url,
      name: 'Kho',
      catalogJson: encodeCatalog(catalog),
      addressKind: AddressKind.public,
      now: 1,
    );
    return id!;
  }

  /// Replaces the catalog of repository [id] (the repository moved on).
  Future<void> setCatalog(
    int id,
    Map<String, Map<String, Object?>> entries, {
    String url = 'https://repo.example.com/plugins.json',
  }) async {
    final catalog = okCatalog(
      catalogJson([
        for (final e in entries.entries)
          entryJson({
            'slug': e.key,
            'path': 'https://cdn.example.com/${e.key}/plugin.zip',
            'hosts': ['music.example.com'],
            ...e.value,
          }),
      ]),
      url: Uri.parse(url),
    );
    await repoRows.saveCatalog(
      id,
      name: 'Kho',
      catalogJson: encodeCatalog(catalog),
      addressKind: AddressKind.public,
      now: 2,
    );
  }

  /// Installs the plugin `slug` of the repository at [repoUrl] from [zip].
  Future<String> installFromRepo(
    int repoId,
    String slug, {
    String repoUrl = 'https://repo.example.com/plugins.json',
  }) async {
    final held = await prepareRepo(repoId, slug);
    final result = await actions.installer.install(held.token);
    expect(result, isA<Installed>(), reason: 'install of $slug');
    return repoInstallId(repoUrl, slug);
  }

  Future<HeldPackage> prepareRepo(int repoId, String slug) async =>
      switch (await held.prepareFromRepo(repoId, slug).result) {
        Ok(:final value) => value,
        Err(:final error) => fail('prepare refused: $error'),
      };

  Future<HeldPackage> prepareLink(String url) async =>
      switch (await held.prepareFromLink(url).result) {
        Ok(:final value) => value,
        Err(:final error) => fail('prepare refused: $error'),
      };

  Future<HeldPackage> prepareFile(
    Uint8List zip, [
    String name = 'a.zip',
  ]) async {
    pickedBytes = zip;
    return switch (await held.prepareFromFile(pickedZip(name)).result) {
      Ok(:final value) => value,
      Err(:final error) => fail('prepare refused: $error'),
    };
  }

  /// A zip of the lyrics demo at [version] with [hosts].
  static Uint8List zipOf({
    int version = 3,
    List<String> hosts = const ['music.example.com'],
    Map<String, Object?>? manifest,
  }) => validZip(
    manifest:
        manifest ??
        withMeta((m) {
          m['version'] = version;
          m['hosts'] = hosts;
        }),
  );

  Future<void> dispose() async {
    await logs.whenIdle();
    await db.close();
    dir.deleteSync(recursive: true);
    final logDir = Directory('${dir.path}-logs');
    if (logDir.existsSync()) logDir.deleteSync(recursive: true);
  }
}
