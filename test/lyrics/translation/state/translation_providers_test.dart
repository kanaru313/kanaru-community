import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_cache_store.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_commands.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../../plugins/domain/plugin_test_support.dart';
import '../support/translation_harness.dart';
import '../support/translation_test_support.dart';

RunOk _prefixed(String prefix, List<String> lines, {String? detected = 'ja'}) =>
    RunOk(
      jsonEncode([
        for (final l in lines) {'text': '$prefix$l', 'detected': ?detected},
      ]),
    );

void main() {
  late TranslationHarness t;
  late String svc;
  late TrackId id;

  setUp(() async {
    t = TranslationHarness();
    svc = await t.install();
    id = await t.song('a.flac');
    await t.turnOn();
    t.chooseService(svc);
    t.h.runner.on(svc, 'translate', (r, _) => translated(r));
  });
  tearDown(() => t.dispose());

  ProviderSubscription<TranslationView> watch(TrackId track) =>
      t.c.listen(trackTranslationProvider(track), (_, _) {});

  Future<void> untilStatus(
    ProviderSubscription<TranslationView> sub,
    bool Function(TranslationStatus) test,
  ) => t.h.until(() => test(sub.read().status));

  /// The saved row of [install] for [lines] into [to].
  Future<TranslationCacheRow?> rowOf(
    String install,
    List<String> lines, {
    String to = 'vi',
  }) => t.c.read(translationCacheStoreProvider).lookup((
    contentHash: hashOf(lines),
    installId: install,
    targetLang: to,
  ));

  group('when it runs', () {
    test('translation off: nothing is read, asked or run', () async {
      await t.turnOn(false);
      t.show(id, ['hello']);
      final sub = watch(id);
      await t.settle();
      expect(sub.read(), TranslationView.idle);
      expect(t.timers, isEmpty);
      expect(t.h.runner.calls, isEmpty);
    });

    test('no shown lyrics: idle', () async {
      final sub = watch(id);
      await t.settle();
      expect(sub.read(), TranslationView.idle);
      expect(t.timers, isEmpty);
    });

    test('an unknown service (list still loading) never runs', () async {
      t.c.read(serviceBoxProvider.notifier).set(const AsyncLoading());
      t.show(id, ['hello']);
      final sub = watch(id);
      await t.settle();
      expect(sub.read(), TranslationView.idle);
      expect(t.timers, isEmpty);
    });

    test('no service chosen and no saved translation: noService', () async {
      t.chooseService(null);
      t.show(id, ['hello']);
      final sub = watch(id);
      await untilStatus(sub, (s) => s is StatusFailed);
      expect(
        sub.read().status,
        const TranslationStatus.failed(TranslationFailure.noService()),
      );
      expect(t.timers, isEmpty);
      expect(t.h.runner.calls, isEmpty);
    });

    test('the chosen service is removed while shown: noService, the run is '
        'dropped', () async {
      final hand = HandRuns();
      t.h.runner.on(svc, 'translate', hand.call);
      t.show(id, List.generate(12, (i) => 'line $i'));
      final sub = watch(id);
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.single.fire();
      await t.settle();
      t.chooseService(null);
      await t.settle();
      hand.answer(translated);
      await t.settle();
      expect(
        sub.read().status,
        const TranslationStatus.failed(TranslationFailure.noService()),
      );
      expect(t.h.runner.calls, hasLength(1), reason: 'chunk 2 not sent');
    });
  });

  group('a job', () {
    test('starts after the 1 s debounce, then shows ready; showing it again '
        'is a cache hit', () async {
      t.show(id, ['hello', 'world', 'hello']);
      final seen = <TranslationStatus>[];
      final sub = t.c.listen(
        trackTranslationProvider(id),
        (_, n) => seen.add(n.status),
      );
      await t.h.until(() => t.timers.isNotEmpty);
      expect(sub.read().status, const TranslationStatus.loading(0, 0));
      expect(t.timers.single.after, const Duration(seconds: 1));
      expect(t.h.runner.calls, isEmpty, reason: 'nothing before the debounce');

      t.timers.single.fire();
      await untilStatus(sub, (s) => s is StatusReady);
      final view = sub.read();
      expect(view.map, {'hello': 'T:hello', 'world': 'T:world'});
      expect(view.sourceLang, 'ja');
      expect(view.installId, svc);
      expect(view.settingsDiffer, isFalse);
      expect(seen, contains(const TranslationStatus.loading(0, 1)));

      final request = t.h.runner.calls.single;
      expect(sentLines(request), ['hello', 'world']);
      expect(request.configAppend, isEmpty);
      expect(request.logInput, isFalse);
      final input = request.input! as Map;
      expect(input['to'], 'vi');
      expect((input['song']! as Map)['title'], 'Song');
      expect((input['song']! as Map)['artist'], 'Artist');

      sub.close();
      await t.settle();
      final again = watch(id);
      await untilStatus(again, (s) => s is StatusReady);
      expect(t.h.runner.calls, hasLength(1));
      expect(t.armed, isEmpty);
    });

    test('rapid song changes start no job for the skipped songs', () async {
      final a = id;
      final b = await t.song('b.flac');
      final c = await t.song('c.flac');
      for (final track in [a, b, c]) {
        t.show(track, ['line of ${track.value}']);
      }
      for (final track in [a, b]) {
        final sub = watch(track);
        await t.h.until(() => t.armed.isNotEmpty);
        sub.close();
        await t.settle();
      }
      final last = watch(c);
      await t.h.until(() => t.armed.isNotEmpty);
      for (final timer in t.timers) {
        timer.fire(); // the skipped songs' timers were cancelled
      }
      await untilStatus(last, (s) => s is StatusReady);
      expect(t.h.runner.calls.map(sentLines), [
        ['line of ${c.value}'],
      ]);
    });

    test('every view gone mid-chunk: the chunk is cached and the row '
        'completed', () async {
      final hand = HandRuns();
      t.h.runner.on(svc, 'translate', hand.call);
      t.show(id, ['hello']);
      final sub = watch(id);
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.single.fire();
      await t.h.until(() => hand.running.isNotEmpty);
      sub.close();
      await t.settle();
      hand.answer(translated);
      await t.settle();
      final row = await rowOf(svc, ['hello']);
      expect(row!.complete, isTrue);
      expect(row.lines, {'hello': 'T:hello'});
    });

    test('the view goes away during chunk 1: chunk 2 is never sent', () async {
      final hand = HandRuns();
      t.h.runner.on(svc, 'translate', hand.call);
      final lines = List.generate(12, (i) => 'line $i');
      t.show(id, lines);
      final sub = watch(id);
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.single.fire();
      await t.h.until(() => hand.running.isNotEmpty);
      sub.close();
      await t.settle();
      hand.answer(translated);
      await t.settle();
      expect(t.h.runner.calls, hasLength(1));
      final row = await rowOf(svc, lines);
      expect(row!.complete, isFalse);
      expect(row.lines.length, 10);
    });

    test(
      'switching translation off keeps the sent chunk and stops the rest',
      () async {
        final hand = HandRuns();
        t.h.runner.on(svc, 'translate', hand.call);
        final lines = List.generate(12, (i) => 'line $i');
        t.show(id, lines);
        final sub = watch(id);
        await t.h.until(() => t.timers.isNotEmpty);
        t.timers.single.fire();
        await t.h.until(() => hand.running.isNotEmpty);
        await t.c.read(translationCommandsProvider).toggle();
        await t.settle();
        expect(sub.read(), TranslationView.idle);
        hand.answer(translated);
        await t.settle();
        expect(t.h.runner.calls, hasLength(1));
        expect((await rowOf(svc, lines))!.lines.length, 10);
      },
    );

    test(
      'a failure shows, nothing retries by itself, retry sends it again',
      () async {
        var n = 0;
        t.h.runner.on(svc, 'translate', (r, _) {
          n++;
          return n == 1
              ? const RunScriptError(RunErrorKind.quota, 'x')
              : translated(r);
        });
        t.show(id, ['hello']);
        final sub = watch(id);
        await t.h.until(() => t.timers.isNotEmpty);
        t.timers.single.fire();
        await untilStatus(sub, (s) => s is StatusFailed);
        expect(
          sub.read().status,
          const TranslationStatus.failed(TranslationFailure.quota()),
        );
        await t.settle();
        expect(t.h.runner.calls, hasLength(1));

        t.c.read(translationCommandsProvider).retry(id);
        await untilStatus(sub, (s) => s is StatusReady);
        expect(t.h.runner.calls, hasLength(2));
      },
    );

    test(
      'a database read failure shows as an error and translation stays on',
      () async {
        await t.dispose();
        t = TranslationHarness(brokenCache: true);
        svc = await t.install();
        id = await t.song('a.flac');
        await t.turnOn();
        t.chooseService(svc);
        t.show(id, ['hello']);
        final sub = watch(id);
        await untilStatus(sub, (s) => s is StatusFailed);
        expect(
          sub.read().status,
          const TranslationStatus.failed(TranslationFailure.server()),
        );
        expect(t.c.read(translationOnProvider), isTrue);
        expect(t.h.runner.calls, isEmpty);
      },
    );
  });

  group('the saved translation', () {
    Future<void> saveRow(
      String install, {
      String? source = 'ja',
      String settings = '{}',
      bool complete = true,
      int createdAt = 1,
      String to = 'vi',
      List<String> lyrics = const ['hello'],
    }) => t.c
        .read(translationCacheStoreProvider)
        .replace(
          TranslationCacheRow(
            key: (
              contentHash: hashOf(lyrics),
              installId: install,
              targetLang: to,
            ),
            sourceLang: source,
            lines: {'hello': 'saved by $install'},
            settingsJson: settings,
            complete: complete,
            createdAt: createdAt,
          ),
        );

    test(
      'another live plugin\'s translation is shown without any run',
      () async {
        final other = await t.install();
        await saveRow(other);
        t.show(id, ['hello']);
        final sub = watch(id);
        await untilStatus(sub, (s) => s is StatusOther);
        expect(sub.read().status, TranslationStatus.other(other));
        expect(sub.read().map, {'hello': 'saved by $other'});
        expect(sub.read().installId, other);
        await t.settle();
        expect(t.timers, isEmpty);
        expect(t.h.runner.calls, isEmpty);
      },
    );

    test(
      'the chosen service\'s own complete row wins over another\'s',
      () async {
        final other = await t.install();
        await saveRow(other, createdAt: 9);
        await saveRow(svc, createdAt: 1);
        t.show(id, ['hello']);
        final sub = watch(id);
        await untilStatus(sub, (s) => s is StatusReady);
        expect(sub.read().map, {'hello': 'saved by $svc'});
        expect(t.h.runner.calls, isEmpty);
      },
    );

    test('a removed plugin\'s translation is never shown', () async {
      final other = await t.install();
      await saveRow(other);
      await t.c.read(pluginRowsProvider).remove(other);
      t.show(id, ['hello']);
      final sub = watch(id);
      await t.h.until(() => t.timers.isNotEmpty);
      expect(sub.read().status, const TranslationStatus.loading(0, 0));
    });

    test('lyrics already in the target language: same', () async {
      await saveRow(svc, source: 'vi');
      t.show(id, ['hello']);
      final sub = watch(id);
      await untilStatus(sub, (s) => s is StatusSame);
      expect(sub.read().status, const TranslationStatus.same('vi'));
    });

    test('an incomplete row is never ready: the job resumes it', () async {
      await saveRow(svc, complete: false, lyrics: ['hello', 'world']);
      t.show(id, ['hello', 'world']);
      final sub = watch(id);
      await t.h.until(() => t.timers.isNotEmpty);
      expect(sub.read().status, const TranslationStatus.loading(0, 0));
      t.timers.single.fire();
      await untilStatus(sub, (s) => s is StatusReady);
      expect(sentLines(t.h.runner.calls.single), ['world']);
    });

    test('settings that differ from the plugin\'s now are flagged, nothing '
        're-runs', () async {
      await saveRow(svc, settings: '{"pluginVersion":0}');
      t.show(id, ['hello']);
      final sub = watch(id);
      await untilStatus(sub, (s) => s is StatusReady);
      expect(sub.read().settingsDiffer, isTrue);
      expect(t.h.runner.calls, isEmpty);
    });
  });

  group('Dịch lại', () {
    test('keeps the old translation on screen, replaces it when done, can be '
        'cancelled', () async {
      t.show(id, ['hello']);
      final sub = watch(id);
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.single.fire();
      await untilStatus(sub, (s) => s is StatusReady);
      final commands = t.c.read(translationCommandsProvider);

      final hand = HandRuns();
      t.h.runner.on(svc, 'translate', hand.call);
      commands.retranslate(id);
      await t.h.until(
        () =>
            sub.read().status ==
            const TranslationStatus.loading(0, 1, background: true),
      );
      expect(sub.read().map, {'hello': 'T:hello'});
      hand.answer((r) => _prefixed('NEW:', sentLines(r)));
      await untilStatus(sub, (s) => s is StatusReady);
      expect(sub.read().map, {'hello': 'NEW:hello'});

      t.h.runner.blockUntilCancelled(svc, 'translate');
      commands.retranslate(id);
      await t.h.until(() => t.h.runner.calls.length == 3);
      commands.cancelRetranslate(id);
      await untilStatus(sub, (s) => s is StatusReady);
      expect(sub.read().map, {'hello': 'NEW:hello'});
      expect(t.h.runner.cancelled, hasLength(1));
    });
  });

  group('Dịch lại and a settings save', () {
    test(
      'a save of the plugin settings during Dịch lại does not drop it',
      () async {
        final ai = await t.install(manifest: () => aiManifest());
        t.chooseService(ai);
        t.h.runner.on(ai, 'translate', (r, _) => translated(r));
        t.show(id, ['hello']);
        final sub = watch(id);
        await t.h.until(() => t.timers.isNotEmpty);
        t.timers.single.fire();
        await untilStatus(sub, (s) => s is StatusReady);

        final hand = HandRuns();
        t.h.runner.on(ai, 'translate', hand.call);
        final commands = t.c.read(translationCommandsProvider);
        commands.retranslate(id);
        await t.h.until(() => hand.running.isNotEmpty);
        await commands.setNote(ai, 'be kind');
        await t.settle();
        expect(
          sub.read().status,
          const TranslationStatus.loading(0, 1, background: true),
        );
        expect(sub.read().map, {'hello': 'T:hello'});
        hand.answer((r) => _prefixed('NEW:', sentLines(r)));
        await t.h.until(() => sub.read().map['hello'] == 'NEW:hello');
        expect(sub.read().status, const TranslationStatus.ready());
        expect(t.h.runner.calls, hasLength(2), reason: 'no resend');
      },
    );

    test('a fresh view of a song whose Dịch lại failed shows the failure '
        'over the saved translation', () async {
      t.show(id, ['hello']);
      final first = watch(id);
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.single.fire();
      await untilStatus(first, (s) => s is StatusReady);

      t.h.runner.answer(
        svc,
        'translate',
        const RunScriptError(RunErrorKind.auth, 'x'),
      );
      t.c.read(translationCommandsProvider).retranslate(id);
      await untilStatus(first, (s) => s is StatusFailed);
      expect(first.read().map, {'hello': 'T:hello'});

      first.close();
      await t.settle();
      final fresh = watch(id);
      await untilStatus(fresh, (s) => s is StatusFailed);
      expect(
        fresh.read().status,
        const TranslationStatus.failed(TranslationFailure.badKey()),
      );
      expect(fresh.read().map, {'hello': 'T:hello'});
      expect(t.h.runner.calls, hasLength(2), reason: 'no automatic retry');
    });
  });

  group('per-song language', () {
    test('a language picked for the song is the target of its job', () async {
      final commands = t.c.read(translationCommandsProvider);
      expect(await commands.setTarget(id, 'en'), isTrue);
      expect(() => commands.setTarget(id, 'xx'), throwsArgumentError);
      t.show(id, ['hello']);
      final sub = watch(id);
      await t.h.until(() => t.armed.isNotEmpty);
      t.timers.last.fire();
      await untilStatus(sub, (s) => s is StatusReady);
      expect((t.h.runner.calls.single.input! as Map)['to'], 'en');
    });

    test('the global target applies when the song has none', () async {
      await t.c.read(translationTargetProvider.notifier).set('en');
      t.show(id, ['hello']);
      final sub = watch(id);
      await t.h.until(() => t.armed.isNotEmpty);
      t.timers.last.fire();
      await untilStatus(sub, (s) => s is StatusReady);
      expect((t.h.runner.calls.single.input! as Map)['to'], 'en');
    });
  });

  group('the playing track', () {
    test('follows the track that plays; idle when nothing plays', () async {
      t.show(id, ['hello']);
      final sub = t.c.listen(playingTranslationProvider, (_, _) {});
      await t.settle();
      expect(sub.read(), TranslationView.idle);
      t.h.play(id);
      await t.h.until(() => t.timers.isNotEmpty);
      t.timers.single.fire();
      await t.h.until(() => sub.read().status is StatusReady);
      expect(sub.read().map, {'hello': 'T:hello'});
    });
  });

  group('commands', () {
    test('toggle, service and display are the settings', () async {
      final commands = t.c.read(translationCommandsProvider);
      await commands.toggle();
      expect(t.c.read(translationOnProvider), isFalse);
      await commands.toggle();
      expect(t.c.read(translationOnProvider), isTrue);
      await commands.setService(null);
      expect(t.c.read(translationServiceProvider), isNull);
      await commands.setService(svc);
      expect(t.c.read(translationServiceProvider), svc);
      await commands.setDisplay(TranslationDisplay.replace);
      expect(t.c.read(translationDisplayProvider), TranslationDisplay.replace);
    });

    test('model, style and note write the plugin config only for keys the '
        'plugin declares', () async {
      final commands = t.c.read(translationCommandsProvider);
      expect(await commands.setModel(svc, 'x'), ConfigWrite.unknownKey);

      final ai = await t.install(manifest: () => aiManifest());
      expect(await commands.setModel(ai, 'smart'), ConfigWrite.written);
      expect(await commands.setStyle(ai, 'plain'), ConfigWrite.written);
      expect(await commands.setNote(ai, 'be kind'), ConfigWrite.written);
      final values = (await t.c.read(pluginConfigStoreProvider).read(ai))
          .values;
      expect(values['model'], 'smart');
      expect(values['style'], 'plain');
      expect(values['customInstruction'], 'be kind');
    });

    test(
      'a saved model marks the translation as made with other settings',
      () async {
        final ai = await t.install(manifest: () => aiManifest());
        t.chooseService(ai);
        t.h.runner.on(ai, 'translate', (r, _) => translated(r));
        t.show(id, ['hello']);
        final sub = watch(id);
        await t.h.until(() => t.timers.isNotEmpty);
        t.timers.single.fire();
        await untilStatus(sub, (s) => s is StatusReady);
        expect(sub.read().settingsDiffer, isFalse);

        await t.c.read(translationCommandsProvider).setModel(ai, 'smart');
        await t.h.until(() => sub.read().settingsDiffer);
        expect(
          t.h.runner.calls,
          hasLength(1),
          reason: 'never re-runs by itself',
        );
      },
    );
  });
}
