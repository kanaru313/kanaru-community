import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/translation/translate_runner.dart';
import 'package:kanaru/src/lyrics/domain/translation/translate_input.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/plugins/data/run/plugin_pauses.dart';
import 'package:kanaru/src/plugins/data/run/plugin_runner.dart'
    show defaultRatePause;
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../../support/fake_plugin_runner.dart';
import '../support/translation_test_support.dart';

const _id = 'plugin-a';
final _now = DateTime.utc(2026, 11, 24, 12);

void main() {
  late FakePluginRunner fake;
  late PluginPauses pauses;
  late TranslateRunner runner;

  setUp(() {
    fake = FakePluginRunner();
    pauses = PluginPauses(now: () => _now);
    runner = TranslateRunner(fake, pauses, now: () => _now);
  });
  tearDown(() => pauses.dispose());

  Future<ChunkResult> run({
    List<String> lines = const ['a', 'b'],
    RunCancel? cancel,
  }) => runner.runChunk(
    installId: _id,
    lines: lines,
    to: 'vi',
    timeout: const Duration(seconds: 20),
    song: const SongContext(title: 'T', artist: 'A'),
    allLines: const ['a', 'b', 'c'],
    cancel: cancel,
  );

  ChunkResult expectFailure(ChunkResult r, TranslationFailure f) {
    expect(r, isA<ChunkFailed>().having((c) => c.failure, 'failure', f));
    return r;
  }

  group('the request', () {
    test('is a translate run of the translate family, input logging off, '
        'no configAppend', () async {
      fake.on(_id, 'translate', (r, _) => translated(r));
      final result = await run();
      expect(result, isA<ChunkDone>());
      final request = fake.calls.single;
      expect(request.script, 'translate');
      expect(request.installId, _id);
      expect(request.logInput, isFalse);
      expect(request.configAppend, isEmpty);
      expect(request.timeout, const Duration(seconds: 20));
      expect(request.kinds, {PluginKind.translate, PluginKind.aiTranslate});
      final input = request.input! as Map;
      expect(input['lines'], ['a', 'b']);
      expect(input['to'], 'vi');
      expect((input['song']! as Map)['lyrics'], 'a\nb\nc');
      expect((input['song']! as Map)['title'], 'T');
    });

    test('hands the caller\'s cancel to the runner', () async {
      final cancel = RunCancel();
      fake.blockUntilCancelled(_id, 'translate');
      final pending = run(cancel: cancel);
      await pumpEventQueue();
      cancel.cancel();
      expect(await pending, isA<ChunkCancelled>());
      expect(fake.cancelled, hasLength(1));
    });
  });

  group('every outcome variant is mapped', () {
    final cases = <String, (RunOutcome, Object Function())>{
      'RunScriptError auth': (
        const RunScriptError(RunErrorKind.auth, 'x'),
        () => const ChunkFailed(TranslationFailure.badKey()),
      ),
      'RunScriptError quota': (
        const RunScriptError(RunErrorKind.quota, 'x'),
        () => const ChunkFailed(TranslationFailure.quota()),
      ),
      'RunScriptError invalidResponse': (
        const RunScriptError(RunErrorKind.invalidResponse, 'x'),
        () => const ChunkFailed(TranslationFailure.invalidResponse()),
      ),
      'RunScriptError server': (
        const RunScriptError(RunErrorKind.server, 'x'),
        () => const ChunkFailed(TranslationFailure.server()),
      ),
      'RunScriptError unavailable': (
        const RunScriptError(RunErrorKind.unavailable, 'x'),
        () => const ChunkFailed(TranslationFailure.server()),
      ),
      'RunScriptError unsupported': (
        const RunScriptError(RunErrorKind.unsupported, 'x'),
        () => const ChunkFailed(TranslationFailure.server()),
      ),
      'RunScriptError network': (
        const RunScriptError(RunErrorKind.network, 'x'),
        () => const ChunkFailed(TranslationFailure.network()),
      ),
      'RunFailed timeout': (
        const RunFailed(RunFailReason.timeout),
        () => const ChunkFailed(TranslationFailure.network()),
      ),
      'RunFailed memory': (
        const RunFailed(RunFailReason.memory),
        () => const ChunkFailed(TranslationFailure.invalidResponse()),
      ),
      'RunFailed stack': (
        const RunFailed(RunFailReason.stack),
        () => const ChunkFailed(TranslationFailure.invalidResponse()),
      ),
      'RunFailed outputTooLarge': (
        const RunFailed(RunFailReason.outputTooLarge),
        () => const ChunkFailed(TranslationFailure.invalidResponse()),
      ),
      'RunFailed internal': (
        const RunFailed(RunFailReason.internal),
        () => const ChunkFailed(TranslationFailure.server()),
      ),
      'RunCancelled caller': (
        const RunCancelled(RunCancelReason.caller),
        () => const ChunkCancelled(),
      ),
      'RunCancelled pluginChanged': (
        const RunCancelled(RunCancelReason.pluginChanged),
        () => const ChunkRequeue(RequeueReason.pluginChanged),
      ),
      'RunBusy': (
        const RunBusy(),
        () => const ChunkRequeue(RequeueReason.busy),
      ),
      'RunNeedsConfig': (
        const RunNeedsConfig(['Key']),
        () => const ChunkFailed(TranslationFailure.needsConfig(['Key'])),
      ),
      'RunUnavailable notInstalled': (
        const RunUnavailable(RunUnavailableReason.notInstalled),
        () => const ChunkFailed(TranslationFailure.pluginGone()),
      ),
      'RunUnavailable packageUnreadable': (
        const RunUnavailable(RunUnavailableReason.packageUnreadable),
        () => const ChunkFailed(TranslationFailure.server()),
      ),
      'RunUnavailable noScript': (
        const RunUnavailable(RunUnavailableReason.noScript),
        () => const ChunkFailed(TranslationFailure.server()),
      ),
    };

    for (final entry in cases.entries) {
      test(entry.key, () async {
        fake.answer(_id, 'translate', entry.value.$1);
        final result = await run();
        final expected = entry.value.$2();
        expect(result.runtimeType, expected.runtimeType);
        if (expected is ChunkFailed) {
          expect((result as ChunkFailed).failure, expected.failure);
        } else if (expected is ChunkRequeue) {
          expect((result as ChunkRequeue).reason, expected.reason);
        }
      });
    }

    test('RunPaused is rateLimited until the pause ends', () async {
      final until = _now.add(const Duration(minutes: 3));
      fake.answer(_id, 'translate', RunPaused(until));
      expectFailure(await run(), TranslationFailure.rateLimited(until));
    });

    test(
      'a rate-limited script error uses the pause the runner started',
      () async {
        pauses.pause(_id, const Duration(minutes: 2));
        fake.answer(
          _id,
          'translate',
          const RunScriptError(
            RunErrorKind.rateLimited,
            'x',
            retryAfter: Duration(seconds: 5),
          ),
        );
        expectFailure(
          await run(),
          TranslationFailure.rateLimited(_now.add(const Duration(minutes: 2))),
        );
      },
    );

    test(
      'without a pause it falls back to retryAfter, then the default',
      () async {
        fake.answer(
          _id,
          'translate',
          const RunScriptError(
            RunErrorKind.rateLimited,
            'x',
            retryAfter: Duration(seconds: 30),
          ),
        );
        expectFailure(
          await run(),
          TranslationFailure.rateLimited(_now.add(const Duration(seconds: 30))),
        );
        fake.answer(
          _id,
          'translate',
          const RunScriptError(RunErrorKind.rateLimited, 'x'),
        );
        expectFailure(
          await run(),
          TranslationFailure.rateLimited(_now.add(defaultRatePause)),
        );
      },
    );
  });

  group('RunOk', () {
    test('a good answer is a chunk, not an echo', () async {
      fake.on(_id, 'translate', (r, _) => translated(r));
      final result = await run() as ChunkDone;
      expect(result.chunk.texts, {'a': 'T:a', 'b': 'T:b'});
      expect(result.chunk.isEcho, isFalse);
      expect(fake.rejectedOutputs, isEmpty);
    });

    test(
      'an answer that breaks the output rules is reported and fails',
      () async {
        fake.answer(_id, 'translate', RunOk(jsonEncode(['only one'])));
        expectFailure(await run(), const TranslationFailure.invalidResponse());
        expect(fake.rejectedOutputs.single.$1, _id);
        expect(fake.rejectedOutputs.single.$2, 'translate');
        expect(fake.rejectedOutputs.single.$3, 'wrong item count');
      },
    );

    test(
      'an echo with no failure behind it is a chunk (already target)',
      () async {
        fake.on(_id, 'translate', (r, _) => echoed(r));
        final result = await run() as ChunkDone;
        expect(result.chunk.isEcho, isTrue);
      },
    );

    test(
      'an echo with a caught fetch failure fails with that failure',
      () async {
        for (final (kind, expected) in [
          (FetchFailureKind.network, const TranslationFailure.network()),
          (FetchFailureKind.abandoned, const TranslationFailure.network()),
          (FetchFailureKind.blockedHost, const TranslationFailure.server()),
          (FetchFailureKind.notConsented, const TranslationFailure.server()),
          (FetchFailureKind.invalidRequest, const TranslationFailure.server()),
          (
            FetchFailureKind.invalidResponse,
            const TranslationFailure.invalidResponse(),
          ),
          (
            FetchFailureKind.rateLimited,
            TranslationFailure.rateLimited(_now.add(defaultRatePause)),
          ),
        ]) {
          fake.on(
            _id,
            'translate',
            (r, _) => RunOk(
              echoed(r).outputJson,
              fetchFailure: FetchFailureInfo(kind: kind),
            ),
          );
          expectFailure(await run(), expected);
        }
      },
    );

    test(
      'an echo after a 429 is rateLimited by the wait the script saw',
      () async {
        fake.on(
          _id,
          'translate',
          (r, _) => RunOk(
            echoed(r).outputJson,
            rateLimitSeen: const Duration(minutes: 4),
          ),
        );
        expectFailure(
          await run(),
          TranslationFailure.rateLimited(_now.add(const Duration(minutes: 4))),
        );
      },
    );

    test(
      'a real translation with a fetch failure inside still counts',
      () async {
        fake.on(
          _id,
          'translate',
          (r, _) => RunOk(
            translated(r).outputJson,
            fetchFailure: const FetchFailureInfo(
              kind: FetchFailureKind.network,
            ),
            rateLimitSeen: const Duration(seconds: 9),
          ),
        );
        expect(await run(), isA<ChunkDone>());
      },
    );

    test('a rejected answer after a fetch failure is that failure, and is '
        'still reported', () async {
      fake.answer(
        _id,
        'translate',
        RunOk(
          jsonEncode([
            {'text': ''},
            {'text': ''},
          ]),
          fetchFailure: const FetchFailureInfo(kind: FetchFailureKind.network),
        ),
      );
      expectFailure(await run(), const TranslationFailure.network());
      expect(fake.rejectedOutputs.single.$3, 'mostly empty');
    });
  });
}
