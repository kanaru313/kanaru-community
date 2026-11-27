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
import 'src/ai/ai_extension.dart';
import 'src/ai/ui/chat_host.dart';
import 'src/database/app_database.dart';
import 'src/database/state/database_providers.dart';
import 'src/extension/kanaru_extension.dart';
import 'src/extension/state/extension_providers.dart';
import 'src/fonts/data/font_downloader.dart';
import 'src/fonts/data/font_registrar.dart';
import 'src/fonts/data/font_storage.dart';
import 'src/fonts/data/startup_font.dart';
import 'src/fonts/state/font_providers.dart';
import 'src/foundation/app_logger.dart';
import 'src/library/library_extension.dart';
import 'src/library/ui/menus/ask_ai_entry.dart';
import 'src/library/ui/menus/song_lyrics_entry.dart';
import 'src/lyrics/data/native_local_lyrics_reader.dart';
import 'src/lyrics/lyrics_extension.dart';
import 'src/lyrics/state/lyrics_reader_provider.dart';
import 'src/lyrics/state/translation/translation_engine_providers.dart';
import 'src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'src/online/online_extension.dart';
import 'src/platform/data/app_paths_factory.dart';
import 'src/platform/data/file_device_id.dart';
import 'src/platform/data/json_settings_store.dart';
import 'src/platform/data/native_library.dart';
import 'src/platform/state/device_id_provider.dart';
import 'src/platform/state/platform_providers.dart';
import 'src/platform/state/settings_providers.dart';
import 'src/router/state/router_provider.dart';
import 'src/router/ui/kanaru_app.dart';
import 'src/screens/screens_extension.dart';
import 'src/screens/settings/state/appearance_settings.dart';
import 'src/shell/ui/ask_ai_entry_shell.dart';
import 'src/shell/ui/chat_host_shell.dart';

export 'src/database/database.dart';
export 'src/extension/domain/license.dart';
export 'src/extension/kanaru_extension.dart';
export 'src/extension/state/extension_providers.dart'
    show proFeatureStatusProvider;
export 'src/extension/state/extension_registry.dart';
export 'src/extension/state/registry_entries.dart';
export 'src/platform/domain/app_paths.dart' show AppPaths;

/// Extensions of the public app, registered before any bundled (Pro) ones.
const List<KanaruExtension> builtInExtensions = [
  ScreensExtension(),
  LibraryExtension(),
  LyricsExtension(),
  OnlineExtension(),
  AiExtension(),
];

/// The default translation target follows the app language: the lyrics module
/// cannot read the appearance setting, so the app hands it over here.
final translationAppLanguageOverride = translationAppLanguageProvider
    .overrideWith((ref) => ref.watch(appLanguageProvider).name);

/// The chat reaches the shell and the router only through [ChatHost]; the app
/// supplies the shell's implementation here.
final chatHostOverride = chatHostProvider.overrideWith(
  (ref) => ChatHostShell(ref, () => ref.read(routerProvider)),
);

/// The "Ask AI" entry of menus and screens: attaches a chip and opens the
/// chat (panel on desktop, page on the phone).
final askAiEntryOverride = askAiEntryProvider.overrideWith(
  (ref) => AskAiEntryShell(ref, () => ref.read(routerProvider)),
);

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
      loadDeviceId: (paths) =>
          FileDeviceId(File('${paths.dataDir.path}/device_id')).load(),
      openDatabase: (paths) =>
          AppDatabase.file(File('${paths.dataDir.path}/$databaseFileName')),
    );
  } on Object catch (e, st) {
    Logger('startup').severe('Startup failed', e, st);
    runApp(KanaruErrorApp(error: e));
    return;
  }

  // The chosen font must be in the engine before the first frame. Never
  // throws: an unusable font falls back to the default.
  final fontRegistrar = FontRegistrar();
  final fontWatch = Stopwatch()..start();
  try {
    final fontId = await prepareStartupFont(
      paths: started.paths,
      settings: started.settings,
      registrar: fontRegistrar,
    );
    Logger('startup')
        .info('Font "$fontId" ready in ${fontWatch.elapsedMilliseconds} ms');
  } on Object catch (e, st) {
    Logger('startup').warning('Startup font failed', e, st);
  }

  // Licences of downloaded fonts: not needed for the first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    registerInstalledCatalogLicenses(FontStorage(started.paths), fontRegistrar);
  });

  runApp(
    ProviderScope(
      overrides: [
        nativeVersionsProvider.overrideWithValue(started.nativeVersions),
        appPathsProvider.overrideWithValue(started.paths),
        settingsStoreProvider.overrideWithValue(started.settings),
        deviceIdProvider.overrideWithValue(started.deviceId),
        fontLoaderProvider.overrideWithValue(fontRegistrar),
        appDatabaseProvider.overrideWithValue(started.database),
        extensionRegistryProvider.overrideWithValue(started.registry),
        localLyricsReaderProvider.overrideWithValue(NativeLocalLyricsReader()),
        songLyricsEntryProvider.overrideWithValue(const LyricsSongEntry()),
        translationAppLanguageOverride,
        chatHostOverride,
        askAiEntryOverride,
      ],
      child: const KanaruApp(),
    ),
  );
}
