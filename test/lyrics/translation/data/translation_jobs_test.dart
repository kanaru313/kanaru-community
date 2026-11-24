import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_cache_store.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_job_types.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../support/translation_test_support.dart';

const _a = 'plugin-a';
final _key = keyOf('h1');
const TranslationKey _cacheKey = (
  contentHash: 'h1',
  installId: _a,
  targetLang: 'vi',
);

JobRequest _req(List<String> lines) => JobRequest(lines: lines);

void main() {
  late EngineRig rig;
  final w1 = Object();
  final w2 = Object();

  EngineRig newRig({TranslationCacheStore Function(dynamic)? cache}) {
    final r = EngineRig(cache: cache == null ? null : (db) => cache(db));
    r.services.plugins[_a] = snapshotOf(_a, maxLines: 2);
    return r;
  }

  setUp(() => rig = newRig());
  tearDown(() => rig.dispose());

  Future<TranslationCacheRow?> row([TranslationKey? key]) =>
      rig.store.lookup(key ?? _cacheKey);

  group('a job', () {
    test(
      'sends the chunks one by one, caches each, then completes the row',
      () async {
        rig.runner.on(_a, 'translate', (r, _) => translated(r));
        rig.jobs.request(_key, _req(['a', 'b', 'c', 'd', 'e']), w1);
        await rig.jobs.whenIdle();

        expect(rig.runner.calls.map(sentLines), [
          ['a', 'b'],
          ['c', 'd'],
          ['e'],
        ]);
        final saved = (await row())!;
        expect(saved.complete, isTrue);
        expect(saved.lines['e'], 'T:e');
        expect(saved.sourceLang, 'ja');
        expect(saved.settingsJson, '{"pluginVersion":1}');
        expect(rig.jobs.statuses, isEmpty);
        final running = [
          for (final s in rig.seen)
            if (s[_key] case final JobRunning r) (r.done, r.total),
        ];
        expect(running, [(0, 0), (0, 3), (1, 3), (2, 3)]);
      },
    );

    test('sends no configAppend and never logs the input', () async {
      rig.runner.on(_a, 'translate', (r, _) => translated(r));
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      for (final call in rig.runner.calls) {
        expect(call.configAppend, isEmpty);
        expect(call.logInput, isFalse);
      }
    });

    test('is joined, not run twice, when two views ask for it', () async {
      rig.runner.on(_a, 'translate', (r, _) => translated(r));
      rig.jobs.request(_key, _req(['a']), w1);
      rig.jobs.request(_key, _req(['a']), w2);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, hasLength(1));
    });

    test('a complete row is not sent again', () async {
      rig.runner.on(_a, 'translate', (r, _) => translated(r));
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, hasLength(1));
    });

    test('over the caps nothing is sent: tooLong', () async {
      rig.services.plugins[_a] = snapshotOf(_a, maxLines: 1);
      rig.jobs.request(
        _key,
        _req([for (var i = 0; i < 21; i++) 'line $i']),
        w1,
      );
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, isEmpty);
      expect(
        rig.jobs.statuses[_key],
        const JobFailed(TranslationFailure.tooLong(), version: 1),
      );
    });
  });

  group('the gate', () {
    test(
      'two songs requested never run at once, first come first served',
      () async {
        final hand = HandRuns();
        rig.runner.on(_a, 'translate', hand.call);
        rig.jobs.request(keyOf('h1'), _req(['a']), w1);
        rig.jobs.request(keyOf('h2'), _req(['b']), w2);
        await pumpEventQueue();
        expect(hand.running.map(sentLines), [
          ['a'],
        ]);
        hand.answer(translated);
        await pumpEventQueue();
        expect(hand.running.map(sentLines), [
          ['b'],
        ]);
        hand.answer(translated);
        await rig.jobs.whenIdle();
        expect(rig.runner.maxInFlight, 1);
        expect(rig.runner.calls, hasLength(2));
      },
    );

    test('a queued job nobody wants any more is never sent', () async {
      final hand = HandRuns();
      rig.runner.on(_a, 'translate', hand.call);
      rig.jobs.request(keyOf('h1'), _req(['a']), w1);
      rig.jobs.request(keyOf('h2'), _req(['b']), w2);
      await pumpEventQueue();
      rig.jobs.release(keyOf('h2'), w2);
      hand.answer(translated);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls.map(sentLines), [
        ['a'],
      ]);
      expect(rig.jobs.statuses, isEmpty);
      expect(
        await row((contentHash: 'h2', installId: _a, targetLang: 'vi')),
        isNull,
      );
    });

    test(
      'switching translation off drops the unsent chunks, keeps the sent',
      () async {
        final hand = HandRuns();
        rig.runner.on(_a, 'translate', hand.call);
        rig.jobs.request(_key, _req(['a', 'b', 'c', 'd']), w1);
        await pumpEventQueue();
        rig.on = false;
        hand.answer(translated);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls, hasLength(1));
        final saved = (await row())!;
        expect(saved.lines.keys, ['a', 'b']);
        expect(saved.complete, isFalse);
        expect(rig.jobs.statuses, isEmpty);
      },
    );
  });

  group('a sent chunk is never lost', () {
    test(
      'the song changes during chunk 1: chunk 1 cached, chunk 2 not sent',
      () async {
        final hand = HandRuns();
        rig.runner.on(_a, 'translate', hand.call);
        rig.jobs.request(_key, _req(['a', 'b', 'c', 'd']), w1);
        await pumpEventQueue();
        rig.jobs.release(_key, w1);
        hand.answer(translated);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls, hasLength(1));
        final saved = (await row())!;
        expect(saved.lines, {'a': 'T:a', 'b': 'T:b'});
        expect(saved.complete, isFalse);
      },
    );

    test('every view gone mid-chunk: the chunk is cached and the row '
        'completed', () async {
      final hand = HandRuns();
      rig.runner.on(_a, 'translate', hand.call);
      rig.jobs.request(_key, _req(['a', 'b']), w1);
      rig.jobs.request(_key, _req(['a', 'b']), w2);
      await pumpEventQueue();
      rig.jobs.release(_key, w1);
      rig.jobs.release(_key, w2);
      hand.answer(translated);
      await rig.jobs.whenIdle();
      final saved = (await row())!;
      expect(saved.lines, {'a': 'T:a', 'b': 'T:b'});
      expect(saved.complete, isTrue);
    });

    test(
      'killed after chunk 1 of 3: a new engine sends only chunks 2 and 3',
      () async {
        final hand = HandRuns();
        rig.runner.on(_a, 'translate', hand.call);
        rig.jobs.request(_key, _req(['a', 'b', 'c', 'd', 'e']), w1);
        await pumpEventQueue();
        hand.answer(translated); // chunk 1 is cached
        await pumpEventQueue();
        expect(hand.running.map(sentLines), [
          ['c', 'd'],
        ]);
        rig.jobs.dispose(); // the app dies with chunk 2 in flight
        hand.answer(translated);
        await pumpEventQueue();
        expect((await row())!.lines.keys, ['a', 'b']);

        rig.runner.calls.clear();
        rig.runner.on(_a, 'translate', (r, _) => translated(r));
        rig.jobs = rig.newEngine();
        rig.jobs.request(_key, _req(['a', 'b', 'c', 'd', 'e']), w1);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls.map(sentLines), [
          ['c', 'd'],
          ['e'],
        ]);
        expect((await row())!.complete, isTrue);
      },
    );

    test('a disposed engine writes nothing and notifies nobody', () async {
      final hand = HandRuns();
      rig.runner.on(_a, 'translate', hand.call);
      rig.jobs.request(_key, _req(['a']), w1);
      await pumpEventQueue();
      final before = rig.changes;
      rig.jobs.dispose();
      hand.answer(translated);
      await pumpEventQueue();
      expect(rig.changes, before);
      expect(await row(), isNull);
    });
  });

  group('failures', () {
    test('chunk 2 of 3 fails: the failure stays, nothing retries by itself, '
        'a retry sends only chunks 2 and 3', () async {
      var n = 0;
      rig.runner.on(_a, 'translate', (r, _) {
        n++;
        return n == 2
            ? const RunScriptError(RunErrorKind.server, 'x')
            : translated(r);
      });
      rig.jobs.request(_key, _req(['a', 'b', 'c', 'd', 'e']), w1);
      await rig.jobs.whenIdle();
      expect(
        rig.jobs.statuses[_key],
        const JobFailed(TranslationFailure.server(), version: 1),
      );
      expect(rig.runner.calls, hasLength(2));
      expect((await row())!.lines.keys, ['a', 'b']);

      // Asking again (a view comes back) does not bill again.
      rig.jobs.request(_key, _req(['a', 'b', 'c', 'd', 'e']), w2);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, hasLength(2));

      rig.jobs.request(_key, _req(['a', 'b', 'c', 'd', 'e']), w1, retry: true);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls.skip(2).map(sentLines), [
        ['c', 'd'],
        ['e'],
      ]);
      expect(rig.jobs.statuses, isEmpty);
      expect((await row())!.complete, isTrue);
    });

    test(
      'RunBusy is sent again once, a second one is a server failure',
      () async {
        rig.runner.answerInOrder(_a, 'translate', [
          const RunBusy(),
          const RunBusy(),
        ]);
        rig.jobs.request(_key, _req(['a']), w1);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls, hasLength(2));
        expect(
          rig.jobs.statuses[_key],
          const JobFailed(TranslationFailure.server(), version: 1),
        );
      },
    );

    test('RunBusy then a good answer succeeds', () async {
      var n = 0;
      rig.runner.on(_a, 'translate', (r, _) {
        n++;
        return n == 1 ? const RunBusy() : translated(r);
      });
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, hasLength(2));
      expect((await row())!.complete, isTrue);
      expect(rig.jobs.statuses, isEmpty);
    });

    test(
      'RunPaused is rateLimited until the pause ends, nothing cached',
      () async {
        final until = rig.clock.add(const Duration(minutes: 2));
        rig.runner.answer(_a, 'translate', RunPaused(until));
        rig.jobs.request(_key, _req(['a']), w1);
        await rig.jobs.whenIdle();
        expect(
          rig.jobs.statuses[_key],
          JobFailed(TranslationFailure.rateLimited(until), version: 1),
        );
        expect(await row(), isNull);
      },
    );

    test(
      'an echo with a fetch failure is a failure and is not cached',
      () async {
        rig.runner.on(
          _a,
          'translate',
          (r, _) => RunOk(
            echoed(r).outputJson,
            fetchFailure: const FetchFailureInfo(
              kind: FetchFailureKind.network,
            ),
          ),
        );
        rig.jobs.request(_key, _req(['a']), w1);
        await rig.jobs.whenIdle();
        expect(
          rig.jobs.statuses[_key],
          const JobFailed(TranslationFailure.network(), version: 1),
        );
        expect(await row(), isNull);
      },
    );

    test('a removed plugin is pluginGone and nothing is sent', () async {
      rig.services.plugins[_a] = null;
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, isEmpty);
      expect(
        rig.jobs.statuses[_key],
        const JobFailed(TranslationFailure.pluginGone()),
      );
    });

    test(
      'a database read failure is a failure with a retry, never a crash',
      () async {
        await rig.dispose();
        rig = newRig(cache: (db) => BrokenCacheStore(db));
        rig.jobs.request(_key, _req(['a']), w1);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls, isEmpty);
        expect(
          rig.jobs.statuses[_key],
          const JobFailed(TranslationFailure.server()),
        );
      },
    );

    test('a plugin read failure is a failure, never a crash', () async {
      rig.services.failSnapshot = true;
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      expect(
        rig.jobs.statuses[_key],
        const JobFailed(TranslationFailure.server()),
      );
    });

    test(
      'a failure is bound to the plugin version: a newer one tries again',
      () async {
        rig.runner.answer(
          _a,
          'translate',
          const RunScriptError(RunErrorKind.server, 'x'),
        );
        rig.jobs.request(_key, _req(['a']), w1);
        await rig.jobs.whenIdle();
        rig.jobs.request(_key, _req(['a']), w1);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls, hasLength(1), reason: 'same version: sticky');

        rig.services.plugins[_a] = snapshotOf(_a, version: 2, maxLines: 2);
        rig.jobs.request(_key, _req(['a']), w1);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls, hasLength(2));
        expect(
          rig.jobs.statuses[_key],
          const JobFailed(TranslationFailure.server(), version: 2),
        );
      },
    );
  });

  group('the plugin is switched mid-job', () {
    test('RunCancelled(pluginChanged): the partial of the old version is not '
        'reused and the chunk is sent again', () async {
      var n = 0;
      rig.runner.on(_a, 'translate', (r, _) {
        n++;
        if (n == 2) return const RunCancelled(RunCancelReason.pluginChanged);
        return translated(r, detected: n == 1 ? 'ja' : 'en');
      });
      rig.jobs.request(_key, _req(['a', 'b', 'c', 'd']), w1);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls.map(sentLines), [
        ['a', 'b'],
        ['c', 'd'],
        ['c', 'd'],
      ]);
      final saved = (await row())!;
      expect(saved.complete, isTrue);
      // A tie between 'ja' (old partial) and 'en' would have kept 'ja'.
      expect(saved.sourceLang, 'en');
      expect(rig.jobs.statuses, isEmpty);
    });

    test('a plugin that keeps being switched ends with a failure', () async {
      rig.runner.answer(
        _a,
        'translate',
        const RunCancelled(RunCancelReason.pluginChanged),
      );
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, hasLength(3));
      expect(
        rig.jobs.statuses[_key],
        const JobFailed(TranslationFailure.server(), version: 1),
      );
    });

    test(
      'a version change between chunks sends nothing for the old plan',
      () async {
        final hand = HandRuns();
        rig.runner.on(_a, 'translate', hand.call);
        rig.jobs.request(_key, _req(['a', 'b', 'c', 'd']), w1);
        await pumpEventQueue();
        rig.services.plugins[_a] = snapshotOf(
          _a,
          version: 2,
          maxLines: 2,
          settings: '{"pluginVersion":2}',
        );
        hand.answer((r) => translated(r, detected: 'ja'));
        await pumpEventQueue();
        expect(hand.running.map(sentLines), [
          ['c', 'd'],
        ]);
        hand.answer((r) => translated(r, detected: 'en'));
        await rig.jobs.whenIdle();
        final saved = (await row())!;
        expect(saved.sourceLang, 'en');
        expect(saved.settingsJson, '{"pluginVersion":2}');
      },
    );
  });

  group('saving the plugin settings', () {
    test('retries the failed song exactly once, the failure stays until it '
        'answers', () async {
      final hand = HandRuns();
      var n = 0;
      rig.runner.on(_a, 'translate', (r, c) {
        n++;
        return n == 1
            ? const RunScriptError(RunErrorKind.auth, 'x')
            : hand.call(r, c);
      });
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      expect(
        rig.jobs.statuses[_key],
        const JobFailed(TranslationFailure.badKey(), version: 1),
      );
      // Opening the plugin page again is not a save: no retry.
      await pumpEventQueue();
      expect(rig.runner.calls, hasLength(1));

      rig.services.saveConfig(_a);
      await pumpEventQueue();
      expect(rig.runner.calls, hasLength(2));
      expect(rig.jobs.statuses[_key], isA<JobFailed>());
      hand.answer(translated);
      await rig.jobs.whenIdle();
      expect(rig.jobs.statuses, isEmpty);
      expect((await row())!.complete, isTrue);

      rig.services.saveConfig(_a);
      await pumpEventQueue();
      expect(rig.runner.calls, hasLength(2));
      expect(rig.services.isWatching(_a), isFalse);
    });

    test('a retry that fails again waits for the next save', () async {
      rig.runner.answer(
        _a,
        'translate',
        const RunScriptError(RunErrorKind.auth, 'x'),
      );
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      rig.services.saveConfig(_a);
      await pumpEventQueue();
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, hasLength(2));
      await pumpEventQueue();
      expect(rig.runner.calls, hasLength(2));
      rig.services.saveConfig(_a);
      await pumpEventQueue();
      await rig.jobs.whenIdle();
      expect(rig.runner.calls, hasLength(3));
    });

    test('a failed song nobody looks at is forgotten, not billed', () async {
      rig.runner.answer(
        _a,
        'translate',
        const RunScriptError(RunErrorKind.auth, 'x'),
      );
      rig.jobs.request(_key, _req(['a']), w1);
      await rig.jobs.whenIdle();
      rig.jobs.release(_key, w1);
      rig.services.saveConfig(_a);
      await pumpEventQueue();
      expect(rig.runner.calls, hasLength(1));
      expect(rig.jobs.statuses, isEmpty);
    });

    test('a save while the chunk runs keeps it; if it then fails it is tried '
        'once more', () async {
      final hand = HandRuns();
      rig.runner.on(_a, 'translate', hand.call);
      rig.jobs.request(_key, _req(['a']), w1);
      await pumpEventQueue();
      rig.services.saveConfig(_a);
      await pumpEventQueue();
      expect(rig.runner.calls, hasLength(1), reason: 'running chunk is kept');
      hand.answer((_) => const RunScriptError(RunErrorKind.auth, 'x'));
      await pumpEventQueue();
      expect(rig.runner.calls, hasLength(2));
      hand.answer(translated);
      await rig.jobs.whenIdle();
      expect(rig.jobs.statuses, isEmpty);
      expect((await row())!.complete, isTrue);
    });

    test(
      'a save while the chunk runs and succeeds sends nothing more',
      () async {
        final hand = HandRuns();
        rig.runner.on(_a, 'translate', hand.call);
        rig.jobs.request(_key, _req(['a']), w1);
        await pumpEventQueue();
        rig.services.saveConfig(_a);
        await pumpEventQueue();
        hand.answer(translated);
        await rig.jobs.whenIdle();
        expect(rig.runner.calls, hasLength(1));
      },
    );
  });

  group('a forced re-run', () {
    Future<void> saveOld() => rig.store.replace(
      TranslationCacheRow(
        key: _cacheKey,
        sourceLang: 'ja',
        lines: const {'a': 'OLD'},
        settingsJson: '{}',
        complete: true,
        createdAt: 1,
      ),
    );

    test(
      'ignores the cache, keeps the old row until done, then replaces it',
      () async {
        await saveOld();
        final hand = HandRuns();
        rig.runner.on(_a, 'translate', hand.call);
        rig.jobs.request(_key, _req(['a']), w1, forced: true);
        await pumpEventQueue();
        expect(rig.runner.calls.map(sentLines), [
          ['a'],
        ]);
        expect(rig.jobs.statuses[_key], const JobRunning(0, 1, forced: true));
        expect((await row())!.lines, {'a': 'OLD'});
        hand.answer(translated);
        await rig.jobs.whenIdle();
        final saved = (await row())!;
        expect(saved.lines, {'a': 'T:a'});
        expect(saved.complete, isTrue);
        expect(rig.jobs.statuses, isEmpty);
      },
    );

    test('can be cancelled while unfinished: the run is cancelled, the old '
        'row stays', () async {
      await saveOld();
      rig.runner.blockUntilCancelled(_a, 'translate');
      rig.jobs.request(_key, _req(['a']), w1, forced: true);
      await pumpEventQueue();
      rig.jobs.cancelForced(_key);
      expect(rig.jobs.statuses, isEmpty);
      await rig.jobs.whenIdle();
      expect(rig.runner.cancelled, hasLength(1));
      expect((await row())!.lines, {'a': 'OLD'});
    });

    test('a normal run is never cancelled by translation', () async {
      rig.runner.blockUntilCancelled(_a, 'translate');
      rig.jobs.request(_key, _req(['a']), w1);
      await pumpEventQueue();
      rig.jobs.cancelForced(_key);
      rig.jobs.release(_key, w1);
      await pumpEventQueue();
      expect(rig.runner.cancelled, isEmpty);
      expect(rig.jobs.statuses[_key], isA<JobRunning>());
    });

    test('a failed forced run leaves the old row', () async {
      await saveOld();
      rig.runner.answer(
        _a,
        'translate',
        const RunScriptError(RunErrorKind.quota, 'x'),
      );
      rig.jobs.request(_key, _req(['a']), w1, forced: true);
      await rig.jobs.whenIdle();
      expect(
        rig.jobs.statuses[_key],
        const JobFailed(TranslationFailure.quota(), version: 1, forced: true),
      );
      expect((await row())!.lines, {'a': 'OLD'});
    });
  });
}
