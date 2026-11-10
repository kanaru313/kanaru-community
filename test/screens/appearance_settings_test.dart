import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/screens/settings/state/appearance_settings.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, ThemeMode;

import '../support/app_harness.dart';
import '../support/memory_settings_store.dart';
import '../support/nav_fixture.dart';

void main() {
  late Directory dir;
  late JsonSettingsStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('appearance_test');
    store = await JsonSettingsStore.open(File('${dir.path}/settings.json'));
  });
  tearDown(() async {
    await store.flush();
    await dir.delete(recursive: true);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('theme defaults to system; stored value and bad value', () async {
    expect(container().read(themeChoiceProvider), ThemeChoice.system);
    await store.write('app.theme', 'dark');
    expect(container().read(themeChoiceProvider), ThemeChoice.dark);
    await store.write('app.theme', 'purple');
    expect(container().read(themeChoiceProvider), ThemeChoice.system);
  });

  test('language default follows the device locale', () {
    expect(defaultLanguageFor('vi'), AppLanguage.vi);
    expect(defaultLanguageFor('en'), AppLanguage.en);
    expect(defaultLanguageFor('fr'), AppLanguage.en);
  });

  test('set persists under the documented keys', () async {
    final c = container();
    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.light);
    await c.read(appLanguageProvider.notifier).set(AppLanguage.vi);
    expect(store.read('app.theme'), 'light');
    expect(store.read('app.language'), 'vi');
  });

  testWidgets('KanaruApp applies theme and language at once', (tester) async {
    final c = await pumpKanaruApp(tester, extensions: [const NavFixture()]);
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));

    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.dark);
    await c.read(appLanguageProvider.notifier).set(AppLanguage.vi);
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.dark);
    expect(app().locale, const Locale('vi'));

    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.light);
    await c.read(appLanguageProvider.notifier).set(AppLanguage.en);
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.light);
    expect(app().locale, const Locale('en'));
  });

  testWidgets('language default follows the device locale', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final c = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(appLanguageProvider), AppLanguage.vi);
  });
}
