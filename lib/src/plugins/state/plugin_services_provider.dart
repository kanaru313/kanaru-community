import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/state/document_picker_provider.dart';
import '../data/install/held_packages.dart';
import '../data/install/package_sources.dart';
import '../data/install/sweep_and_restore.dart';
import '../data/install/write_queue.dart';
import '../data/native/rust_script_checker.dart';
import '../data/net/fetcher.dart';
import '../data/repos/catalog_cache.dart';
import '../data/repos/icon_cache.dart';
import '../data/repos/repo_address_guard.dart';
import '../data/repos/repo_refresher.dart';
import '../data/repos/repo_store.dart';
import '../data/run/run_gate.dart';
import '../domain/install/script_checker.dart';
import 'plugin_store_providers.dart';

/// The only way the plugin feature reaches the network. Tests override it.
final pluginFetcherProvider = Provider<HttpFetcher>((ref) => HttpFetcher());

/// The script syntax check (the Rust runtime). Tests override it.
final scriptCheckerProvider = Provider<ScriptChecker>(
  (ref) => const RustScriptChecker(),
);

/// The behaviour services of the plugin store. Every mutation goes through
/// [queue]; reading a service for the first time starts the sweep.
class PluginServices {
  PluginServices({
    required this.queue,
    required this.sweeper,
    required this.repos,
    required this.refresher,
    required this.icons,
    required this.held,
    required this.catalogs,
    required this.runGate,
    required this._startupRestore,
  });

  final PluginWriteQueue queue;
  final PluginSweeper sweeper;
  final PluginRepositories repos;
  final RepoRefresher refresher;
  final PluginIconCache icons;
  final HeldPackages held;
  final CatalogCache catalogs;

  /// Keeps plugin runs and package switches apart (install-over, update,
  /// repair, remove). One per process: runs and switches must meet in the
  /// same gate.
  final RunGate runGate;
  final Future<List<RestoreCandidate>> _startupRestore;

  /// The live plugins whose package folder was missing when the first queue
  /// job ran (completes after the sweep; never fails). The restore step
  /// reinstalls them with one queue job each, outside this job, so a slow
  /// network never holds up config saves.
  Future<List<RestoreCandidate>> get startupRestore => _startupRestore;

  /// A fresh scan for missing folders, as a queue job (run again when the
  /// store opens, to retry what was offline at startup).
  Future<List<RestoreCandidate>> findMissingPackages() => queue.run(
    sweeper.findMissing,
    key: 'restore-scan',
    onError: (_, _) => const <RestoreCandidate>[],
  );
}

// The inputs are read once, not watched: they live as long as the process.
// A rebuild would create a second write queue whose sweep could delete a
// folder the first queue's install has written but not yet recorded.
final pluginServicesProvider = Provider<PluginServices>((ref) {
  final rows = ref.read(pluginRowsProvider);
  final repoRows = ref.read(pluginRepoRowsProvider);
  final files = ref.read(pluginFilesProvider);
  final fetcher = ref.read(pluginFetcherProvider);
  final clock = ref.read(pluginClockProvider);
  final sweeper = PluginSweeper(rows, files);
  final restore = Completer<List<RestoreCandidate>>();
  final queue = PluginWriteQueue(
    firstJob: () async {
      try {
        await sweeper.sweep();
        restore.complete(await sweeper.findMissing());
      } finally {
        if (!restore.isCompleted) restore.complete(const []);
      }
    },
  );
  ref.onDispose(queue.close);
  final guard = RepoAddressGuard();
  final catalogs = CatalogCache();
  final icons = PluginIconCache(fetcher: fetcher, guard: guard, files: files);
  final refresher = RepoRefresher(
    rows: repoRows,
    fetcher: fetcher,
    queue: queue,
    guard: guard,
    onRefreshedAll: icons.clearFailures,
    clock: clock,
  );
  return PluginServices(
    queue: queue,
    sweeper: sweeper,
    catalogs: catalogs,
    refresher: refresher,
    repos: PluginRepositories(
      rows: repoRows,
      fetcher: fetcher,
      queue: queue,
      catalogs: catalogs,
      clock: clock,
    ),
    icons: icons,
    held: HeldPackages(
      sources: PackageSources(
        fetcher: fetcher,
        guard: guard,
        picker: ref.read(documentPickerProvider),
      ),
      checker: ref.read(scriptCheckerProvider),
      rows: rows,
      repoRows: repoRows,
      catalogs: catalogs,
      refreshRepo: refresher.refresh,
    ),
    runGate: RunGate(),
    startupRestore: restore.future,
  );
});
