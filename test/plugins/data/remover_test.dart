import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/remover.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../domain/plugin_test_support.dart';
import '../run/support/fake_plugin_engine.dart';
import '../run/support/runner_support.dart';
import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';
import 'services_test_support.dart';

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  final id = fileInstallId('Demo', 'someone');

  Future<void> installDemo({int version = 3, Object? config}) async {
    final manifest = withMeta((m) => m['version'] = version);
    if (config != null) manifest['config'] = config;
    final result = await h.actions.installer.install(
      (await h.prepareFile(validZip(manifest: manifest))).token,
    );
    expect(result, isA<Installed>());
  }

  const form = {
    'region': {'title': 'Region', 'mode': 'input', 'format': 'text'},
  };

  test('remove: tombstone, data and folder gone', () async {
    await installDemo(config: form);
    await h.actions.configWrites.setValue(id, 'region', 'vn');

    expect(await h.actions.remover.remove(id), RemoveResult.removed);

    final row = (await h.rows.byId(id))!;
    expect(row.removedAt, isNotNull);
    expect(row.packageDir, isNull);
    expect((await h.config.read(id)).values, isEmpty);
    expect(await h.files.listFolders(), isEmpty);
    expect(await h.actions.remover.remove(id), RemoveResult.alreadyRemoved);
    expect(
      await h.actions.remover.remove('plugin-${'0' * 32}'),
      RemoveResult.missing,
    );
  });

  test(
    'remove deletes the run log and drops writes queued before it',
    () async {
      await installDemo();
      RunLogEvent ev() => RunLogEvent(
        time: DateTime.now(),
        installId: id,
        pluginName: 'Demo',
        version: '3',
        script: 'search',
        kind: 'server',
      );
      h.logs.append(ev());
      await h.logs.whenIdle();
      final file = File('${h.dir.path}-logs/$id.jsonl');
      expect(file.existsSync(), isTrue);

      h.logs.append(ev());
      expect(await h.actions.remover.remove(id), RemoveResult.removed);
      await h.logs.whenIdle();

      expect(file.existsSync(), isFalse);
    },
  );

  test('the summary is read fresh', () async {
    await installDemo(config: form);
    var summary = (await h.actions.remover.removeSummary(id))!;
    expect(summary.name, 'Demo');
    expect(summary.hasUserData, isFalse);

    await h.actions.configWrites.setValue(id, 'region', 'vn');
    summary = (await h.actions.remover.removeSummary(id))!;
    expect(summary.configValues, 1);
    expect(summary.hasUserData, isTrue);

    await h.actions.remover.remove(id);
    expect(await h.actions.remover.removeSummary(id), isNull);
  });

  test(
    'a remove while an update is on its way wins; the update finds it gone',
    () async {
      final repo = await h.addRepo({'netease': {}});
      final repoId = await h.installFromRepo(repo, 'netease');
      await h.setCatalog(repo, {
        'netease': {'version': 4},
      });
      final gate = Completer<void>();
      h.fetcher.answer = (uri) async {
        await gate.future;
        return served(InstallHarness.zipOf(version: 4));
      };
      final update = h.actions.updater.update(repoId);
      await Future<void>.delayed(Duration.zero);

      expect(await h.actions.remover.remove(repoId), RemoveResult.removed);
      gate.complete();
      final result = await update;

      expect((result as InstallRefused).failure, InstallFailure.pluginGone);
      expect(await h.rows.liveById(repoId), isNull);
      expect(await h.files.listFolders(), isEmpty);
    },
  );

  group('run gate', () {
    Future<void> untilRunning(FakePluginEngine engine) async {
      for (var i = 0; i < 100 && engine.active == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(engine.active, 1);
    }

    test('a remove cancels the run in flight and completes', () async {
      await installDemo();
      final engine = FakePluginEngine();
      engine.script = (req, _) => engine.untilCancelled(req.job);
      final runs = RunnerHarness(h, engine: engine);
      addTearDown(runs.dispose);
      final run = runs.runner.run(runRequest());
      await untilRunning(engine);

      expect(await h.actions.remover.remove(id), RemoveResult.removed);

      final outcome = await run;
      expect((outcome as RunCancelled).reason, RunCancelReason.pluginChanged);
      expect(await h.files.listFolders(), isEmpty);
      expect(h.runGate.isClosed(id), isFalse);
      expect(
        (await runs.runner.run(runRequest())) is RunUnavailable,
        isTrue,
        reason: 'the plugin is gone',
      );
    });

    test(
      'a run that ignores the cancel does not hold the remove for ever',
      () async {
        final slow = InstallHarness(
          exclusiveWait: const Duration(milliseconds: 100),
        );
        final runs = RunnerHarness(
          slow,
          engine: FakePluginEngine((req, _) async {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            return const EngineResult(status: EngineStatus.cancelled);
          }),
        );
        addTearDown(() async {
          runs.dispose();
          await slow.dispose();
        });
        await runs.install();
        final run = runs.runner.run(runRequest());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final watch = Stopwatch()..start();
        expect(await slow.actions.remover.remove(id), RemoveResult.removed);
        expect(watch.elapsedMilliseconds, lessThan(500));
        expect(await run, isA<RunCancelled>());
      },
    );
  });
}
