/// Public API of the Kanaru app package, used by `kanaru_extensions` and
/// extension packages.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';

import 'kanaru_bootstrap.dart';
import 'kanaru_error_app.dart';
import 'src/database/app_database.dart';
import 'src/database/state/database_providers.dart';
import 'src/extension/kanaru_extension.dart';
import 'src/extension/state/extension_providers.dart';
import 'src/foundation/app_logger.dart';
import 'src/library/library_extension.dart';
import 'src/online/online_extension.dart';
import 'src/platform/data/app_paths_factory.dart';
import 'src/platform/data/file_device_id.dart';
import 'src/platform/data/json_settings_store.dart';
import 'src/platform/data/native_library.dart';
import 'src/platform/state/device_id_provider.dart';
import 'src/platform/state/platform_providers.dart';
import 'src/platform/state/settings_providers.dart';
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

/// Starts the app: native library, paths, settings, device id, database, extensions, then the UI.
/// [extensions] are registered after the built-in ones. A startup failure is
/// logged and shown by a minimal error app instead of leaving a blank window.
Future<void> runKanaru({List<KanaruExtension> extensions = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  final BootstrapResult started;
  try {
    // The only place media_kit is initialised; modules never call it.
    MediaKit.ensureInitialized();
    started = await bootstrap(
      extensions: [...builtInExtensions, ...extensions],
      loadNative: loadNativeLibrary,
      createPaths: createAppPaths,
      openSettings: (paths) =>
          JsonSettingsStore.open(File('${paths.configDir.path}/settings.json')),
      loadDeviceId: (paths) => FileDeviceId(File('${paths.dataDir.path}/device_id')).load(),
      openDatabase: (paths) => AppDatabase.file(File('${paths.dataDir.path}/$databaseFileName')),
    );
  } on Object catch (e, st) {
    Logger('startup').severe('Startup failed', e, st);
    runApp(KanaruErrorApp(error: e));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        nativeVersionsProvider.overrideWithValue(started.nativeVersions),
        appPathsProvider.overrideWithValue(started.paths),
        settingsStoreProvider.overrideWithValue(started.settings),
        deviceIdProvider.overrideWithValue(started.deviceId),
        appDatabaseProvider.overrideWithValue(started.database),
        extensionRegistryProvider.overrideWithValue(started.registry),
      ],
      child: const KanaruApp(),
    ),
  );
}
