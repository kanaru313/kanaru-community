import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/remover.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../data/install_test_support.dart';
import '../domain/plugin_test_support.dart';
import 'support/fake_plugin_engine.dart';
import 'support/runner_support.dart';

/// A config store whose first `read` answers with what it saw at the call and
/// then waits: setup that outlives a plugin switch.
class _SlowFirstRead extends PluginConfigStore {
  _SlowFirstRead(InstallHarness h) : super(h.db, h.rows);

  final release = Completer<void>();
  final entered = Completer<void>();
  var _first = true;

  @override
  Future<PluginConfigData> read(String installId) async {
    final data = await super.read(installId);
    if (_first) {
      _first = false;
      entered.complete();
      await release.future;
    }
    return data;
  }
}

class _SyncThrowEngine extends FakePluginEngine {
  @override
  Future<EngineResult> run(EngineRequest request, EngineFetch fetch) =>
      throw StateError('sync');
}

Future<void> waitFor(bool Function() done) async {
  for (var i = 0; i < 400 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue, reason: 'the condition was never met');
}

void main() {
  late InstallHarness h;
  late RunnerHarness r;

  final form = withConfig({
    'note': {'title': 'Note', 'mode': 'input', 'format': 'text'},
    'key': {
      'title': 'Key',
      'mode': 'input',
      'format': 'text',
      'required': true,
    },
  });

  Future<void> start({
    FakePluginEngine? engine,
    int slots = 4,
    Map<String, Object?>? manifest,
    Map<String, Object> extra = const {},
    PluginConfigStore Function(InstallHarness)? config,
  }) async {
    h = InstallHarness(exclusiveWait: const Duration(milliseconds: 60));
    r = RunnerHarness(
      h,
      engine: engine,
      slots: slots,
      config: config?.call(h),
      grace: const Duration(milliseconds: 60),
    );
    await r.install(manifest: manifest, extra: extra);
  }

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  group('a bridge that throws', () {
    test('reset throwing ends the run and frees the slot', () async {
      final engine = FakePluginEngine()..resetThrows = true;
      final hold = Completer<void>();
      await start(engine: engine);
      final first = await r.runner.run(runRequest());
      expect((first as RunFailed).reason, RunFailReason.internal);

      engine.script = (_, _) async {
        await hold.future;
        return FakePluginEngine.okResult();
      };
      final runs = [for (var i = 0; i < 4; i++) r.runner.run(runRequest())];
      await waitFor(() => engine.active == 4);
      hold.complete();
      expect((await Future.wait(runs)).every((o) => o is RunOk), isTrue);
    });

    test('a cancel that throws does not stop the others or a remove', () async {
      final engine = FakePluginEngine()..cancelThrows = true;
      engine.script = (req, _) => engine.untilCancelled(req.job);
      await start(engine: engine);
      final a = r.runner.run(runRequest());
      final b = r.runner.run(runRequest());
      await waitFor(() => engine.active == 2);

      expect(
        await h.actions.remover.remove(demoPluginId),
        RemoveResult.removed,
      );
      for (final outcome in await Future.wait([a, b])) {
        expect((outcome as RunCancelled).reason, RunCancelReason.pluginChanged);
      }
      expect(engine.cancelled.toSet(), {1, 2});
    });

    test(
      'a run call that throws at once leaves no timer and no slot',
      () async {
        final engine = _SyncThrowEngine();
        await start(engine: engine, slots: 1);
        final outcome = await r.runner.run(
          runRequest(timeout: const Duration(milliseconds: 10)),
        );
        expect((outcome as RunFailed).reason, RunFailReason.internal);
        expect(engine.cancelled, [
          1,
        ], reason: 'the begun job is cancelled once');

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(engine.cancelled, [1], reason: 'no deadline timer fired later');
        final again = await r.runner.run(runRequest());
        expect((again as RunFailed).reason, RunFailReason.internal);
        expect(engine.beginCalls, 2, reason: 'the slot was free');
      },
    );
  });

  group('a plugin switch', () {
    test('setup that outlives the switch starts over on the new row', () async {
      late _SlowFirstRead slow;
      await start(manifest: form, config: (h) => slow = _SlowFirstRead(h));
      final run = r.runner.run(runRequest());
      await slow.entered.future;

      // The old read saw no value for the required key; the switch sets one.
      await h.runGate.exclusive(demoPluginId, () async {
        await h.actions.configWrites.setValue(demoPluginId, 'key', 'abc');
      });
      slow.release.complete();

      expect(await run, isA<RunOk>(), reason: 'not the stale needs-config');
    });

    test('a run waiting for a slot starts over on the new row', () async {
      final engine = FakePluginEngine();
      var calls = 0;
      engine.script = (req, _) {
        if (++calls == 1) return engine.untilCancelled(req.job);
        return Future.value(FakePluginEngine.okResult());
      };
      await start(engine: engine, slots: 1, manifest: form);
      await h.actions.configWrites.setValue(demoPluginId, 'key', 'abc');
      final holder = r.runner.run(runRequest());
      await waitFor(() => engine.active == 1);
      final waiting = r.runner.run(runRequest());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      var begunDuringSwitch = -1;
      await h.runGate.exclusive(demoPluginId, () async {
        await h.actions.configWrites.setValue(demoPluginId, 'note', 'new');
        begunDuringSwitch = engine.beginCalls;
      });

      expect(
        ((await holder) as RunCancelled).reason,
        RunCancelReason.pluginChanged,
      );
      expect(await waiting, isA<RunOk>());
      expect(begunDuringSwitch, 1, reason: 'the waiting run had not begun');
      final sent = {for (final (k, v) in engine.requests.last.config) k: v};
      expect(sent['note'], '"new"');
    });

    test('a run asked during a remove ends not installed', () async {
      await start();
      final hold = Completer<void>();
      final job = h.queue.run(() => hold.future);
      final remove = h.actions.remover.remove(demoPluginId);
      await turns(20);
      final run = r.runner.run(runRequest());
      await turns(20);
      expect(r.engine.beginCalls, 0);

      hold.complete();
      await job;
      expect(await remove, RemoveResult.removed);
      final outcome = await run;
      expect(
        (outcome as RunUnavailable).reason,
        RunUnavailableReason.notInstalled,
      );
      expect(r.engine.beginCalls, 0);
    });

    for (final callerFirst in [true, false]) {
      test('the first cause wins (caller first: $callerFirst)', () async {
        final engine = FakePluginEngine();
        engine.script = (req, _) => engine.untilCancelled(req.job);
        await start(engine: engine);
        final cancel = RunCancel();
        final run = r.runner.run(runRequest(), cancel: cancel);
        await waitFor(() => engine.active == 1);

        // Both stop signals reach the job before the engine answers.
        final hold = Completer<void>();
        if (callerFirst) cancel.cancel();
        final switching = h.runGate.exclusive(demoPluginId, () => hold.future);
        if (!callerFirst) cancel.cancel();
        await turns(10);
        hold.complete();
        await switching;

        final outcome = await run;
        expect(
          (outcome as RunCancelled).reason,
          callerFirst ? RunCancelReason.caller : RunCancelReason.pluginChanged,
        );
      });
    }
  });

  group('stop paths guard the bridge', () {
    test('a caller cancel never throws when the runtime cancel does', () async {
      final engine = FakePluginEngine()..cancelThrows = true;
      engine.script = (req, _) => engine.untilCancelled(req.job);
      await start(engine: engine);
      final cancel = RunCancel();
      final run = r.runner.run(runRequest(), cancel: cancel);
      await waitFor(() => engine.active == 1);

      expect(cancel.cancel, returnsNormally);
      expect(((await run) as RunCancelled).reason, RunCancelReason.caller);
    });

    test('the deadline answers even when the runtime cancel throws', () async {
      final engine = FakePluginEngine()..cancelThrows = true;
      engine.script = (req, _) => engine.untilCancelled(req.job);
      await start(engine: engine);
      final outcome = await r.runner.run(
        runRequest(timeout: const Duration(milliseconds: 20)),
      );
      expect((outcome as RunFailed).reason, RunFailReason.timeout);
    });

    test('the runtime is told once per job whatever stops it', () async {
      final engine = FakePluginEngine();
      engine.script = (req, _) => engine.untilCancelled(req.job);
      await start(engine: engine);
      final cancel = RunCancel();
      final run = r.runner.run(
        runRequest(timeout: const Duration(milliseconds: 20)),
        cancel: cancel,
      );
      await waitFor(() => engine.active == 1);
      cancel.cancel();
      await run;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(engine.cancelCalls, 1);
    });

    test(
      'a throwing listener on the job token cannot skip the cancel',
      () async {
        final engine = FakePluginEngine();
        r = RunnerHarness(
          h = InstallHarness(),
          engine: engine,
          handler: RecordingFetchHandler((_, ctx) async {
            ctx.cancel.listen(() => throw StateError('bad listener'));
            return EngineFetchResponse.failure(EngineFetchOutcome.network);
          }),
        );
        await r.install();
        engine.script = (req, fetch) async {
          await fetch(
            EngineFetchRequest(
              installId: req.installId,
              method: 'GET',
              url: 'https://x.example.com',
              headers: const [],
              body: Uint8List(0),
              deadlineMs: 1000,
              maxSends: 10,
            ),
          );
          return engine.untilCancelled(req.job);
        };
        final cancel = RunCancel();
        final run = r.runner.run(runRequest(), cancel: cancel);
        await waitFor(() => r.handler.seen.isNotEmpty);

        expect(cancel.cancel, returnsNormally);
        expect(((await run) as RunCancelled).reason, RunCancelReason.caller);
        expect(engine.cancelled, [1]);
      },
    );
  });

  group('kinds', () {
    test('another kind is not installed and nothing starts', () async {
      await start();
      final outcome = await r.runner.run(
        runRequest(kinds: {PluginKind.translate, PluginKind.aiTranslate}),
      );
      expect(
        (outcome as RunUnavailable).reason,
        RunUnavailableReason.notInstalled,
      );
      expect(r.engine.beginCalls, 0);
    });

    test('an empty set checks nothing; a matching set runs', () async {
      await start();
      expect(await r.runner.run(runRequest()), isA<RunOk>());
      expect(
        await r.runner.run(runRequest(kinds: {PluginKind.lyrics})),
        isA<RunOk>(),
      );
    });

    test('the translate family accepts both translate kinds', () async {
      await start(
        manifest: translateManifest(),
        extra: {'src/translate.js': 'function execute() {}'},
      );
      final id = (await h.rows.live()).single.installId;
      final outcome = await r.runner.run(
        runRequest(
          installId: id,
          script: 'translate',
          kinds: {PluginKind.translate, PluginKind.aiTranslate},
        ),
      );
      expect(outcome, isA<RunOk>());
    });
  });

  test('saved endpoints must fit the form; empty items are dropped', () async {
    final manifest = withConfig({
      'one': {'title': 'One', 'mode': 'input', 'format': 'url'},
      'many': {'title': 'Many', 'mode': 'list', 'format': 'url'},
    });
    final engine = FakePluginEngine((req, fetch) async {
      await fetch(
        EngineFetchRequest(
          installId: req.installId,
          method: 'GET',
          url: 'https://x.example.com',
          headers: const [],
          body: Uint8List(0),
          deadlineMs: 1000,
          maxSends: 10,
        ),
      );
      return FakePluginEngine.okResult();
    });
    await start(engine: engine, manifest: manifest);
    await h.actions.configWrites.setValue(demoPluginId, 'many', [
      'https://ok.example.com',
    ]);
    // Written straight to the table: the save path would refuse these.
    await h.db.customStatement(
      'UPDATE plugin_data SET config_json = ? WHERE install_id = ?',
      [
        '{"one":"not a url","many":["https://ok.example.com","",'
            '"https://also.example.com"]}',
        demoPluginId,
      ],
    );
    await r.runner.run(runRequest());
    final endpoints = r.handler.seen.single.$2.userEndpoints;
    expect(endpoints.contains('not a url'), isFalse);
    expect(endpoints.contains(''), isFalse);

    await h.db.customStatement(
      'UPDATE plugin_data SET config_json = ? WHERE install_id = ?',
      [
        '{"one":"https://mine.example.com","many":["https://ok.example.com"]}',
        demoPluginId,
      ],
    );
    r.handler.seen.clear();
    await r.runner.run(runRequest());
    expect(r.handler.seen.single.$2.userEndpoints, {
      'https://mine.example.com',
      'https://ok.example.com',
    });
  });
}
