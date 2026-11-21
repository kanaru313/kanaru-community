import 'package:logging/logging.dart';

import '../store/plugin_config_store.dart';
import 'write_queue.dart';

final _log = Logger('plugin_config');

/// Config and custom-choice writes as queue jobs: they never interleave with
/// an update or a remove. Screens call this, never the store's writers.
class PluginConfigWrites {
  PluginConfigWrites({required this._queue, required this._store});

  final PluginWriteQueue _queue;
  final PluginConfigStore _store;

  Future<ConfigWrite> setValue(String installId, String key, Object? value) =>
      _job(() => _store.setValue(installId, key, value));

  Future<ConfigWrite> addCustomChoice(
    String installId,
    String key,
    String value, {
    String? subtitle,
  }) => _job(
    () => _store.addCustomChoice(installId, key, value, subtitle: subtitle),
  );

  Future<ConfigWrite> removeCustomChoice(
    String installId,
    String key,
    String value,
  ) => _job(() => _store.removeCustomChoice(installId, key, value));

  /// A failed write is `failed` (nothing written) with the type logged;
  /// the screen shows its save-failed line.
  Future<ConfigWrite> _job(Future<ConfigWrite> Function() write) =>
      _queue.run<ConfigWrite>(
        write,
        onError: (error, _) {
          _log.warning('Config write failed: ${error.runtimeType}');
          return ConfigWrite.failed;
        },
      );
}
