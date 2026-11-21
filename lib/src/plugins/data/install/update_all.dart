import 'package:logging/logging.dart';

import '../repos/catalog_cache.dart';
import '../../domain/install/install_result.dart';
import '../store/plugin_repo_rows.dart';
import '../store/plugin_rows.dart';
import 'plugin_activity.dart';
import 'streaming_gate.dart';
import 'update_candidates.dart';
import 'updater.dart';

final _log = Logger('plugin_update');

/// Updates every eligible plugin, one after the other. An item that needs
/// review is skipped without a download; a failure is recorded and the run
/// goes on. Progress is in [PluginActivity] (`updateAll`).
class PluginUpdateAll {
  PluginUpdateAll({
    required this._rows,
    required this._repoRows,
    required this._catalogs,
    required this._updater,
    required this._activity,
    required this._gate,
  });

  final PluginRows _rows;
  final PluginRepoRows _repoRows;
  final CatalogCache _catalogs;
  final PluginUpdater _updater;
  final PluginActivity _activity;
  final StreamingGate _gate;

  Future<UpdateAllState>? _run;

  /// Runs the update, or joins the run that is going. Never throws.
  Future<UpdateAllState> run() => _run ??= _runAll().whenComplete(() {
    _run = null;
  });

  Future<UpdateAllState> _runAll() async {
    var state = const UpdateAllState(running: true);
    try {
      final updates = findUpdates(
        live: await _rows.live(),
        repos: await _repoRows.all(),
        catalogs: _catalogs,
        lockedIds: await _gate.lockedIds(),
      );
      state = UpdateAllState(running: true, total: updates.length);
      _activity.setUpdateAll(state);
      for (final update in updates) {
        final id = update.row.installId;
        // Flagged ones are not downloaded again.
        final result =
            update.needsReview || _activity.snapshot.needsReview.contains(id)
            ? const InstallRefused(InstallFailure.needsReview)
            : await _updater.update(id, keepForReview: false);
        state = UpdateAllState(
          running: true,
          done: state.done + 1,
          total: state.total,
          outcomes: [
            ...state.outcomes,
            UpdateOutcome(id, update.row.name, result),
          ],
        );
        _activity.setUpdateAll(state);
      }
    } on Object catch (error) {
      _log.warning('Update all stopped: ${error.runtimeType}');
    }
    state = UpdateAllState(
      done: state.done,
      total: state.total,
      outcomes: state.outcomes,
    );
    _activity.setUpdateAll(state);
    return state;
  }
}
