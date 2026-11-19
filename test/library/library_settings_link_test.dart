import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/library_settings_focus.dart';
import 'package:kanaru/src/library/state/scan/scan_capabilities.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_empty_state.dart';
import 'package:kanaru/src/library/ui/library_settings_links.dart';
import 'package:kanaru/src/library/ui/scan/scan_progress_card.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

class _Commands implements LibraryScanCommands, ScanOrigin {
  @override
  bool get lastFinishWasRequested => true;

  @override
  Future<void> rescan({bool full = false}) async {}
}

/// Pumps [home] at `/` with a stand-in for Settings › Library.
Future<(GoRouter, ProviderContainer)> _pump(
  WidgetTester tester,
  Widget home, {
  Stream<ScanStatus>? status,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      if (status != null) scanStatusProvider.overrideWith((ref) => status),
      libraryScanCommandsProvider.overrideWithValue(_Commands()),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: home),
      ),
      GoRoute(
        path: librarySettingsLocation,
        builder: (_, _) => const Scaffold(body: Text('library settings')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, container);
}

void main() {
  testWidgets(
    '"Choose music folders" opens Settings › Library, focus folders',
    (tester) async {
      final (router, container) = await _pump(
        tester,
        const LibraryEmptyState(),
      );
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Choose music folders'),
      );
      expect(button.onPressed, isNotNull);
      await tester.tap(find.text('Choose music folders'));
      await tester.pumpAndSettle();
      expect(find.text('library settings'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        librarySettingsLocation,
      );
      expect(
        container.read(librarySettingsFocusProvider)?.anchor,
        LibrarySettingsAnchor.folders,
      );
    },
  );

  testWidgets('the empty-library scan card offers "Change folders"', (
    tester,
  ) async {
    final status = StreamController<ScanStatus>();
    addTearDown(() => unawaited(status.close()));
    final (router, container) = await _pump(
      tester,
      ScanProgressCard(now: () => DateTime(2026, 11, 19, 12)),
      status: status.stream,
    );
    status.add(
      ScanFinished(
        tracks: 0,
        albums: 0,
        artists: 0,
        added: 0,
        at: DateTime(2026, 11, 19, 12),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No songs found'), findsOneWidget);
    await tester.tap(find.text('Change folders'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      librarySettingsLocation,
    );
    expect(
      container.read(librarySettingsFocusProvider)?.anchor,
      LibrarySettingsAnchor.folders,
    );
  });

  testWidgets('a scan card with songs has no button', (tester) async {
    final status = StreamController<ScanStatus>();
    addTearDown(() => unawaited(status.close()));
    await _pump(
      tester,
      ScanProgressCard(now: () => DateTime(2026, 11, 19, 12)),
      status: status.stream,
    );
    status.add(
      ScanFinished(
        tracks: 10,
        albums: 1,
        artists: 1,
        added: 10,
        at: DateTime(2026, 11, 19, 12),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Change folders'), findsNothing);
  });
}
