import 'package:logging/logging.dart';

import '../../domain/install/install_result.dart';
import '../../domain/install/install_rules.dart';
import '../../domain/package/plugin_package.dart';
import '../store/plugin_config_store.dart';
import '../store/plugin_files.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_rows.dart';

final _log = Logger('plugin_install');

/// The one place a package reaches the disk and the database. Order: write
/// the new folder (flushed), one database transaction, delete the old folder.
/// A failure of the transaction deletes the new folder, so the database never
/// names a package that is not whole and a crash leaves at most an orphan the
/// sweep deletes. Runs inside a queue job; the caller has checked every rule.
class PackageWriter {
  PackageWriter({
    required this._rows,
    required this._files,
    required this._config,
  });

  final PluginRows _rows;
  final PluginFiles _files;
  final PluginConfigStore _config;

  /// Writes [package] for [installId]. [mode] `install` inserts or revives the
  /// row from [source] (installing is the consent to the package's hosts);
  /// `update` and `repair` point the live row at the new folder, keep its
  /// source and config, and (update only) move the config to the new form in
  /// the same transaction.
  Future<InstallResult> write({
    required String installId,
    required PluginPackage package,
    required PluginSource source,
    required InstallMode mode,
  }) async {
    final String dir;
    try {
      dir = await _files.write(installId, package);
    } on Object catch (error) {
      _log.warning('Writing a plugin folder failed: ${error.runtimeType}');
      return const InstallRefused(InstallFailure.diskFailed);
    }
    final draft = PluginDraft.fromPackage(package, packageDir: dir);
    try {
      if (mode == InstallMode.install) {
        final (write, _) = await _rows.installOrRevive(
          installId,
          draft,
          source,
        );
        if (write == PluginInstallWrite.alreadyLive) {
          await _files.deleteFolder(installId, dir);
          return const InstallRefused(InstallFailure.reviewStale);
        }
        return Installed(
          installId,
          write == PluginInstallWrite.revived
              ? InstallOutcome.revived
              : InstallOutcome.installed,
        );
      }
      final switched = await _rows.transaction(() async {
        final result = await _rows.switchPackage(installId, draft);
        if (result != null && mode == InstallMode.update) {
          final adapted = await _config.adaptToForm(
            installId,
            _rows.manifestOf(result.old)?.config ?? const [],
            package.manifest.config,
          );
          // A config that cannot follow the new form aborts the whole
          // update: it rolls back and the new folder is deleted.
          if (adapted != ConfigWrite.written) {
            throw StateError('config adaptation: ${adapted.name}');
          }
        }
        return result;
      });
      if (switched == null) {
        await _files.deleteFolder(installId, dir);
        return const InstallRefused(InstallFailure.pluginGone);
      }
      final old = switched.old.packageDir;
      if (old != null && old != dir) await _files.deleteFolder(installId, old);
      return Installed(
        installId,
        mode == InstallMode.update
            ? InstallOutcome.updated
            : InstallOutcome.repaired,
      );
    } on Object catch (error) {
      _log.warning('Recording a plugin failed: ${error.runtimeType}');
      await _files.deleteFolder(installId, dir);
      return const InstallRefused(InstallFailure.databaseFailed);
    }
  }
}
