import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/kanaru_error_app.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/platform/data/app_paths_factory.dart';
import 'package:kanaru/src/platform/state/media_permissions_provider.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru_extensions/kanaru_extensions.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'fixtures.dart';

/// A started real app: the widget tree plus its provider container.
class RunningApp {
  RunningApp(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  /// Pumps frames until [condition] holds, failing with [what] after
  /// [timeout]. Real time: the app does real I/O (scan, FFI, mpv).
  Future<void> pumpUntil(
    FutureOr<bool> Function() condition, {
    required String what,
    Duration timeout = const Duration(seconds: 60),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!await condition()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TestFailure('Timed out after $timeout waiting for: $what');
      }
      await Future<void>.delayed(step);
      await tester.pump();
    }
  }

  /// Library tracks by title, from the real database.
  Future<Map<String, int>> trackIdsByTitle() async {
    final db = container.read(appDatabaseProvider);
    final rows = await (db.select(
      db.tracks,
    )..orderBy([(t) => OrderingTerm.asc(t.title)])).get();
    return {for (final row in rows) row.title: row.id};
  }
}

/// Settings the harness writes before the app opens its store: library
/// minimum duration off, because the fixtures are a few seconds long.
const _harnessSettings = <String, Object?>{'library.min_duration_ms': 0};

/// Merges [_harnessSettings] into `settings.json` (same format as
/// `JsonSettingsStore`; an existing file keeps its other values).
Future<void> _prepareSettings() async {
  final paths = await createAppPaths();
  final file = File('${paths.configDir.path}/settings.json');
  final values = <String, Object?>{};
  if (await file.exists()) {
    final json = jsonDecode(await file.readAsString());
    if (json is Map<String, Object?> && json['values'] is Map) {
      values.addAll((json['values'] as Map).cast<String, Object?>());
    }
  }
  values.addAll(_harnessSettings);
  await file.writeAsString(
    jsonEncode({'format': 'kanaru-settings', 'version': 1, 'values': values}),
  );
}

/// Starts the real app (real bootstrap, Rust library, libmpv, database on
/// disk) and brings it to the Home page with the fixture library scanned.
///
/// The library folder is never picked through a native dialog: the first-run
/// page adds the platform's default music folder (Linux: `XDG_MUSIC_DIR` that
/// `tool/integration_test.sh` points at the fixtures; Android: `/Music`, where
/// the runner pushed them), then the harness presses the page's arrow.
Future<RunningApp> startKanaru(WidgetTester tester) async {
  await _prepareSettings();
  await runKanaru(extensions: bundledExtensions);
  await tester.pump();
  if (find.byType(KanaruErrorApp).evaluate().isNotEmpty) {
    throw TestFailure('The app failed to start (KanaruErrorApp is shown)');
  }
  final container = ProviderScope.containerOf(
    tester.element(find.byType(KanaruApp)),
  );
  final app = RunningApp(tester, container);

  if (container.read(firstRunRequiredProvider)) {
    final next = find.byType(SetupNextButton);
    var lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
    await app.pumpUntil(
      () {
        // Permissions are granted from outside (`pm grant`) while the app
        // starts: look again, at most once a second, until they show.
        final now = DateTime.now();
        if (now.difference(lastRefresh) >= const Duration(seconds: 1)) {
          lastRefresh = now;
          unawaited(
            container
                .read(mediaPermissionStateProvider.notifier)
                .refresh()
                .then<void>(
                  (_) {},
                  onError: (Object e) =>
                      debugPrint('permission refresh failed: $e'),
                ),
          );
        }
        return next.hitTestable().evaluate().isNotEmpty &&
            tester.widget<SetupNextButton>(next).onPressed != null;
      },
      what:
          'first-run page with a default music folder (is XDG_MUSIC_DIR set?)',
    );
    await tester.tap(next);
    await app.pumpUntil(
      () => !container.read(firstRunRequiredProvider),
      what: 'setup to finish',
    );
  }

  container.read(routerProvider).go('/library/songs');
  await tester.pump();

  final wanted = {for (final t in fixtureTracks) t.title};
  await app.pumpUntil(
    () async => (await app.trackIdsByTitle()).keys.toSet().containsAll(wanted),
    what: 'every fixture track in the library (scan)',
    timeout: const Duration(seconds: 120),
  );
  return app;
}
