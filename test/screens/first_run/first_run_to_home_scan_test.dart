import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/library/data/scan/library_counts.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline_types.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/scan_controller.dart';
import 'package:kanaru/src/library/state/scan/scan_controller_provider.dart';
import 'package:kanaru/src/library/ui/scan/scan_progress_card.dart';
import 'package:kanaru/src/platform/data/noop_window_close_guard.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/state/device_id_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/platform/state/window_close_provider.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/first_run/ui/first_run_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../database/support/test_db.dart';
import '../../support/fake_playback_commands.dart';
import '../../support/memory_settings_store.dart';
import 'support/first_run_host.dart';

class _Paths implements AppPaths {
  _Paths(Directory root)
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

/// First run → Home with the real wiring: the real gate and router, the real
/// scan controller and status stream, the real `libraryScanCommandsProvider`.
/// Only the scan pass itself is scripted.
void main() {
  testWidgets('the arrow starts exactly one scan and Home shows its summary', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.reset);

    final root = Directory.systemTemp.createTempSync('kanaru_first_run_scan');
    addTearDown(() => root.deleteSync(recursive: true));
    final db = openTestDb();
    addTearDown(db.close);

    final catalog = FakeCatalog()..suggestion = '/home/u/Music';
    final store = MemorySettingsStore();
    final passGate = Completer<void>();
    var passes = 0;
    var garbage = 0;

    final controller = ScanController(
      runPass: (session, hooks, {required full}) async {
        passes++;
        hooks.onStatus(
          const ScanRunning(phase: ScanPhase.tags, done: 5, total: 20),
        );
        await passGate.future;
        return ScanOutcome()
          ..added = 20
          ..counts = const LibraryCounts(tracks: 20, albums: 3, artists: 2);
      },
      runCoverMisses: (_, _, _) async => ScanOutcome(),
      isSetupDone: () => store.read('library.setup_done') == true,
      collectGarbage: () async => garbage++,
      collectCoverFiles: () async {},
    );
    addTearDown(controller.dispose);

    final container = ProviderContainer(
      overrides: <Override>[
        extensionRegistryProvider.overrideWithValue(
          ExtensionRegistry()..install(builtInExtensions),
        ),
        nativeVersionsProvider.overrideWithValue('bridge test'),
        settingsStoreProvider.overrideWithValue(store),
        deviceIdProvider.overrideWithValue('test-device'),
        windowCloseGuardProvider.overrideWithValue(
          const NoopWindowCloseGuard(),
        ),
        appPathsProvider.overrideWithValue(_Paths(root)),
        appDatabaseProvider.overrideWithValue(db),
        playbackCommandsProvider.overrideWithValue(FakePlaybackCommands()),
        nowPlayingProvider.overrideWith((ref) => Stream.value(NowPlaying.none)),
        scanControllerProvider.overrideWithValue(controller),
        ...platformOverrides(
          catalog: catalog,
          permissions: FakePermissions(
            const MediaPermissionState.notApplicable(),
          ),
          android: false,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const KanaruApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FirstRunPage), findsOneWidget);
    expect(passes, 0);
    expect(find.byType(ProgressNoticeCard), findsNothing);

    await tester.tap(find.byType(SetupNextButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/',
    );

    // Home's startup request comes after the first frame; the scan the arrow
    // asked for is the only one.
    expect(passes, 1);
    expect(find.text('Scanning the library'), findsOneWidget);
    expect(find.text('Reading tags and covers · 5 / 20 songs'), findsOne);

    passGate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Added 20 songs'), findsOneWidget);
    expect(find.text('3 albums · 2 artists'), findsOneWidget);

    // Past the startup delay and the card's 4 s: no second scan, card gone,
    // and the garbage collection ran once, after the scan.
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(ProgressNoticeCard), findsNothing);
    await tester.pump(const Duration(seconds: 15));
    expect(passes, 1);
    expect(garbage, 1);
    expect(find.byType(ScanProgressCard), findsOneWidget);
  });
}
