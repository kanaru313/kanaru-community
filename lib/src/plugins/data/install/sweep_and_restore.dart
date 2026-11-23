import 'package:logging/logging.dart';

import '../../../database/tables.dart';
import '../logs/plugin_run_log.dart';
import '../store/plugin_files.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_rows.dart';

final _log = Logger('plugin_sweep');

/// What a live plugin with a missing package folder needs.
enum RestoreAction {
  /// Repository or link origin: the package can be downloaded again.
  download,

  /// File origin (or an origin that cannot be read): only the user can pick
  /// the file again.
  pickFile,
}

/// A live plugin whose package folder is gone (a restored backup, a cleared
/// cache, a failed write). The row and its config are intact; the plugin
/// cannot run until the package is back.
class RestoreCandidate {
  const RestoreCandidate(this.row, this.action);

  final PluginRow row;
  final RestoreAction action;

  String get installId => row.installId;
}

/// The first job of the write queue: delete folders nothing points to, then
/// list the live rows whose folder is missing. Reinstalling them is the
/// restore hook's work (it runs after this job, one queue job per plugin).
class PluginSweeper {
  PluginSweeper(this._rows, this._files, {required this._logs});

  final PluginRows _rows;
  final PluginFiles _files;
  final PluginRunLog _logs;

  /// Deletes every package folder that no live row points to: the folder of
  /// a removed plugin, an older version left by a crash, a half-written
  /// install. It must run before any install, since a folder written but not
  /// yet recorded looks unreferenced; the queue guarantees that. Also deletes
  /// the run log files of ids that are not live plugins. Returns how
  /// many folders were deleted. Never throws; when the live rows cannot be
  /// read nothing is deleted.
  Future<int> sweep() async {
    final Set<String> liveIds;
    try {
      liveIds = {for (final row in await _rows.live()) row.installId};
    } on Object catch (error) {
      _log.warning('Plugin sweep skipped: ${error.runtimeType}');
      return 0;
    }
    var deleted = 0;
    try {
      final keep = await _rows.livePackageFolders();
      for (final folder in await _files.listFolders()) {
        if (keep.contains(folder.key)) continue;
        if (await _files.deleteFolder(folder.installId, folder.packageDir)) {
          deleted++;
        }
      }
    } on Object catch (error) {
      _log.warning('Plugin folder sweep stopped: ${error.runtimeType}');
    }
    if (deleted > 0) _log.info('Plugin sweep deleted $deleted folders');
    // Run logs of plugins that are gone (a remove that crashed before the
    // delete, a restored backup); needs only the live ids.
    final cleared = await _logs.deleteOrphans(liveIds);
    if (cleared > 0) _log.info('Plugin sweep deleted $cleared run logs');
    return deleted;
  }

  /// The live rows whose folder is missing or has no `plugin.json`, with what
  /// each needs. Empty when the rows cannot be read.
  Future<List<RestoreCandidate>> findMissing() async {
    try {
      final candidates = <RestoreCandidate>[];
      for (final row in await _rows.live()) {
        if (await _files.exists(row)) continue;
        final origin = row.originKind;
        candidates.add(
          RestoreCandidate(
            row,
            origin == PluginOrigin.repo || origin == PluginOrigin.link
                ? RestoreAction.download
                : RestoreAction.pickFile,
          ),
        );
      }
      return candidates;
    } on Object catch (error) {
      _log.warning('Restore scan failed: ${error.runtimeType}');
      return const [];
    }
  }
}
