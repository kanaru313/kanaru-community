import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_commands.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_tune_provider.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';

import '../../../plugins/domain/plugin_test_support.dart';
import '../support/translation_harness.dart';

void main() {
  late TranslationHarness t;
  setUp(() => t = TranslationHarness());
  tearDown(() => t.dispose());

  /// The value of [provider] once its first data is in.
  Future<T> loaded<T>(ProviderListenable<AsyncValue<T>> provider) async {
    final sub = t.c.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await t.settle();
    return sub.read().requireValue;
  }

  group('services', () {
    test('no plugin: none, nothing chosen', () async {
      final services = await loaded(translateServicesProvider);
      expect(services.none, isTrue);
      expect(services.current, isNull);
      expect(services.gone, isFalse);
    });

    test(
      'plain plugins first, then AI ones; the chosen one is current',
      () async {
        final ai = await t.install(manifest: aiManifest);
        final plain = await t.install();
        await t.c.read(translationServiceProvider.notifier).set(ai);
        final services = await loaded(translateServicesProvider);
        expect(services.all.map((s) => s.installId), [plain, ai]);
        expect(services.all.map((s) => s.ai), [false, true]);
        expect(services.current?.installId, ai);
        expect(services.current?.name, 'Plugin 1');
        expect(services.gone, isFalse);
      },
    );

    test('a chosen service that is not installed reads as gone', () async {
      await t.install();
      await t.c.read(translationServiceProvider.notifier).set('removed');
      final services = await loaded(translateServicesProvider);
      expect(services.current, isNull);
      expect(services.gone, isTrue);
      expect(services.none, isFalse);
    });
  });

  group('tune', () {
    test('model, style and note come from the plugin’s own settings', () async {
      final ai = await t.install(manifest: aiManifest);
      final commands = t.c.read(translationCommandsProvider);
      final sub = t.c.listen(translateTuneProvider(ai), (_, _) {});
      addTearDown(sub.close);
      await t.settle();
      var tune = sub.read().requireValue!;
      expect(tune.model?.options.map((o) => o.value), ['fast', 'smart']);
      expect(tune.style?.options, hasLength(1));
      expect(tune.hasNote, isTrue);
      expect(tune.modelValue, isNull);
      expect(tune.note, '');
      expect(await commands.setModel(ai, 'smart'), ConfigWrite.written);
      expect(await commands.setNote(ai, 'Giữ tên riêng'), ConfigWrite.written);
      await t.settle();
      tune = sub.read().requireValue!;
      expect(tune.modelValue, 'smart');
      expect(tune.modelTitle, 'Smart');
      expect(tune.note, 'Giữ tên riêng');
    });

    test('a plugin without the fields has none of them', () async {
      final plain = await t.install();
      final sub = t.c.listen(translateTuneProvider(plain), (_, _) {});
      addTearDown(sub.close);
      await t.settle();
      final tune = sub.read().requireValue!;
      expect(tune.model, isNull);
      expect(tune.style, isNull);
      expect(tune.hasNote, isFalse);
    });

    test('a plugin that is not installed has no tune', () async {
      final sub = t.c.listen(translateTuneProvider('nope'), (_, _) {});
      addTearDown(sub.close);
      await t.settle();
      expect(sub.read().requireValue, isNull);
    });
  });

  group('settings diff', () {
    TranslateTune tune({
      String? model = 'smart',
      String? style = 'plain',
      String note = '',
      int version = 1,
    }) => TranslateTune(
      installId: 'x',
      pluginName: 'AI',
      pluginVersion: version,
      modelValue: model,
      styleValue: style,
      note: note,
      hasNote: true,
    );

    String made({
      String? model = 'fast',
      String? style = 'plain',
      String? hash,
      int version = 1,
    }) => jsonEncode({
      'pluginVersion': version,
      'model': model,
      'style': style,
      'instructionHash': hash,
    });

    test('names a changed model, not an unchanged style', () {
      final diff = translateSettingsDiff(made(), tune());
      expect(diff.model, ('fast', 'smart'));
      expect(diff.style, isNull);
      expect(diff.note, isFalse);
      expect(diff.version, isFalse);
    });

    test('a note added since is a change; the same note is not', () {
      expect(translateSettingsDiff(made(), tune(note: 'a')).note, isTrue);
      final withNote = translateSettingsDiff(
        made(model: 'smart'),
        tune(note: 'a'),
      );
      expect(withNote.note, isTrue);
      expect(withNote.model, isNull);
    });

    test('a newer plugin version is a change', () {
      final diff = translateSettingsDiff(
        made(model: 'smart'),
        tune(version: 2),
      );
      expect(diff.version, isTrue);
      expect(diff.isEmpty, isFalse);
    });

    test('unreadable text reads as everything changed', () {
      final diff = translateSettingsDiff('{not json', tune());
      expect(diff.model, isNotNull);
      expect(diff.version, isTrue);
    });
  });
}
