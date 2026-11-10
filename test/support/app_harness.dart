import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/data/noop_window_close_guard.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/domain/settings_store.dart';
import 'package:kanaru/src/platform/domain/window_close.dart';
import 'package:kanaru/src/platform/state/device_id_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/platform/state/window_close_provider.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';

import '../database/support/test_db.dart';
import 'fake_playback_commands.dart';
import 'memory_settings_store.dart';

/// [AppPaths] rooted in one temporary directory.
class _TempPaths implements AppPaths {
  _TempPaths(Directory root)
    : dataDir = Directory('${root.path}/data')..createSync(),
      cacheDir = Directory('${root.path}/cache')..createSync(),
      configDir = Directory('${root.path}/config')..createSync();

  @override
  final Directory dataDir;
  @override
  final Directory cacheDir;
  @override
  final Directory configDir;
}

/// A scanner that records requests and does nothing else.
class NoopScanCommands implements LibraryScanCommands {
  int rescans = 0;

  @override
  Future<void> rescan({bool full = false}) async => rescans++;
}

/// Pumps [KanaruApp] with every provider that has a replaceable body
/// (scanner, player, first run) and every platform/database provider pinned
/// to a test value, so a test never depends on what a module seeds.
///
/// - [extensions]: exactly these are installed; null installs
///   [builtInExtensions]. Mechanics tests pass a synthetic set.
/// - [width] / [height]: logical window size (device pixel ratio 1).
/// - [settings], [scanner], [scan], [playback]: replace the matching default.
/// - [windowCloseGuard]: replaces the no-op guard (default), e.g. a recorder.
/// - [firstRunRequired]: replaces the `firstRunRequiredProvider` override
///   (default: false), e.g. one driven by a test notifier.
/// - [overrides]: added to the defaults. A container refuses two overrides of
///   one provider, so they must not repeat a provider pinned above.
///
/// Returns the container. The database is closed after the container is
/// disposed, and the temporary directory is removed last.
Future<ProviderContainer> pumpKanaruApp(
  WidgetTester tester, {
  List<KanaruExtension>? extensions,
  List<Override> overrides = const [],
  double width = 1280,
  double height = 800,
  SettingsStore? settings,
  NoopScanCommands? scanner,
  ScanStatus scan = const ScanIdle(),
  FakePlaybackCommands? playback,
  WindowCloseGuard? windowCloseGuard,
  Override? firstRunRequired,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  // Teardowns run last-in first: container, then database, then directory.
  final root = Directory.systemTemp.createTempSync('kanaru_widget_test');
  addTearDown(() => root.deleteSync(recursive: true));
  final db = openTestDb();
  addTearDown(db.close);

  final registry = ExtensionRegistry()
    ..install(extensions ?? builtInExtensions);
  final container = ProviderContainer(
    overrides: [
      extensionRegistryProvider.overrideWithValue(registry),
      nativeVersionsProvider.overrideWithValue('bridge test'),
      settingsStoreProvider.overrideWithValue(
        settings ?? MemorySettingsStore(),
      ),
      deviceIdProvider.overrideWithValue('test-device'),
      windowCloseGuardProvider.overrideWithValue(
        windowCloseGuard ?? const NoopWindowCloseGuard(),
      ),
      appPathsProvider.overrideWithValue(_TempPaths(root)),
      appDatabaseProvider.overrideWithValue(db),
      scanStatusProvider.overrideWith((ref) => Stream.value(scan)),
      libraryScanCommandsProvider.overrideWithValue(
        scanner ?? NoopScanCommands(),
      ),
      playbackCommandsProvider.overrideWithValue(
        playback ?? FakePlaybackCommands(),
      ),
      nowPlayingProvider.overrideWith((ref) => Stream.value(NowPlaying.none)),
      firstRunRequired ?? firstRunRequiredProvider.overrideWithValue(false),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const KanaruApp()),
  );
  if (settle) await tester.pumpAndSettle();
  return container;
}
