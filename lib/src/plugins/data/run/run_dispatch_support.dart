import 'package:logging/logging.dart';

import '../store/plugin_storage_store.dart';
import 'run_setup.dart';
import 'stream_dispatch.dart';

final _log = Logger('plugin_run');

/// Longest wall time of one normal run, whatever its request asks for.
const maxRunWall = Duration(seconds: 90);

/// `min(cap, timeout + 9 x spacing)`: the allowance for the pauses between the
/// up-to-ten sends of one call. The cap is [maxRunWall], or [maxStreamRunWall]
/// for a streaming run.
Duration runWall(
  Duration timeout,
  Duration spacing, {
  required bool streaming,
}) {
  final wall = timeout + spacing * 9;
  final cap = streaming ? maxStreamRunWall : maxRunWall;
  return wall > cap ? cap : wall;
}

/// Saves the storage the script changed, before the outcome is returned, so
/// the next run of the plugin reads it. A refused write (the plugin was
/// updated, removed or its storage cleared meanwhile) is silent; a failed one
/// logs its type and the outcome still stands.
///
/// The write is a job of the plugin write queue and the run waits for it, so
/// no queue job may ever wait on a plugin run (it would wait for itself).
Future<void> writeBackStorage(
  PluginStorageStore storage,
  String installId,
  String storageJson,
  PreparedRun prepared,
) async {
  try {
    await storage.writeBack(
      installId,
      storageJson,
      expectedRev: prepared.storageRev,
      expectedUpdatedAt: prepared.rowUpdatedAt,
    );
  } on Object catch (error) {
    _log.warning('Plugin storage was not saved: ${error.runtimeType}');
  }
}
