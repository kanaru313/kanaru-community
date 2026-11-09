import 'src/database/app_database.dart';
import 'src/extension/kanaru_extension.dart';
import 'src/extension/state/extension_registry.dart';
import 'src/extension/state/registry_entries.dart';
import 'src/platform/domain/app_paths.dart';

/// Everything the UI needs, ready after a successful [bootstrap].
class BootstrapResult {
  const BootstrapResult({
    required this.nativeVersions,
    required this.paths,
    required this.database,
    required this.registry,
  });

  final String nativeVersions;
  final AppPaths paths;
  final AppDatabase database;
  final ExtensionRegistry registry;
}

/// Startup work before `runApp`, in this order: native library, paths,
/// database (opened and migrated), extension registry, startup hooks. Steps
/// are injected so the order is testable. Any failure closes the database and
/// rethrows.
Future<BootstrapResult> bootstrap({
  required List<KanaruExtension> extensions,
  required Future<String> Function() loadNative,
  required Future<AppPaths> Function() createPaths,
  required AppDatabase Function(AppPaths paths) openDatabase,
}) async {
  final nativeVersions = await loadNative();
  final paths = await createPaths();
  final database = openDatabase(paths);
  try {
    // Open now so migrations run before any extension or page touches it.
    await database.doWhenOpened((_) async {});
    final registry = ExtensionRegistry()..install(extensions);
    // After the public database is open, so extensions can migrate their tables.
    for (final hook in registry.startupHooks) {
      await hook(StartupContext(connection: database.sharedConnection));
    }
    return BootstrapResult(
      nativeVersions: nativeVersions,
      paths: paths,
      database: database,
      registry: registry,
    );
  } on Object {
    await database.close();
    rethrow;
  }
}
