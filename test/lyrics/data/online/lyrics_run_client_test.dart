import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/online/lyrics_run_client.dart';
import 'package:kanaru/src/lyrics/data/online/source_run.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../../support/fake_plugin_runner.dart';

const _id = 'p1';

void main() {
  late FakePluginRunner runner;
  late LyricsRunClient client;
  var isolateRuns = 0;
  setUp(() {
    isolateRuns = 0;
    runner = FakePluginRunner();
    client = LyricsRunClient(
      runner,
      run: <R>(f) async {
        isolateRuns++;
        return await f();
      },
    );
  });

  Future<SourceRun<Object?>> search([String? script]) => client.searchByTags(
    _id,
    title: 'Song',
    artist: 'Artist',
    artists: const ['Artist'],
    album: null,
    duration: const Duration(seconds: 200),
  );

  Future<SourceRun<Object?>> lyrics() => client.fetchLyrics(_id, '7');

  void expectFailed(SourceRun<Object?> run, SourceFailKind kind) {
    expect(run, isA<SourceFailed<Object?>>());
    expect((run as SourceFailed).kind, kind);
  }

  group('the lyrics column of the run contract', () {
    test('a clean answer is read', () async {
      runner.answer(_id, 'search', searchAnswer([searchItem()]));
      expect(await search(), isA<SourceOk<Object?>>());
    });

    test('empty with a failed fetch or a rate limit is a failure', () async {
      runner.answer(
        _id,
        'search',
        const RunOk(
          '[]',
          fetchFailure: FetchFailureInfo(kind: FetchFailureKind.network),
        ),
      );
      expectFailed(await search(), SourceFailKind.network);
      runner.answer(
        _id,
        'search',
        const RunOk('[]', rateLimitSeen: Duration(seconds: 90)),
      );
      final limited = await search() as SourceFailed;
      expect(limited.kind, SourceFailKind.rateLimited);
      expect(limited.retryAfter, const Duration(seconds: 90));
      runner.answer(
        _id,
        'lyrics',
        const RunOk(
          'null',
          fetchFailure: FetchFailureInfo(
            kind: FetchFailureKind.invalidResponse,
          ),
        ),
      );
      expectFailed(await lyrics(), SourceFailKind.invalid);
    });

    test('a found result with a failed fetch inside still counts', () async {
      const sticky = FetchFailureInfo(kind: FetchFailureKind.network);
      runner.answer(
        _id,
        'search',
        RunOk(searchAnswer([searchItem()]).outputJson, fetchFailure: sticky),
      );
      expect(await search(), isA<SourceOk<Object?>>());
      runner.answer(
        _id,
        'lyrics',
        RunOk(
          lyricsAnswer(plain: 'words').outputJson,
          fetchFailure: sticky,
          rateLimitSeen: const Duration(seconds: 5),
        ),
      );
      expect(await lyrics(), isA<SourceOk<Object?>>());
    });

    test('script errors', () async {
      final cases = {
        RunErrorKind.rateLimited: SourceFailKind.rateLimited,
        RunErrorKind.auth: SourceFailKind.server,
        RunErrorKind.quota: SourceFailKind.rateLimited,
        RunErrorKind.server: SourceFailKind.server,
        RunErrorKind.unavailable: SourceFailKind.server,
        RunErrorKind.unsupported: SourceFailKind.server,
        RunErrorKind.network: SourceFailKind.network,
        RunErrorKind.invalidResponse: SourceFailKind.invalid,
      };
      for (final e in cases.entries) {
        runner.answer(
          _id,
          'search',
          RunScriptError(e.key, 'x', retryAfter: const Duration(seconds: 30)),
        );
        final run = await search();
        expectFailed(run, e.value);
      }
      runner.answer(
        _id,
        'search',
        const RunScriptError(
          RunErrorKind.rateLimited,
          'x',
          retryAfter: Duration(seconds: 30),
        ),
      );
      expect(
        ((await search()) as SourceFailed).retryAfter,
        const Duration(seconds: 30),
      );
    });

    test('failed runs', () async {
      final cases = {
        RunFailReason.timeout: SourceFailKind.network,
        RunFailReason.memory: SourceFailKind.invalid,
        RunFailReason.stack: SourceFailKind.invalid,
        RunFailReason.outputTooLarge: SourceFailKind.invalid,
        RunFailReason.internal: SourceFailKind.server,
      };
      for (final e in cases.entries) {
        runner.answer(_id, 'search', RunFailed(e.key));
        expectFailed(await search(), e.value);
      }
    });

    test('cancelled, busy, paused, config and unavailable are skips', () async {
      runner.answer(_id, 'search', const RunCancelled(RunCancelReason.caller));
      expect(await search(), isA<SourceAbandoned<Object?>>());
      final skips = <RunOutcome, SourceSkip>{
        const RunCancelled(RunCancelReason.pluginChanged):
            SourceSkip.pluginChanged,
        const RunBusy(): SourceSkip.busy,
        RunPaused(DateTime.utc(2026)): SourceSkip.paused,
        const RunNeedsConfig(['Token']): SourceSkip.needsConfig,
        const RunUnavailable(RunUnavailableReason.notInstalled):
            SourceSkip.unavailable,
        const RunUnavailable(RunUnavailableReason.noScript):
            SourceSkip.unavailable,
      };
      for (final e in skips.entries) {
        runner.answer(_id, 'search', e.key);
        final run = await search();
        expect(run, isA<SourceSkipped<Object?>>());
        expect((run as SourceSkipped).reason, e.value);
      }
      runner.answer(_id, 'search', RunPaused(DateTime.utc(2027)));
      expect(((await search()) as SourceSkipped).until, DateTime.utc(2027));
    });
  });

  group('bad output', () {
    test('is a failure, reported by reason only, never by its text', () async {
      runner.answer(_id, 'search', const RunOk('{"secret": "tok-123"}'));
      expectFailed(await search(), SourceFailKind.invalid);
      runner.answer(_id, 'lyrics', const RunOk('"tok-456"'));
      expectFailed(await lyrics(), SourceFailKind.invalid);
      expect(runner.rejectedOutputs, hasLength(2));
      for (final (_, _, reason) in runner.rejectedOutputs) {
        expect(reason, isNot(contains('tok-')));
      }
    });

    test('dropped items are reported, the valid ones used', () async {
      runner.answer(
        _id,
        'search',
        searchAnswer([
          searchItem(),
          {'id': '2'},
        ]),
      );
      final run = await search() as SourceOk;
      expect((run.value as dynamic).candidates, hasLength(1));
      expect(runner.rejectedOutputs, hasLength(1));
      expect(runner.rejectedOutputs.single.$2, 'search');
    });

    test('large output is parsed through the isolate runner', () async {
      runner.answer(_id, 'lyrics', lyricsAnswer(plain: 'x\n' * 10000));
      expect(await lyrics(), isA<SourceOk<Object?>>());
      expect(isolateRuns, 1);
      runner.answer(_id, 'lyrics', lyricsAnswer(plain: 'small'));
      await lyrics();
      expect(isolateRuns, 1);
    });
  });

  group('what a plugin receives', () {
    test('only tags for a lookup, a missing tag is null', () async {
      runner.answer(_id, 'search', searchAnswer([]));
      await client.searchByTags(
        _id,
        title: 'Song',
        artist: 'Artist',
        artists: const [],
        album: null,
        duration: const Duration(seconds: 200),
      );
      final call = runner.calls.single;
      expect(call.script, 'search');
      expect(call.input, {
        'title': 'Song',
        'artist': 'Artist',
        'artists': null,
        'album': null,
        'durationMs': 200000,
      });
      expect(call.timeout, const Duration(seconds: 30));
      expect(call.kinds, {PluginKind.lyrics});
    });

    test('the manual search sends the text only, a fetch the id', () async {
      runner.answer(_id, 'search', searchAnswer([]));
      runner.answer(_id, 'lyrics', lyricsAnswer(plain: 'w'));
      await client.searchByText(_id, 'artist song');
      await client.fetchLyrics(_id, '42');
      expect(runner.calls[0].input, {'text': 'artist song'});
      expect(runner.calls[1].script, 'lyrics');
      expect(runner.calls[1].input, '42');
    });
  });
}
