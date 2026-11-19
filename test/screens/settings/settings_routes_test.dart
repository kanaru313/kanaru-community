import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

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
      containsAll(['appearance', 'seek-bar', 'playback', 'about']),
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
}
