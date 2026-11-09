/// Public API of the Kanaru app package, used by `kanaru_extensions` and the
/// private Pro repo.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/database/app_database.dart';
import 'src/database/state/database_providers.dart';
import 'src/extension/kanaru_extension.dart';
import 'src/extension/state/extension_providers.dart';
import 'src/extension/state/extension_registry.dart';
import 'src/extension/state/registry_entries.dart';
import 'src/foundation/app_logger.dart';
import 'src/library/library_extension.dart';
import 'src/online/online_extension.dart';
import 'src/platform/data/app_paths_factory.dart';
import 'src/platform/data/native_library.dart';
import 'src/platform/domain/app_paths.dart';
import 'src/platform/state/platform_providers.dart';
import 'src/router/ui/kanaru_app.dart';
import 'src/screens/screens_extension.dart';

export 'src/database/database.dart';
export 'src/extension/domain/license.dart';
export 'src/extension/kanaru_extension.dart';
export 'src/extension/state/extension_registry.dart';
export 'src/extension/state/registry_entries.dart';

/// Extensions of the public app, registered before any bundled (Pro) ones.
const List<KanaruExtension> builtInExtensions = [
  ScreensExtension(),
  LibraryExtension(),
  OnlineExtension(),
];

/// Starts the app: native library, paths, database, extensions, then the UI.
/// [extensions] are registered after the built-in ones.
Future<void> runKanaru({List<KanaruExtension> extensions = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  final nativeVersions = await loadNativeLibrary();
  final AppPaths paths = await createAppPaths();
  final database = AppDatabase.file(File('${paths.dataDir.path}/kanaru.db'));
  // Open now so migrations run before any extension or page touches it.
  await database.doWhenOpened((_) async {});

  final registry = ExtensionRegistry()..install([...builtInExtensions, ...extensions]);
  // After the public database is open, so extensions can migrate their tables.
  for (final hook in registry.startupHooks) {
    await hook(StartupContext(database: database));
  }

  runApp(
    ProviderScope(
      overrides: [
        nativeVersionsProvider.overrideWithValue(nativeVersions),
        appPathsProvider.overrideWithValue(paths),
        appDatabaseProvider.overrideWithValue(database),
        extensionRegistryProvider.overrideWithValue(registry),
      ],
      child: const KanaruApp(),
    ),
  );
}
