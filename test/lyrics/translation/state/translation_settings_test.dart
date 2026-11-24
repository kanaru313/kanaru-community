import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';

import '../../../support/memory_settings_store.dart';

PluginRow _row(String id, String kind, {int? removedAt}) => PluginRow(
  installId: id,
  kind: kind,
  name: 'P',
  version: 1,
  apiVersion: 1,
  manifestJson: '{}',
  packageSha256: 'a' * 64,
  origin: 'file',
  consentedHostsJson: '[]',
  installedAt: 1,
  updatedAt: 1,
  removedAt: removedAt,
);

InstalledEntry _entry(PluginRow r) =>
    InstalledEntry(row: r, updating: false, missing: null);

void main() {
  late MemorySettingsStore store;

  ProviderContainer container(AsyncValue<InstalledByKind> installed) {
    final c = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        installedByKindProvider.overrideWithValue(installed),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => store = MemorySettingsStore());

  test('keys and defaults', () {
    final c = container(const AsyncLoading());
    expect(translationOnSetting.key, 'lyrics.translation.on');
    expect(translationServiceSetting.key, 'lyrics.translation.service');
    expect(translationTargetSetting.key, 'lyrics.translation.target');
    expect(translationDisplaySetting.key, 'lyrics.translation.display');
    expect(c.read(translationOnProvider), isFalse);
    expect(c.read(translationServiceProvider), isNull);
    expect(c.read(translationTargetProvider), isNull);
    expect(c.read(translationDisplayProvider), TranslationDisplay.under);
  });

  test('unknown stored values decode to the default', () async {
    await store.write('lyrics.translation.on', 'yes');
    await store.write('lyrics.translation.service', 3);
    await store.write('lyrics.translation.target', 'xx');
    await store.write('lyrics.translation.display', 'beside');
    final c = container(const AsyncLoading());
    expect(c.read(translationOnProvider), isFalse);
    expect(c.read(translationServiceProvider), isNull);
    expect(c.read(translationTargetProvider), isNull);
    expect(c.read(translationDisplayProvider), TranslationDisplay.under);
  });

  test('known stored values are read', () async {
    await store.write('lyrics.translation.on', true);
    await store.write('lyrics.translation.target', 'ja');
    await store.write('lyrics.translation.display', 'replace');
    final c = container(const AsyncLoading());
    expect(c.read(translationOnProvider), isTrue);
    expect(c.read(translationTargetProvider), 'ja');
    expect(c.read(translationDisplayProvider), TranslationDisplay.replace);
  });

  group('effective service', () {
    InstalledByKind installed(Map<PluginKind, List<PluginRow>> rows) =>
        InstalledByKind({
          for (final e in rows.entries)
            e.key: [for (final r in e.value) _entry(r)],
        }, const []);

    test('no choice is data(null) even while plugins load', () {
      final c = container(const AsyncLoading());
      expect(c.read(effectiveTranslationServiceProvider).value, isNull);
      expect(c.read(effectiveTranslationServiceProvider).hasValue, isTrue);
    });

    test('a live translate or ai-translate plugin is kept', () async {
      await store.write('lyrics.translation.service', 'a');
      final c = container(
        AsyncData(
          installed({
            PluginKind.aiTranslate: [_row('a', 'ai-translate')],
          }),
        ),
      );
      expect(c.read(effectiveTranslationServiceProvider).value, 'a');
    });

    test('a removed id, another kind or an unknown id gives null', () async {
      await store.write('lyrics.translation.service', 'a');
      for (final map in [
        <PluginKind, List<PluginRow>>{},
        {
          PluginKind.lyrics: [_row('a', 'lyrics')],
        },
        {
          PluginKind.translate: [_row('a', 'translate', removedAt: 3)],
        },
      ]) {
        final c = container(AsyncData(installed(map)));
        expect(c.read(effectiveTranslationServiceProvider).value, isNull);
      }
    });

    test('loading or error is unknown, never data(null)', () async {
      await store.write('lyrics.translation.service', 'a');
      final loading = container(const AsyncLoading());
      expect(
        loading.read(effectiveTranslationServiceProvider).isLoading,
        isTrue,
      );
      final failed = container(AsyncError(StateError('x'), StackTrace.empty));
      expect(failed.read(effectiveTranslationServiceProvider).hasError, isTrue);
    });
  });
}
