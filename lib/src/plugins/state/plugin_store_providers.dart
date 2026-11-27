import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../database/state/database_providers.dart';
import '../../database/tables.dart';
import '../../platform/state/platform_providers.dart';
import '../data/store/plugin_config_store.dart';
import '../data/store/plugin_config_values.dart';
import '../data/store/plugin_files.dart';
import '../data/store/plugin_repo_rows.dart';
import '../data/store/plugin_rows.dart';
import '../domain/config/config_field.dart';
import '../domain/config/config_required.dart';
import '../domain/package/plugin_manifest.dart';

final _log = Logger('plugin_store');

/// Milliseconds since the epoch; tests replace it.
final pluginClockProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().millisecondsSinceEpoch,
);

final pluginRowsProvider = Provider<PluginRows>(
  (ref) => PluginRows(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(pluginClockProvider),
  ),
);

final pluginRepoRowsProvider = Provider<PluginRepoRows>(
  (ref) => PluginRepoRows(ref.watch(appDatabaseProvider)),
);

final pluginFilesProvider = Provider<PluginFiles>(
  (ref) => PluginFiles(
    ref.watch(appPathsProvider).dataDir,
    clock: ref.watch(pluginClockProvider),
  ),
);

/// One asset file of an installed seekbar package; null when it is missing
/// or unreadable. Read with `ref.read(...future)` where it is needed.
final pluginAssetProvider = FutureProvider.autoDispose
    .family<Uint8List?, ({String installId, String packageDir, String name})>(
      (ref, key) => ref
          .watch(pluginFilesProvider)
          .readAssetAt(key.installId, key.packageDir, key.name),
    );

Duration? _noRetry(int count, Object error) => null;

/// Bytes of an installed package folder (manifest, icon, assets); see
/// `PluginFiles.packageBytes`. An unreadable folder is an error, not retried.
final pluginPackageBytesProvider = FutureProvider.autoDispose
    .family<int, ({String installId, String packageDir})>(
      (ref, key) => ref
          .watch(pluginFilesProvider)
          .packageBytes(key.installId, key.packageDir),
      retry: _noRetry,
    );

final pluginConfigStoreProvider = Provider<PluginConfigStore>(
  (ref) => PluginConfigStore(
    ref.watch(appDatabaseProvider),
    ref.watch(pluginRowsProvider),
  ),
);

/// Passes [source] through and logs every error it carries (type only, no
/// message). The error still reaches the provider, which holds it as an error
/// state for the screen to show (a failing database must not end as a red
/// screen on a release build).
Stream<T> _logged<T>(Stream<T> source, String what) => source.transform(
  StreamTransformer<T, T>.fromHandlers(
    handleError: (error, stack, sink) {
      _log.warning('Reading $what failed: ${error.runtimeType}');
      sink.addError(error, stack);
    },
  ),
);

/// Every live plugin, oldest install first.
final installedPluginsProvider = StreamProvider<List<PluginRow>>(
  (ref) => _logged(ref.watch(pluginRowsProvider).watchLive(), 'plugins'),
);

/// The repositories the user added.
final pluginReposProvider = StreamProvider<List<PluginRepoRow>>(
  (ref) => _logged(
    ref.watch(pluginRepoRowsProvider).watchAll(),
    'plugin repositories',
  ),
);

/// One live plugin by id; data null when it is not installed (or was
/// removed).
final installedPluginProvider = Provider.autoDispose
    .family<AsyncValue<PluginRow?>, String>(
      (ref, installId) => ref
          .watch(installedPluginsProvider)
          .whenData(
            (rows) => rows.where((r) => r.installId == installId).firstOrNull,
          ),
    );

/// The stored config of one plugin; emits again only when it changes.
final pluginConfigProvider = StreamProvider.autoDispose
    .family<PluginConfigData, String>(
      (ref, installId) => _logged(
        ref.watch(pluginConfigStoreProvider).watch(installId),
        'plugin config',
      ),
    );

/// One installed plugin with its config and what is still missing.
class PluginConfigStatus {
  const PluginConfigStatus({
    required this.row,
    required this.manifest,
    required this.data,
    required this.missingRequired,
  });

  final PluginRow row;

  /// The parsed manifest; null when the stored one no longer parses (the
  /// plugin is shown as broken).
  final PluginManifest? manifest;
  final PluginConfigData data;

  /// Required fields without a usable value (defaults counted); empty means
  /// the plugin is ready.
  final List<ConfigField> missingRequired;
}

/// A live plugin's config and status; data null when it is not installed. A
/// database error on either part is the error state.
final pluginConfigStatusProvider = Provider.autoDispose
    .family<AsyncValue<PluginConfigStatus?>, String>((ref, installId) {
      final row = ref.watch(installedPluginProvider(installId));
      final config = ref.watch(pluginConfigProvider(installId));
      if (row.hasError) return AsyncError(row.error!, row.stackTrace!);
      if (config.hasError) return AsyncError(config.error!, config.stackTrace!);
      if (row.isLoading || config.isLoading) return const AsyncLoading();
      final installed = row.value;
      if (installed == null) return const AsyncData(null);
      final manifest = ref.watch(pluginRowsProvider).manifestOf(installed);
      final data = config.requireValue;
      return AsyncData(
        PluginConfigStatus(
          row: installed,
          manifest: manifest,
          data: data,
          missingRequired: manifest == null
              ? const []
              : missingRequiredConfig(
                  manifest.config,
                  resolveRunConfig(manifest.config, data),
                ),
        ),
      );
    });
