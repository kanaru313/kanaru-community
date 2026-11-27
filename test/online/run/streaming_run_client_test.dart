import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/data/run/install_run_queue.dart';
import 'package:kanaru/src/online/data/run/isolate_runner.dart';
import 'package:kanaru/src/online/data/run/streaming_run_client.dart';
import 'package:kanaru/src/online/domain/contract/online_page.dart';
import 'package:kanaru/src/online/domain/contract/stream_answer.dart';
import 'package:kanaru/src/online/domain/failure/online_failure.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../../lyrics/support/fake_plugin_runner.dart';

const id = 'inst';

RunOk pageOk([int cards = 1, int pad = 0]) => RunOk(
  jsonEncode({
    'items': [
      for (var i = 0; i < cards; i++) {'id': '$i', 'title': 'Song $i'},
    ],
    if (pad > 0) 'next': 'x' * pad,
  }),
);

RunOk streamOk([String mime = 'audio/mpeg']) => RunOk(
  jsonEncode({'url': 'https://cdn.example.com/a.mp3', 'mimeType': mime}),
);

T value<T>(OnlineResult<T> r) => (r as OnlineOk<T>).value;
OnlineFailure failed<T>(OnlineResult<T> r) => (r as OnlineFailed<T>).failure;

void main() {
  late FakePluginRunner runner;
  late int isolateCalls;
  late StreamingRunClient client;

  setUp(() {
    runner = FakePluginRunner();
    isolateCalls = 0;
    client = StreamingRunClient(
      runner,
      run: <R>(f) async {
        isolateCalls++;
        return f();
      },
    );
  });

  group('requests', () {
    test('every script: no input log, streaming kind, own timeout', () async {
      runner
        ..answer(id, 'search', pageOk())
        ..answer(id, 'stream', streamOk())
        ..answer(id, 'autocomplete', RunOk(jsonEncode(['a'])));
      await client.search(id, 'q');
      await client.stream(id, 'i');
      await client.autocomplete(id, 'q');
      final byScript = {for (final c in runner.calls) c.script: c};
      expect(byScript.keys, {'search', 'stream', 'autocomplete'});
      for (final c in runner.calls) {
        expect(c.logInput, isFalse, reason: c.script);
        expect(c.kinds, {PluginKind.streaming});
      }
      expect(byScript['autocomplete']!.timeout, autocompleteTimeout);
      expect(byScript['autocomplete']!.timeout, const Duration(seconds: 5));
      expect(byScript['search']!.timeout, const Duration(seconds: 20));
      expect(byScript['stream']!.timeout, const Duration(seconds: 20));
      expect(byScript['autocomplete']!.persistStorage, isFalse);
      expect(byScript['search']!.persistStorage, isTrue);
      expect(byScript['stream']!.persistStorage, isTrue);
    });

    test('input shapes', () async {
      runner
        ..answer(id, 'search', pageOk())
        ..answer(id, 'stream', streamOk());
      await client.search(id, '  hello  ');
      await client.search(id, 'q', next: 'n1', filter: 'f1');
      await client.stream(id, 'abc');
      await client.stream(id, 'abc', fresh: true);
      final inputs = runner.calls.map((c) => c.input).toList();
      expect(inputs, [
        {'query': 'hello'},
        {'query': 'q', 'next': 'n1', 'filter': 'f1'},
        {'id': 'abc'},
        {'id': 'abc', 'fresh': true},
      ]);
    });

    test('bad arguments throw before any run', () async {
      expect(() => client.search(id, '   '), throwsArgumentError);
      expect(() => client.search(id, 'a' * 2001), throwsArgumentError);
      expect(() => client.stream(id, ''), throwsArgumentError);
      expect(runner.calls, isEmpty);
      runner.answer(id, 'search', pageOk());
      expect((await client.search(id, 'a' * 2000)), isA<OnlineOk<PageRead>>());
    });

    test('empty autocomplete query runs nothing', () async {
      expect(value(await client.autocomplete(id, '  ')), isEmpty);
      expect(runner.calls, isEmpty);
    });
  });

  group('serial per install', () {
    test('search and stream never overlap; stream jumps the queue', () async {
      final gates = <Completer<RunOutcome>>[];
      FakeScript slow(RunOutcome o) => (_, _) {
        final c = Completer<RunOutcome>();
        gates.add(c);
        return c.future.then((_) => o);
      };
      runner
        ..on(id, 'search', slow(pageOk()))
        ..on(id, 'stream', slow(streamOk()));
      final s1 = client.search(id, 'one');
      final s2 = client.search(id, 'two');
      final st = client.stream(id, 'x');
      await pumpEventQueue();
      expect(runner.calls.map((c) => c.script), ['search']);
      gates[0].complete(const RunOk(''));
      await pumpEventQueue();
      expect(runner.calls.map((c) => c.script), ['search', 'stream']);
      gates[1].complete(const RunOk(''));
      await pumpEventQueue();
      expect(runner.calls.map((c) => c.script), ['search', 'stream', 'search']);
      gates[2].complete(const RunOk(''));
      await Future.wait([s1, s2, st]);
      expect(runner.maxInFlight, 1);
    });

    test('another install is not blocked', () async {
      runner
        ..blockUntilCancelled(id, 'search')
        ..answer('other', 'search', pageOk());
      final cancel = RunCancel();
      final blocked = client.search(id, 'q', cancel: cancel);
      expect(await client.search('other', 'q'), isA<OnlineOk<PageRead>>());
      cancel.cancel();
      expect(await blocked, isA<OnlineAbandoned<PageRead>>());
    });
  });

  group('autocomplete', () {
    test('does not wait for a search in flight', () async {
      runner
        ..blockUntilCancelled(id, 'search')
        ..answer(id, 'autocomplete', RunOk(jsonEncode(['a', 'b'])));
      final cancel = RunCancel();
      final search = client.search(id, 'q', cancel: cancel);
      await pumpEventQueue();
      expect(value(await client.autocomplete(id, 'q')), ['a', 'b']);
      cancel.cancel();
      await search;
    });

    test('a newer call cancels the older one', () async {
      var n = 0;
      runner.on(id, 'autocomplete', (_, _) {
        if (n++ == 0) return Completer<RunOutcome>().future;
        return RunOk(jsonEncode(['new']));
      });
      final first = client.autocomplete(id, 'ab');
      await pumpEventQueue();
      final second = client.autocomplete(id, 'abc');
      expect(await first, isA<OnlineAbandoned<List<String>>>());
      expect(value(await second), ['new']);
      expect(runner.cancelled, [runner.calls.first]);
    });

    test('cancelAutocomplete abandons the running call', () async {
      runner.blockUntilCancelled(id, 'autocomplete');
      final f = client.autocomplete(id, 'ab');
      await pumpEventQueue();
      client.cancelAutocomplete(id);
      expect(await f, isA<OnlineAbandoned<List<String>>>());
    });

    test('a rejected output fails quietly: no report', () async {
      runner.answer(id, 'autocomplete', const RunOk('{"a":1}'));
      final r = await client.autocomplete(id, 'q');
      expect(failed(r).kind, OnlineFailureKind.invalidOutput);
      expect(runner.rejectedOutputs, isEmpty);
    });
  });

  group('cancel', () {
    test('while queued: abandoned, the runner never sees the call', () async {
      runner.blockUntilCancelled(id, 'search');
      final running = RunCancel();
      final first = client.search(id, 'one', cancel: running);
      await pumpEventQueue();
      final queued = RunCancel();
      final second = client.search(id, 'two', cancel: queued);
      await pumpEventQueue();
      queued.cancel();
      expect(await second, isA<OnlineAbandoned<PageRead>>());
      expect(runner.calls, hasLength(1));
      running.cancel();
      expect(await first, isA<OnlineAbandoned<PageRead>>());
    });

    test('while running: the token reaches the runner', () async {
      runner.blockUntilCancelled(id, 'stream');
      final cancel = RunCancel();
      final f = client.stream(id, 'x', cancel: cancel);
      await pumpEventQueue();
      cancel.cancel();
      expect(await f, isA<OnlineAbandoned<StreamRead>>());
      expect(runner.cancelled, hasLength(1));
    });
  });

  group('reading', () {
    test(
      'rejected output: invalidOutput and one fixed-reason report',
      () async {
        runner.answer(id, 'search', const RunOk('[1]'));
        final r = await client.search(id, 'q');
        expect(failed(r).kind, OnlineFailureKind.invalidOutput);
        expect(runner.rejectedOutputs, hasLength(1));
        expect(runner.rejectedOutputs.single.$1, id);
        expect(runner.rejectedOutputs.single.$2, 'search');
        expect(
          runner.rejectedOutputs.single.$3,
          'search output must be an object',
        );
      },
    );

    test('rejected stream output is reported under its script', () async {
      runner.answer(id, 'stream', const RunOk('nope'));
      expect(
        failed(await client.stream(id, 'x')).kind,
        OnlineFailureKind.invalidOutput,
      );
      expect(runner.rejectedOutputs.single.$2, 'stream');
    });

    test(
      'a page with dropped cards is ok and its summary is reported',
      () async {
        runner.answer(
          id,
          'search',
          RunOk(
            jsonEncode({
              'items': [
                {'id': '1', 'title': 'Ok'},
                {'title': 'no id'},
              ],
            }),
          ),
        );
        final read = value(await client.search(id, 'q'));
        expect(read.notes, isNotEmpty);
        expect(runner.rejectedOutputs.single.$3, read.rejectionSummary);
      },
    );

    test('empty page with a network failure inside is a failure', () async {
      runner.answer(
        id,
        'search',
        RunOk(
          jsonEncode({'items': []}),
          fetchFailure: const FetchFailureInfo(kind: FetchFailureKind.network),
        ),
      );
      final r = await client.search(id, 'q');
      expect(failed(r).kind, OnlineFailureKind.network);
    });

    test('non-empty page with the same failure is ok', () async {
      runner.answer(
        id,
        'search',
        RunOk(
          pageOk().outputJson,
          fetchFailure: const FetchFailureInfo(kind: FetchFailureKind.network),
        ),
      );
      expect(await client.search(id, 'q'), isA<OnlineOk<PageRead>>());
    });

    test('an HLS stream is ok with StreamUnsupported', () async {
      runner.answer(id, 'stream', streamOk('application/x-mpegurl'));
      final read = value(await client.stream(id, 'x'));
      expect(read, isA<StreamUnsupported>());
      expect((read as StreamUnsupported).mediaType, 'application/x-mpegurl');
    });

    test('failures from the outcome come back as failed', () async {
      runner.answer(id, 'stream', const RunScriptError(RunErrorKind.auth, 'm'));
      expect(
        failed(await client.stream(id, 'x')).kind,
        OnlineFailureKind.authRequired,
      );
      runner.answer(id, 'search', const RunBusy());
      expect(failed(await client.search(id, 'q')).kind, OnlineFailureKind.busy);
    });

    test(
      'large output goes through the isolate runner, small does not',
      () async {
        runner.answer(id, 'search', pageOk(1));
        await client.search(id, 'q');
        expect(isolateCalls, 0);
        runner.answer(
          id,
          'search',
          RunOk(
            jsonEncode({
              'items': [
                {
                  'id': '1',
                  'title': 'T',
                  'subtitle': 'x' * (onlineIsolateThreshold),
                },
              ],
            }),
          ),
        );
        expect(await client.search(id, 'q'), isA<OnlineResult<PageRead>>());
        expect(isolateCalls, 1);
      },
    );
  });

  test('the queue is idle after calls end', () async {
    final queue = InstallRunQueue();
    final c = StreamingRunClient(runner, queue: queue);
    runner.answer(id, 'search', pageOk());
    await c.search(id, 'q');
    expect(queue.isIdle(id), isTrue);
  });
}
