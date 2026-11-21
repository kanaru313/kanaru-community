import 'package:logging/logging.dart';

import '../../domain/install/install_result.dart';
import 'plugin_activity.dart';
import 'repairer.dart';
import 'sweep_and_restore.dart';

final _log = Logger('plugin_restore');

/// What happened to one plugin that was missing its folder.
class RestoreOutcome {
  const RestoreOutcome(this.installId, this.result);

  final String installId;
  final InstallResult result;
}

/// Brings back the plugins whose package folder is missing (a restored
/// backup, a cleared cache). Repository and link plugins are downloaded
/// again, one after the other, and installed silently when their hosts are
/// consented (else they wait as "Cần xem"); the Free rule applies. A plugin
/// that cannot be fetched (offline) stays missing and is retried by the next
/// [restoreMissing]; a file plugin waits for the user to pick the file.
/// Each write is its own queue job and re-reads the row, so a long download
/// never blocks other writes.
class PluginRestorer {
  PluginRestorer({
    required this._startup,
    required this._scan,
    required this._repairer,
    required this._activity,
  });

  final Future<List<RestoreCandidate>> _startup;
  final Future<List<RestoreCandidate>> Function() _scan;
  final PluginRepairer _repairer;
  final PluginActivity _activity;

  Future<List<RestoreOutcome>>? _run;

  /// After the first queue job: a fresh scan, then reinstalls what is
  /// missing. The startup list is only awaited (it marks the end of the first
  /// job), never replayed: a plugin restored since is not downloaded again.
  Future<List<RestoreOutcome>> restoreAtStartup() =>
      _run ??= _startup.then((_) => _scan()).then(_restore).whenComplete(() {
        _run = null;
      });

  /// A fresh scan, then the same work: call it when the store opens, to retry
  /// what was offline. Joins a run that is going.
  Future<List<RestoreOutcome>> restoreMissing() =>
      _run ??= _scan().then(_restore).whenComplete(() {
        _run = null;
      });

  Future<List<RestoreOutcome>> _restore(
    List<RestoreCandidate> candidates,
  ) async {
    _activity.setMissing(candidates);
    final outcomes = <RestoreOutcome>[];
    for (final candidate in candidates) {
      final id = candidate.installId;
      InstallResult result;
      if (candidate.action == RestoreAction.pickFile) {
        result = const InstallRefused(InstallFailure.needsFile);
      } else {
        try {
          result = await _repairer.repair(id, restore: true);
        } on Object catch (error) {
          _log.warning('Restore failed: ${error.runtimeType}');
          result = const InstallRefused(InstallFailure.unexpected);
        }
      }
      outcomes.add(RestoreOutcome(id, result));
    }
    return outcomes;
  }
}
