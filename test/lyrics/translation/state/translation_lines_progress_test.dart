import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart' show translationAppLanguageOverride;
import 'package:kanaru/src/lyrics/data/translation/translation_cache_store.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_language.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_engine_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_commands.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/screens/settings/state/appearance_settings.dart';

import '../../../support/memory_settings_store.dart';
import '../support/translation_harness.dart';
import '../support/translation_test_support.dart';

/// 25 distinct lines: three chunks of at most 10.
final _lyrics = [for (var i = 0; i < 25; i++) 'line $i'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('lines done and total', () {
    late TranslationHarness t;
    late String svc;
    late TrackId id;

    setUp(() async {
      t = TranslationHarness();
      svc = await t.install(maxLines: 10);
      id = await t.song('a.flac');
      await t.turnOn();
      t.chooseService(svc);
    });
    tearDown(() => t.dispose());

    ProviderSubscription<TranslationView> watch() =>
        t.c.listen(trackTranslationProvider(id), (_, _) {});

    Future<void> start(ProviderSubscription<TranslationView> sub) async {
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.single.fire();
    }

    test(
      'a running job counts the lines translated, not only chunks',
      () async {
        final hand = HandRuns();
        t.h.runner.on(svc, 'translate', hand.call);
        t.show(id, [..._lyrics, _lyrics.first]);
        final sub = watch();
        await start(sub);
        await t.h.until(() => sub.read().linesTotal == 25);
        expect(sub.read().linesDone, 0);
        hand.answer(translated);
        await t.h.until(() => sub.read().linesDone == 10);
        expect(sub.read().linesTotal, 25);
        expect(sub.read().status, isA<StatusLoading>());
        hand.answer(translated);
        await t.h.until(() => sub.read().linesDone == 20);
        hand.answer(translated);
        await t.h.until(() => sub.read().status is StatusReady);
        expect(sub.read().map.keys, unorderedEquals(_lyrics));
      },
    );

    test(
      'a failure after saved chunks keeps their lines and counts them',
      () async {
        var n = 0;
        t.h.runner.on(svc, 'translate', (r, _) {
          n++;
          return n == 1
              ? translated(r)
              : const RunScriptError(RunErrorKind.quota, 'x');
        });
        t.show(id, _lyrics);
        final sub = watch();
        await start(sub);
        await t.h.until(() => sub.read().map.isNotEmpty);
        final view = sub.read();
        expect(
          view.status,
          const TranslationStatus.failed(TranslationFailure.quota()),
        );
        expect(view.map.keys, _lyrics.take(10));
        expect(view.linesDone, 10);
        expect(view.linesTotal, 25);
        expect(view.installId, svc);
        // Nothing is sent again by itself.
        await t.settle();
        expect(n, 2);
      },
    );

    test('a failure with nothing saved shows no lines', () async {
      t.h.runner.on(
        svc,
        'translate',
        (r, _) => const RunScriptError(RunErrorKind.quota, 'x'),
      );
      t.show(id, _lyrics);
      final sub = watch();
      await start(sub);
      await t.h.until(() => sub.read().status is StatusFailed);
      await t.settle();
      expect(sub.read().map, isEmpty);
      expect(sub.read().linesTotal, 0);
    });

    test(
      'the credit names the plugin and the language; partial counts',
      () async {
        var n = 0;
        t.h.runner.on(svc, 'translate', (r, _) {
          n++;
          return n == 1
              ? translated(r)
              : const RunScriptError(RunErrorKind.quota, 'x');
        });
        t.show(id, _lyrics);
        final credit = t.c.listen(translationCreditProvider(id), (_, _) {});
        await start(t.c.listen(trackTranslationProvider(id), (_, _) {}));
        await t.h.until(() => credit.read() != null);
        final partial = credit.read()!;
        expect(partial.plugin, 'Plugin 1');
        expect(partial.target, 'vi');
        expect(partial.other, isFalse);
        expect(partial.partial, isTrue);
        expect((partial.linesDone, partial.linesTotal), (10, 25));
      },
    );

    test('a complete translation is credited without counts', () async {
      t.h.runner.on(svc, 'translate', (r, _) => translated(r));
      t.show(id, ['a']);
      final credit = t.c.listen(translationCreditProvider(id), (_, _) {});
      await start(t.c.listen(trackTranslationProvider(id), (_, _) {}));
      await t.h.until(() => credit.read() != null);
      expect(credit.read()!.partial, isFalse);
      expect(credit.read()!.model, isNull);
    });

    test(
      'another plugin\'s saved translation is credited as existing',
      () async {
        final other = await t.install();
        await t.c
            .read(translationCacheStoreProvider)
            .replace(
              TranslationCacheRow(
                key: (
                  contentHash: hashOf(['a']),
                  installId: other,
                  targetLang: 'vi',
                ),
                sourceLang: 'ja',
                lines: const {'a': 'saved'},
                settingsJson: '{}',
                complete: true,
                createdAt: 1,
              ),
            );
        t.show(id, ['a']);
        final credit = t.c.listen(translationCreditProvider(id), (_, _) {});
        t.c.listen(trackTranslationProvider(id), (_, _) {});
        await t.h.until(() => credit.read() != null);
        expect(credit.read()!.other, isTrue);
        expect(credit.read()!.plugin, 'Plugin 2');
      },
    );

    test(
      'no credit while the lyrics are already in the target language',
      () async {
        await t.c
            .read(translationCacheStoreProvider)
            .replace(
              TranslationCacheRow(
                key: (
                  contentHash: hashOf(['a']),
                  installId: svc,
                  targetLang: 'vi',
                ),
                sourceLang: 'vi',
                lines: const {'a': 'a'},
                settingsJson: '{}',
                complete: true,
                createdAt: 1,
              ),
            );
        t.show(id, ['a']);
        final credit = t.c.listen(translationCreditProvider(id), (_, _) {});
        final sub = t.c.listen(trackTranslationProvider(id), (_, _) {});
        await t.h.until(() => sub.read().status is StatusSame);
        expect(credit.read(), isNull);
      },
    );
  });

  group('the target a track is translated into', () {
    late TranslationHarness t;
    late String svc;
    late TrackId id;

    Future<void> open(String language) async {
      t = TranslationHarness(language: language);
      svc = await t.install();
      id = await t.song('a.flac');
      await t.turnOn();
      t.chooseService(svc);
      t.h.runner.on(svc, 'translate', (r, _) => translated(r));
    }

    tearDown(() => t.dispose());

    Future<String> sentTarget() async {
      t.show(id, ['hello']);
      final sub = t.c.listen(trackTranslationProvider(id), (_, _) {});
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.last.fire();
      await t.h.until(() => t.h.runner.calls.isNotEmpty);
      sub.close();
      return (t.h.runner.calls.single.input! as Map)['to']! as String;
    }

    for (final (app, expected) in [('vi', 'vi'), ('en', 'en'), ('ja', 'en')]) {
      test('follows the app language: $app gives $expected', () async {
        await open(app);
        final sub = t.c.listen(
          effectiveTranslationTargetProvider(id),
          (_, _) {},
        );
        await t.settle();
        expect(sub.read(), expected);
        // The engine plans with the same answer.
        expect(await sentTarget(), expected);
      });
    }

    test('the global language beats the app language, the song\'s own beats '
        'both', () async {
      await open('vi');
      final sub = t.c.listen(effectiveTranslationTargetProvider(id), (_, _) {});
      await t.c.read(translationTargetProvider.notifier).set('ja');
      await t.settle();
      expect(sub.read(), 'ja');
      await t.c.read(translationCommandsProvider).setTarget(id, 'en');
      await t.h.until(() => sub.read() == 'en');
      expect(await sentTarget(), 'en');
    });
  });

  test('the app wires the default target to the app language', () async {
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        translationAppLanguageOverride,
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(translationAppLanguageProvider, (_, _) {});
    await container.read(appLanguageProvider.notifier).set(AppLanguage.vi);
    expect(appTarget(sub.read()), 'vi');
    await container.read(appLanguageProvider.notifier).set(AppLanguage.en);
    expect(appTarget(sub.read()), 'en');
  });

  test('pickTranslationTarget: song, then global, then app language', () {
    expect(
      pickTranslationTarget(trackPref: 'ja', global: 'ko', appLanguage: 'vi'),
      'ja',
    );
    expect(pickTranslationTarget(global: 'ko', appLanguage: 'vi'), 'ko');
    expect(pickTranslationTarget(appLanguage: 'vi'), 'vi');
    expect(pickTranslationTarget(appLanguage: 'fr'), 'en');
  });
}
