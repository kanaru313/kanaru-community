import 'dart:ui' show GestureSettings;

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/library_tabs.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_list_scaffold.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart' show testRefresh;
import 'support/ui_harness.dart';

int taps = 0;

/// The list scaffold on mobile with a horizontal scroller as its body.
Future<GoRouter> _pump(
  WidgetTester tester,
  ScrollController scroll, {
  bool verticalList = false,
}) async {
  taps = 0;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  final db = openTestDb();
  addTearDown(db.close);
  final source = await addSource(db);
  await addLibraryTrack(db, source: source, locator: 'a.flac');
  final router = GoRouter(
    initialLocation: '/library/songs',
    routes: [
      GoRoute(
        path: '/library/:tab',
        builder: (context, state) {
          final tab = LibraryTab.values.byName(state.pathParameters['tab']!);
          return LibraryListScaffold(
            tab: tab,
            child: Column(
              children: [
                SizedBox(
                  height: 80,
                  child: ListView(
                    controller: scroll,
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < 20; i++)
                        SizedBox(width: 100, child: Text('chip $i')),
                    ],
                  ),
                ),
                Expanded(
                  child: verticalList
                      ? ListView(
                          children: [
                            for (var i = 0; i < 40; i++)
                              const SizedBox(height: 60, child: Text('row')),
                          ],
                        )
                      : GestureDetector(
                          key: const Key('row'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => taps++,
                          child: const SizedBox.expand(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        scanStatusProvider.overrideWith(
          (ref) => Stream.value(const ScanIdle()),
        ),
        browseRefreshIntervalProvider.overrideWithValue(testRefresh),
      ],
      child: MaterialApp.router(
        theme: buildKanaruTheme(brightness: Brightness.light),
        routerConfig: router,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            Scaffold(body: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  return router;
}

String _tab(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('a horizontal scroller in the body scrolls, tab stays', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final router = await _pump(tester, scroll);
    await tester.drag(find.byType(ListView), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(_tab(router), '/library/songs');
    await unmountApp(tester);
  });

  testWidgets('a drag over 60 px on the body changes tab, 40 px does not', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final router = await _pump(tester, scroll);
    // The plain area under the 80 px scroller.
    final area = const Offset(195, 500);
    await tester.dragFrom(area, const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(_tab(router), '/library/songs');
    await tester.dragFrom(area, const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(_tab(router), '/library/albums');
    await unmountApp(tester);
  });

  testWidgets('a mouse click with 2 px of jitter taps the row, tab stays', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final router = await _pump(tester, scroll);
    final mouse = await tester.startGesture(
      const Offset(195, 500),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(2, 0));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(_tab(router), '/library/songs');
    await unmountApp(tester);
  });

  testWidgets('a mouse drag well past the slop still changes tab', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final router = await _pump(tester, scroll);
    final mouse = await tester.startGesture(
      const Offset(195, 500),
      kind: PointerDeviceKind.mouse,
    );
    for (var i = 0; i < 12; i++) {
      await mouse.moveBy(const Offset(-10, 0));
    }
    await mouse.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(_tab(router), '/library/albums');
    await unmountApp(tester);
  });

  testWidgets('a touch swipe uses the device slop, not the mouse slop', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    // A vertical list competes for the pointer, as on the real screens; a
    // lone recogniser would win at once and hide its slop.
    final router = await _pump(tester, scroll, verticalList: true);
    tester.view.gestureSettings = const GestureSettings(physicalTouchSlop: 8);
    addTearDown(tester.view.resetGestureSettings);
    await tester.pump();
    // 5 dp steps: the swipe is accepted after 2 steps with the 8 dp device
    // slop but only after 4 with the 18 dp mouse slop, and the tab changes
    // only when the counted distance exceeds 60 dp.
    final touch = await tester.startGesture(const Offset(300, 500));
    for (var i = 0; i < 15; i++) {
      await touch.moveBy(const Offset(-5, 0));
    }
    await touch.up();
    await tester.pumpAndSettle();
    expect(_tab(router), '/library/albums');
    await unmountApp(tester);
  });
}
