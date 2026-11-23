import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/state/font_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/router/ui/app_theme_provider.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_settings_store.dart';

void main() {
  test('theme family follows the stored font', () async {
    final store = MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    String family() => container
        .read(appThemeProvider(Brightness.light))
        .textTheme
        .bodyMedium!
        .fontFamily!;

    expect(container.read(activeFontFamilyProvider), 'Nunito');
    expect(family(), contains('Nunito'));

    await store.write('app.font', 'inter');
    expect(container.read(activeFontFamilyProvider), 'Inter');
    expect(family(), contains('Inter'));

    await store.write('app.font', 'system');
    expect(family(), contains('sans-serif'));
  });

  test('an invalid stored font gives the default family', () {
    final store = MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    store.write('app.font', '../x');
    expect(container.read(activeFontFamilyProvider), 'Nunito');
  });
}
