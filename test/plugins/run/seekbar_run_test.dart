import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';

import '../data/install_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'support/runner_support.dart';

/// An installed seek bar plugin has no script: a run request against it is
/// refused before anything starts, whatever the caller asked for.
void main() {
  late InstallHarness h;
  late RunnerHarness r;
  late String id;

  setUp(() async {
    h = InstallHarness();
    r = RunnerHarness(h);
    final held = await h.prepareFile(
      buildZip({
        'plugin.json':
            '{"metadata":{"apiVersion":1,"type":"seekbar","name":"Neon",'
            '"version":1,"author":"someone","license":"CC0-1.0"},'
            '"seekbar":{"track":{"kind":"flat"}}}',
      }),
    );
    final result = await h.actions.installer.install(held.token);
    id = (result as Installed).installId;
  });

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  for (final script in ['search', 'lyrics', 'translate', 'chat']) {
    test('a $script run fails cleanly with no script to run', () async {
      final outcome = await r.runner.run(
        runRequest(installId: id, script: script),
      );
      expect(outcome, isA<RunUnavailable>());
      expect((outcome as RunUnavailable).reason, RunUnavailableReason.noScript);
      expect(r.engine.requests, isEmpty, reason: 'nothing reached the engine');
    });
  }

  test('a run limited to another kind does not find it', () async {
    final outcome = await r.runner.run(
      runRequest(installId: id, kinds: {PluginKind.lyrics}),
    );
    expect(
      (outcome as RunUnavailable).reason,
      RunUnavailableReason.notInstalled,
    );
  });

  test('a stream run is refused the same way', () async {
    final outcome = await r.runner.run(
      runRequest(
        installId: id,
        script: 'stream',
        stream: StreamOptions(
          idle: const Duration(seconds: 1),
          onEvent: (_) {},
        ),
      ),
    );
    expect(outcome, isA<RunUnavailable>());
    expect(r.engine.requests, isEmpty);
  });
}
