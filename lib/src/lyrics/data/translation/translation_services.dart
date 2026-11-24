import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../plugins/data/store/plugin_config_store.dart';
import '../../../plugins/data/store/plugin_row_types.dart';
import '../../../plugins/data/store/plugin_rows.dart';
import '../../../plugins/domain/package/translate_spec.dart';

/// What a job needs to know about a live translate plugin, read fresh before
/// every chunk.
class ServiceSnapshot {
  const ServiceSnapshot({
    required this.installId,
    required this.version,
    required this.spec,
    required this.settingsJson,
  });

  final String installId;

  /// `metadata.version` of the installed package.
  final int version;

  /// Chunk limits and run time of the plugin.
  final TranslateSpec spec;

  /// `{pluginVersion, model, style, instructionHash}` stored with the cache
  /// row. The instruction text is never stored, only its hash.
  final String settingsJson;
}

/// The translate plugins as the engine sees them. Tests replace it.
abstract interface class TranslationServices {
  /// The live translate plugin [installId], or null when it is removed,
  /// tombstoned or of another kind. Throws on a database error.
  Future<ServiceSnapshot?> snapshot(String installId);

  /// Emits the plugin's stored settings now (the baseline) and again after
  /// each change.
  Stream<Object?> configChanges(String installId);
}

/// [TranslationServices] over the plugin store.
class PluginTranslationServices implements TranslationServices {
  PluginTranslationServices({required this._rows, required this._config});

  final PluginRows _rows;
  final PluginConfigStore _config;

  @override
  Future<ServiceSnapshot?> snapshot(String installId) async {
    final row = await _rows.liveById(installId);
    if (row == null || !(row.pluginKind?.isTranslation ?? false)) return null;
    final spec = _rows.manifestOf(row)?.translate;
    if (spec == null) {
      // A parsed translate row always has the block; stop the job with a
      // visible failure instead of guessing limits.
      throw StateError('translate plugin without a translate block');
    }
    final values = await _config.configForRun(installId);
    final instruction = values['customInstruction'];
    return ServiceSnapshot(
      installId: installId,
      version: row.version,
      spec: spec,
      settingsJson: jsonEncode({
        'pluginVersion': row.version,
        'model': values['model'],
        'style': values['style'],
        'instructionHash':
            instruction is String && instruction.trim().isNotEmpty
            ? sha256.convert(utf8.encode(instruction.trim())).toString()
            : null,
      }),
    );
  }

  @override
  Stream<Object?> configChanges(String installId) => _config.watch(installId);
}
