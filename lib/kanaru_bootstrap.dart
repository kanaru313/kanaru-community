import 'src/database/app_database.dart';
import 'src/extension/kanaru_extension.dart';
import 'src/extension/state/extension_registry.dart';
import 'src/extension/state/registry_entries.dart';
import 'src/platform/domain/app_paths.dart';
import 'src/platform/domain/settings_store.dart';

/// File name of the database inside the data folder. Never the old app's `library.db`.
const String databaseFileName = 'kanaru.db';

/// Everything the UI needs, ready after a successful [bootstrap].
class BootstrapResult {
  const BootstrapResult({
    required this.nativeVersions,
    required this.paths,
    required this.settings,
    required this.deviceId,
    required this.database,
    required this.registry,
  });

  final String nativeVersions;
  final AppPaths paths;
  final SettingsStore settings;
  final String deviceId;
  final AppDatabase database;
  final ExtensionRegistry registry;
}

/// Startup work before `runApp`, in this order: native library, paths,
/// settings, device id, database (opened and migrated), extension registry, startup hooks. Steps
/// are injected so the order is testable. Any failure closes the database and
/// rethrows.
Future<BootstrapResult> bootstrap({
  required List<KanaruExtension> extensions,
  required Future<String> Function() loadNative,
  required Future<AppPaths> Function() createPaths,
  required Future<SettingsStore> Function(AppPaths paths) openSettings,
  required Future<String> Function(AppPaths paths) loadDeviceId,
  required AppDatabase Function(AppPaths paths) openDatabase,
}) async {
  final nativeVersions = await loadNative();
  final paths = await createPaths();
  final settings = await openSettings(paths);
  final deviceId = await loadDeviceId(paths);
  final database = openDatabase(paths);
  try {
    // Open now so migrations run before any extension or page touches it.
    await database.doWhenOpened((_) async {});
    final registry = ExtensionRegistry()..install(extensions);
    // After the public database is open, so extensions can migrate their tables.
    for (final hook in registry.startupHooks) {
      await hook(StartupContext(connection: await database.openedConnection()));
    }
    return BootstrapResult(
      nativeVersions: nativeVersions,
      paths: paths,
      settings: settings,
      deviceId: deviceId,
      database: database,
      registry: registry,
    );
  } on Object {
    await database.close();
    rethrow;
  }
}
