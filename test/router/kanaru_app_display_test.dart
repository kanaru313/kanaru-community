import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/router/ui/app_theme_provider.dart';
import 'package:kanaru/src/screens/settings/state/display_settings.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/memory_settings_store.dart';

/// Context below the app's builder (the navigator).
BuildContext _appContext(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first);

void main() {
  testWidgets('text scale multiplies the system scale', (tester) async {
    final store = MemorySettingsStore();
    await store.write('app.text_scale', 125);
    await pumpKanaruApp(tester, settings: store);
    expect(MediaQuery.textScalerOf(_appContext(tester)).scale(10), 12.5);
  });

  testWidgets('150 % on a 1.5 system scale is capped at 2.0', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = MemorySettingsStore();
    await store.write('app.text_scale', 150);
    await pumpKanaruApp(tester, settings: store);
    expect(MediaQuery.textScalerOf(_appContext(tester)).scale(10), 20);
  });

  testWidgets('motion off forces disableAnimations, on follows the system', (
    tester,
  ) async {
    final c = await pumpKanaruApp(tester);
    expect(MediaQuery.disableAnimationsOf(_appContext(tester)), isFalse);
    await c.read(appMotionProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(MediaQuery.disableAnimationsOf(_appContext(tester)), isTrue);
  });

  testWidgets('a system request to disable animations wins over motion on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpKanaruApp(tester);
    expect(MediaQuery.disableAnimationsOf(_appContext(tester)), isTrue);
  });

  testWidgets('toggling display settings keeps the same router', (
    tester,
  ) async {
    final c = await pumpKanaruApp(tester);
    final router = c.read(routerProvider);
    final navigator = tester.state(find.byType(Navigator).first);
    await c.read(appTextScaleProvider.notifier).set(150);
    await c.read(appMotionProvider.notifier).set(false);
    await c.read(pureBlackProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(identical(c.read(routerProvider), router), isTrue);
    // The navigator keeps its state: nothing above it was remounted.
    expect(tester.state(find.byType(Navigator).first), same(navigator));
  });

  testWidgets('a dialog inherits the text scale', (tester) async {
    final store = MemorySettingsStore();
    await store.write('app.text_scale', 150);
    await pumpKanaruApp(tester, settings: store);
    double? seen;
    unawaited(
      showDialog<void>(
        context: _appContext(tester),
        builder: (context) {
          seen = MediaQuery.textScalerOf(context).scale(10);
          return const AlertDialog(content: Text('hi'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(seen, 15);
  });

  testWidgets('pure black changes only the dark base surface', (tester) async {
    final store = MemorySettingsStore();
    await store.write('app.pure_black', true);
    await store.write('app.theme', 'dark');
    final c = await pumpKanaruApp(tester, settings: store);
    final dark = c.read(appThemeProvider(Brightness.dark));
    expect(dark.colorScheme.surface, Colors.black);
    expect(dark.scaffoldBackgroundColor, Colors.black);
    // Container tiers stay tinted.
    expect(dark.colorScheme.surfaceContainerHigh, isNot(Colors.black));
    expect(dark.colorScheme.surfaceContainer, isNot(Colors.black));
    final light = c.read(appThemeProvider(Brightness.light));
    expect(light.colorScheme.surface, isNot(Colors.black));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme!.colorScheme.surface, Colors.black);
  });

  testWidgets('without the setting the dark surface is not black', (
    tester,
  ) async {
    final c = await pumpKanaruApp(tester);
    expect(
      c.read(appThemeProvider(Brightness.dark)).colorScheme.surface,
      isNot(Colors.black),
    );
  });
}
