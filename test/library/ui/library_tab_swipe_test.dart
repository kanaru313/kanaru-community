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

/// The list scaffold on mobile with a horizontal scroller as its body.
Future<GoRouter> _pump(WidgetTester tester, ScrollController scroll) async {
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
                const Expanded(child: SizedBox.expand()),
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
}
