import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/store/plugin_storage_store.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:logging/logging.dart';

import '../data/install_test_support.dart';
import 'support/fake_plugin_engine.dart';
import 'support/runner_support.dart';

/// A storage store that counts write-backs and can fail them.
class _SpyStore extends PluginStorageStore {
  _SpyStore(InstallHarness h) : super(h.db, h.queue);

  var writes = 0;
  var fail = false;

  @override
  Future<bool> writeBack(
    String installId,
    String storageJson, {
    required int expectedRev,
    required int expectedUpdatedAt,
  }) {
    writes++;
    if (fail) throw StateError('disk full');
    return super.writeBack(
      installId,
      storageJson,
      expectedRev: expectedRev,
      expectedUpdatedAt: expectedUpdatedAt,
    );
  }
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
  late _SpyStore spy;

  Future<void> start(FakePluginEngine engine) async {
    h = InstallHarness();
    spy = _SpyStore(h);
    r = RunnerHarness(
      h,
      engine: engine,
      storage: spy,
      grace: const Duration(milliseconds: 60),
    );
    await r.install();
  }

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  test('the storage a script returns is the next run\'s storage', () async {
    final engine = FakePluginEngine();
    engine.script = (req, _) async => req.entry == 'search.js'
        ? const EngineResult(
            status: EngineStatus.ok,
            outputJson: '[]',
            storageJson: '{"token":"t1"}',
          )
        : FakePluginEngine.okResult();
    await start(engine);

    expect(await r.runner.run(runRequest(script: 'search')), isA<RunOk>());
    expect(await r.runner.run(runRequest(script: 'lyrics')), isA<RunOk>());

    expect(engine.requests.first.storageJson, '');
    expect(engine.requests.last.storageJson, '{"token":"t1"}');
  });

  test('a result without storage writes nothing', () async {
    await start(FakePluginEngine());
    await r.runner.run(runRequest());
    expect(spy.writes, 0);
  });

  test('a run stopped by a plugin switch writes nothing', () async {
    final engine = FakePluginEngine();
    engine.script = (req, _) async {
      await engine.untilCancelled(req.job);
      return const EngineResult(
        status: EngineStatus.ok,
        outputJson: '[]',
        storageJson: '{"late":"x"}',
      );
    };
    await start(engine);
    final run = r.runner.run(runRequest());
    await waitFor(() => engine.active == 1);

    await h.actions.remover.remove(demoPluginId);
    // The fake answers `ok` after the stop; the runner must still not save.
    await run;
    expect(engine.cancelled, isNotEmpty);
    expect(spy.writes, 0);
  });

  test('a clear during a run keeps the run from writing back', () async {
    final engine = FakePluginEngine();
    final release = Completer<void>();
    engine.script = (req, _) async {
      await release.future;
      return const EngineResult(
        status: EngineStatus.ok,
        outputJson: '[]',
        storageJson: '{"stale":"x"}',
      );
    };
    await start(engine);
    final run = r.runner.run(runRequest());
    await waitFor(() => engine.active == 1);

    await h.actions.clearStorage(demoPluginId);
    release.complete();

    expect(await run, isA<RunOk>());
    expect(spy.writes, 1, reason: 'the guarded write was tried');
    final stored = await spy.read(demoPluginId);
    expect(stored.json, '');
    expect(stored.rev, 1);
  });

  test('a failed write still returns the outcome and logs the type', () async {
    final engine = FakePluginEngine(
      (_, _) async => const EngineResult(
        status: EngineStatus.ok,
        outputJson: '[]',
        storageJson: '{"a":"1"}',
      ),
    );
    await start(engine);
    spy.fail = true;
    final lines = <String>[];
    final sub = Logger('plugin_run').onRecord
        .listen((e) => lines.add(e.message));
    addTearDown(sub.cancel);
    Logger.root.level = Level.ALL;

    final outcome = await r.runner.run(runRequest());

    expect(outcome, isA<RunOk>());
    expect(lines.where((l) => l.contains('StateError')), hasLength(1));
    expect(lines.join(), isNot(contains('disk full')));
  });

  test('the write is saved before the run returns', () async {
    final engine = FakePluginEngine(
      (_, _) async => EngineResult(
        status: EngineStatus.ok,
        outputJson: jsonEncode([]),
        storageJson: '{"a":"1"}',
      ),
    );
    await start(engine);
    await r.runner.run(runRequest());
    expect((await spy.read(demoPluginId)).json, '{"a":"1"}');
  });
}
