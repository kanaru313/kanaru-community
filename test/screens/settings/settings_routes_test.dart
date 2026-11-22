import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/screens/plugins/plugin_paths.dart';
import 'package:kanaru/src/screens/plugins/repos/repositories_page.dart';
import 'package:kanaru/src/screens/plugins/store/store_page.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_settings_page.dart';
import 'package:kanaru/src/screens/settings/ui/settings_scaffold.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../plugins/support/plugin_fixtures.dart';
import '../../support/icon_button_finders.dart';
import 'support/settings_host.dart';

Iterable<GoRoute> _all(List<RouteBase> routes) sync* {
  for (final r in routes.whereType<GoRoute>()) {
    yield r;
    yield* _all(r.routes);
  }
}

/// Pages of every navigator in the tree (the shell's and the root's).
Iterable<Page<dynamic>> _pages(WidgetTester tester) =>
    tester.widgetList<Navigator>(find.byType(Navigator)).expand((n) => n.pages);

void main() {
  test('root keeps the branch behaviour, sub-pages use a page builder', () {
    final root = buildSettingsRoute();
    expect(root.builder, isNotNull);
    expect(root.pageBuilder, isNull);
    final subs = _all(root.routes).toList();
    expect(
      subs.map((r) => r.path),
      containsAll([
        'appearance',
        'seek-bar',
        'playback',
        'lyrics',
        'about',
        'plugins',
        'repositories',
      ]),
    );
    for (final r in subs) {
      expect(r.pageBuilder, isNotNull, reason: r.path);
      expect(r.builder, isNull, reason: r.path);
    }
  });

  testWidgets('a pushed sub-page is a KDetailPage and animates', (
    tester,
  ) async {
    final h = await pumpSettings(tester);
    h.router.push(SettingsPaths.about);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_pages(tester).whereType<KDetailPage>(), isNotEmpty);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Native libraries'), findsOneWidget);
  });

  testWidgets('/settings/lyrics builds the lyrics page', (tester) async {
    await pumpSettings(tester, location: SettingsPaths.lyrics);
    expect(find.byType(LyricsSettingsPage), findsOneWidget);
  });

  testWidgets('a sub-page paints an opaque surface ground', (tester) async {
    final h = await pumpSettings(tester);
    h.router.push(SettingsPaths.about);
    await tester.pumpAndSettle();
    final scaffold = find.byType(SettingsScaffold);
    final ground = tester
        .widgetList<ColoredBox>(
          find.ancestor(of: scaffold, matching: find.byType(ColoredBox)),
        )
        .map((b) => b.color)
        .toList();
    final surface = Theme.of(tester.element(scaffold)).colorScheme.surface;
    expect(ground, contains(surface));
    expect(surface.a, 1.0);
  });

  testWidgets('with the instant theme the push completes in one pump', (
    tester,
  ) async {
    final h = await pumpSettings(
      tester,
      theme: buildKanaruTheme(brightness: Brightness.light).copyWith(
        pageTransitionsTheme: kanaruPageTransitionsTheme(instant: true),
      ),
    );
    h.router.push(SettingsPaths.about);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(_pages(tester).whereType<KDetailPage>(), isNotEmpty);
    expect(find.text('Native libraries'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Native libraries'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('plugin pages', () {
    testWidgets('the store takes the kind query', (tester) async {
      await pumpPlugins(
        tester,
        StoreFixture(),
        location: '/settings/plugins?kind=streaming',
      );
      final page = tester.widget<StorePage>(find.byType(StorePage));
      expect(page.kind, 'streaming');
      expect(_pages(tester).whereType<KDetailPage>(), isNotEmpty);
    });

    testWidgets('an unknown kind opens the store with an empty search', (
      tester,
    ) async {
      final h = await pumpPlugins(
        tester,
        StoreFixture(),
        location: '/settings/plugins?kind=chat',
      );
      expect(h.container.read(storeFilterProvider).isEmpty, isTrue);
    });

    testWidgets('back goes up one level at a time', (tester) async {
      final h = await pumpPlugins(
        tester,
        StoreFixture(),
        location: PluginPaths.repositories,
      );
      expect(find.byType(RepositoriesPage), findsOneWidget);
      // Opened directly: the arrow leads to the store, then to Settings.
      await tester.tap(byIconButton('Back'));
      await tester.pumpAndSettle();
      expect(
        h.router.routerDelegate.currentConfiguration.last.matchedLocation,
        PluginPaths.store,
      );
      await tester.tap(byIconButton('Back'));
      await tester.pumpAndSettle();
      expect(
        h.router.routerDelegate.currentConfiguration.last.matchedLocation,
        SettingsPaths.root,
      );
    });
  });
}
