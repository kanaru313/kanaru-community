import '../logs/plugin_log_reader.dart';
import '../logs/plugin_run_log.dart';
import '../repos/catalog_cache.dart';
import '../store/plugin_config_store.dart';
import '../store/plugin_files.dart';
import '../store/plugin_repo_rows.dart';
import '../run/run_gate.dart';
import '../store/plugin_rows.dart';
import '../store/plugin_storage_store.dart';
import 'config_writes.dart';
import 'held_packages.dart';
import 'installer.dart';
import 'package_writer.dart';
import 'plugin_activity.dart';
import 'remover.dart';
import 'repairer.dart';
import 'restore_reinstall.dart';
import 'streaming_gate.dart';
import 'sweep_and_restore.dart';
import 'update_all.dart';
import 'updater.dart';
import 'write_queue.dart';

/// Every action of the plugin store the screens call, wired to one queue.
class PluginActions {
  PluginActions({
    required PluginWriteQueue queue,
    required PluginRows rows,
    required PluginRepoRows repoRows,
    required PluginFiles files,
    required PluginConfigStore config,
    required this._storage,
    required PluginRunLog logs,
    required HeldPackages held,
    required CatalogCache catalogs,
    required RunGate runGate,
    required bool Function() streamingUnlocked,
    required Future<List<RestoreCandidate>> startupRestore,
    required Future<List<RestoreCandidate>> Function() findMissing,
  }) {
    gate = StreamingGate(rows: rows, files: files, unlocked: streamingUnlocked);
    installer = PluginInstaller(
      queue: queue,
      rows: rows,
      held: held,
      writer: PackageWriter(rows: rows, files: files, config: config),
      gate: gate,
      runGate: runGate,
      activity: activity,
    );
    updater = PluginUpdater(
      rows: rows,
      repoRows: repoRows,
      catalogs: catalogs,
      held: held,
      installer: installer,
      activity: activity,
    );
    updateAll = PluginUpdateAll(
      rows: rows,
      repoRows: repoRows,
      catalogs: catalogs,
      updater: updater,
      activity: activity,
      gate: gate,
    );
    repairer = PluginRepairer(
      rows: rows,
      repoRows: repoRows,
      catalogs: catalogs,
      held: held,
      installer: installer,
      activity: activity,
    );
    remover = PluginRemover(
      queue: queue,
      rows: rows,
      files: files,
      config: config,
      runGate: runGate,
      activity: activity,
      logs: logs,
    );
    logReader = PluginLogReader(logs);
    restorer = PluginRestorer(
      startup: startupRestore,
      scan: findMissing,
      repairer: repairer,
      activity: activity,
    );
    configWrites = PluginConfigWrites(queue: queue, store: config);
  }

  final PluginStorageStore _storage;

  /// Empties what the plugin's scripts stored. A run that began before the
  /// clear does not write its result back afterwards.
  Future<void> clearStorage(String installId) => _storage.clear(installId);

  /// Reads and clears the run logs of the plugins (the screens' Nhật ký).
  late final PluginLogReader logReader;

  final activity = PluginActivity();
  late final StreamingGate gate;
  late final PluginInstaller installer;
  late final PluginUpdater updater;
  late final PluginUpdateAll updateAll;
  late final PluginRepairer repairer;
  late final PluginRemover remover;
  late final PluginRestorer restorer;
  late final PluginConfigWrites configWrites;
}
