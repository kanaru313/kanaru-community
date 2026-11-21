import 'package:logging/logging.dart';

import '../store/plugin_config_store.dart';
import '../store/plugin_files.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_rows.dart';
import '../../domain/package/plugin_kind.dart';
import 'plugin_activity.dart';
import 'write_queue.dart';

final _log = Logger('plugin_remove');

enum RemoveResult { removed, alreadyRemoved, missing, failed }

/// What removing a plugin deletes, for the confirm dialog.
class RemoveSummary {
  const RemoveSummary({
    required this.installId,
    required this.name,
    required this.kind,
    required this.configValues,
    required this.customChoices,
  });

  final String installId;
  final String name;
  final PluginKind? kind;

  /// Settings the user changed (deleted with the plugin).
  final int configValues;

  /// Options the user added to selects (deleted with the plugin).
  final int customChoices;

  bool get hasUserData => configValues > 0 || customChoices > 0;
}

/// Removes a plugin: one transaction (data deleted, `removed_at` set,
/// `package_dir` cleared), then the folder; a folder that cannot be deleted is
/// left to the sweep.
class PluginRemover {
  PluginRemover({
    required this._queue,
    required this._rows,
    required this._files,
    required this._config,
    required this._activity,
  });

  final PluginWriteQueue _queue;
  final PluginRows _rows;
  final PluginFiles _files;
  final PluginConfigStore _config;
  final PluginActivity _activity;

  /// Never throws.
  Future<RemoveResult> remove(String installId) => _queue.run<RemoveResult>(
    () async {
      final (removal, dir) = await _rows.remove(installId);
      if (dir != null) await _files.deleteFolder(installId, dir);
      _activity.clearFor(installId);
      return switch (removal) {
        PluginRemoval.removed => RemoveResult.removed,
        PluginRemoval.alreadyRemoved => RemoveResult.alreadyRemoved,
        PluginRemoval.missing => RemoveResult.missing,
      };
    },
    key: 'remove:$installId',
    onError: (error, _) {
      _log.warning('Remove failed: ${error.runtimeType}');
      return RemoveResult.failed;
    },
  );

  /// Read fresh, when the dialog opens; null when the plugin is not live or
  /// the database cannot be read.
  Future<RemoveSummary?> removeSummary(String installId) async {
    try {
      final row = await _rows.liveById(installId);
      if (row == null) return null;
      final data = await _config.read(installId);
      return RemoveSummary(
        installId: installId,
        name: row.name,
        kind: row.pluginKind,
        configValues: data.values.length,
        customChoices: data.choices.values.fold(0, (n, l) => n + l.length),
      );
    } on Object catch (error) {
      _log.warning('Remove summary failed: ${error.runtimeType}');
      return null;
    }
  }
}
