import 'dart:convert';

import 'package:logging/logging.dart';

import '../../domain/config/config_field.dart';
import '../../domain/config/config_required.dart';
import '../../domain/config/config_value_rules.dart';
import '../../domain/run/plugin_engine.dart';
import '../../domain/run/run_outcome.dart';
import '../../domain/run/run_request.dart';
import '../store/plugin_config_store.dart';
import '../store/plugin_config_values.dart';
import '../store/plugin_files.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_storage_store.dart';
import '../store/plugin_rows.dart';

final _log = Logger('plugin_run');

/// What a run needs, read once at its start (one snapshot of the row, the
/// package and the settings).
class PreparedRun {
  PreparedRun({
    required this.files,
    required this.entry,
    required this.config,
    required this.manifestHosts,
    required this.consentedHosts,
    required this.userEndpoints,
    required this.storageJson,
    required this.storageRev,
    required this.rowUpdatedAt,
    required this.pluginName,
    required this.pluginVersion,
    required this.configSchema,
    required this.storedConfig,
  });

  final List<EngineFile> files;
  final String entry;

  /// `(key, JSON text)`, `configAppend` already merged.
  final List<(String, String)> config;
  final Set<String> manifestHosts;
  final Set<String> consentedHosts;
  final Set<String> userEndpoints;
  final String storageJson;

  /// The storage's clear counter and the plugin row's `updated_at` as read
  /// here: the write-back of this run holds only while both are unchanged.
  final int storageRev;
  final int rowUpdatedAt;

  /// The plugin's name and version, and its settings as stored (with the
  /// manifest's fields): what the run log needs to hide the user's values.
  final String pluginName;
  final String pluginVersion;
  final List<ConfigField> configSchema;
  final Map<String, Object?> storedConfig;
}

/// Either what the run needs, or the outcome that ends it before anything
/// starts.
class RunSetup {
  const RunSetup.ready(PreparedRun this.prepared) : refused = null;
  const RunSetup.refused(RunOutcome this.refused) : prepared = null;

  final PreparedRun? prepared;
  final RunOutcome? refused;
}

/// Reads the plugin row, its package and its settings for [request], checks
/// that it can run and that its required settings have a value.
Future<RunSetup> prepareRun(
  PluginRunRequest request, {
  required PluginRows rows,
  required PluginFiles files,
  required PluginConfigStore config,
  required PluginStorageStore storage,
}) async {
  final row = await rows.byId(request.installId);
  if (row == null || !row.isLive) {
    return const RunSetup.refused(
      RunUnavailable(RunUnavailableReason.notInstalled),
    );
  }
  if (request.kinds.isNotEmpty && !request.kinds.contains(row.pluginKind)) {
    return const RunSetup.refused(
      RunUnavailable(RunUnavailableReason.notInstalled),
    );
  }
  final manifest = rows.manifestOf(row);
  if (manifest == null) {
    return const RunSetup.refused(
      RunUnavailable(RunUnavailableReason.packageUnreadable),
    );
  }
  final entry = manifest.scripts[request.script];
  if (entry == null) {
    return const RunSetup.refused(
      RunUnavailable(RunUnavailableReason.noScript),
    );
  }
  final StoredPackage package;
  try {
    package = await files.readPackage(row);
  } on PluginPackageUnreadable {
    return const RunSetup.refused(
      RunUnavailable(RunUnavailableReason.packageUnreadable),
    );
  } on Object catch (error) {
    _log.warning('A plugin package could not be read: ${error.runtimeType}');
    return const RunSetup.refused(
      RunUnavailable(RunUnavailableReason.packageUnreadable),
    );
  }
  if (!package.scripts.containsKey(entry)) {
    return const RunSetup.refused(
      RunUnavailable(RunUnavailableReason.noScript),
    );
  }

  // One read of the stored values: the run config (stored, then defaults) and
  // the user's saved endpoints come from the same snapshot.
  final stored = await config.read(request.installId);
  // A run that keeps no storage starts empty and is never written back.
  final StoredStorage kept = request.persistStorage
      ? await storage.read(request.installId)
      : (json: '', rev: 0);
  final values = resolveRunConfig(manifest.config, stored);
  final missing = missingRequiredConfig(manifest.config, values);
  if (missing.isNotEmpty) {
    return RunSetup.refused(RunNeedsConfig([for (final f in missing) f.title]));
  }
  final merged = _withAppend(manifest.config, values, request.configAppend);
  if (merged == null) {
    _log.warning('A run asked for a configAppend the rules refuse');
    return const RunSetup.refused(RunFailed(RunFailReason.internal));
  }
  return RunSetup.ready(
    PreparedRun(
      files: [
        for (final e in package.scripts.entries) EngineFile(e.key, e.value),
      ],
      entry: entry,
      config: [for (final e in merged.entries) (e.key, jsonEncode(e.value))],
      manifestHosts: manifest.hosts.toSet(),
      consentedHosts: row.consentedHosts.toSet(),
      userEndpoints: _savedEndpoints(manifest.config, stored.values),
      storageJson: kept.json,
      storageRev: kept.rev,
      rowUpdatedAt: row.updatedAt,
      pluginName: row.name,
      pluginVersion: row.version.toString(),
      configSchema: manifest.config,
      storedConfig: Map.unmodifiable(stored.values),
    ),
  );
}

/// [values] with each append joined (new line) to the stored-or-default text
/// of its field; null when a key is not a declared `text` input or a value is
/// over its cap.
Map<String, Object>? _withAppend(
  List<ConfigField> schema,
  Map<String, Object> values,
  Map<String, String> append,
) {
  if (append.isEmpty) return values;
  final out = {...values};
  for (final entry in append.entries) {
    final field = schema.where((f) => f.key == entry.key).firstOrNull;
    if (field is! InputField || field.format != InputFormat.text) return null;
    if (entry.value.length > maxConfigAppendChars) return null;
    final base = out[entry.key];
    final text = [
      if (base is String) base,
      entry.value,
    ].where((s) => s.isNotEmpty).join('\n');
    if (text.isNotEmpty) out[entry.key] = text;
  }
  return out;
}

/// The `format: url` values the user saved: stored values only, never the
/// manifest defaults.
Set<String> _savedEndpoints(
  List<ConfigField> schema,
  Map<String, Object?> stored,
) {
  final out = <String>{};
  for (final field in schema) {
    final value = stored[field.key];
    // Only a value the form accepts: what a script would not be given as
    // config must not widen where it may connect either.
    if (value == null || !valueFits(field, value)) continue;
    if (field is InputField && field.format == InputFormat.url) {
      if (value is String && value.isNotEmpty) out.add(value);
    } else if (field is ListField && field.format == ListFormat.url) {
      if (value is List) {
        out.addAll(value.whereType<String>().where((s) => s.isNotEmpty));
      }
    }
  }
  return out;
}
