import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/fetch_handler.dart';
import 'package:kanaru/src/plugins/data/run/plugin_pauses.dart';
import 'package:kanaru/src/plugins/data/run/plugin_runner.dart';
import 'package:kanaru/src/plugins/data/run/run_admission.dart';
import 'package:kanaru/src/plugins/data/run/run_log_recorder.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/data/store/plugin_storage_store.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';

import '../../data/install_test_support.dart';
import 'fake_plugin_engine.dart';
import '../../domain/plugin_test_support.dart';
import '../../fixtures/zip_builders.dart';

/// The install id of the demo lyrics plugin of the test packages.
final demoPluginId = fileInstallId('Demo', 'someone');

/// A handler that records the requests and answers [answer] (default: 200).
class RecordingFetchHandler implements PluginFetchHandler {
  RecordingFetchHandler([this.answer]);

  Future<EngineFetchResponse> Function(
    EngineFetchRequest request,
    JobContext context,
  )?
  answer;
  final seen = <(EngineFetchRequest, JobContext)>[];

  @override
  Future<EngineFetchResponse> handle(
    EngineFetchRequest request,
    JobContext context,
  ) async {
    seen.add((request, context));
    return answer?.call(request, context) ??
        EngineFetchResponse(
          outcome: EngineFetchOutcome.ok,
          status: 200,
          body: Uint8List(0),
        );
  }
}

/// A runner over [h]'s database, folders and run gate with a fake engine.
class RunnerHarness {
  RunnerHarness(
    this.h, {
    FakePluginEngine? engine,
    RecordingFetchHandler? handler,
    Duration spacing = Duration.zero,
    Duration grace = const Duration(milliseconds: 80),
    int slots = 4,
    PluginConfigStore? config,
    PluginStorageStore? storage,
    DateTime Function()? clock,
  }) : engine = engine ?? FakePluginEngine(),
       handler = handler ?? RecordingFetchHandler(),
       pauses = PluginPauses() {
    runner = PluginRunner(
      engine: this.engine,
      handler: this.handler,
      gate: h.runGate,
      pauses: pauses,
      rows: h.rows,
      files: h.files,
      config: config ?? h.config,
      storage: storage ?? h.storage,
      recorder: RunLogRecorder(
        log: h.logs,
        rows: h.rows,
        config: config ?? h.config,
        storage: storage ?? h.storage,
        clock: clock,
      ),
      admission: RunAdmission(slots: slots),
      spacing: spacing,
      grace: grace,
    );
  }

  final InstallHarness h;
  final FakePluginEngine engine;
  final RecordingFetchHandler handler;
  final PluginPauses pauses;
  late final PluginRunner runner;

  void dispose() => pauses.dispose();

  /// Installs the demo plugin from a file zip made from [manifest].
  Future<void> install({
    Map<String, Object?>? manifest,
    Map<String, Object> extra = const {},
  }) async {
    final held = await h.prepareFile(
      validZip(manifest: manifest ?? validManifest(), extra: extra),
    );
    final result = await h.actions.installer.install(held.token);
    if (result is! Installed) throw StateError('install failed: $result');
  }
}

PluginRunRequest runRequest({
  String? installId,
  String script = 'search',
  Map<String, Object?> input = const {'title': 'x'},
  Duration timeout = const Duration(seconds: 30),
  Map<String, String> configAppend = const {},
  Set<PluginKind> kinds = const {},
}) => PluginRunRequest(
  installId: installId ?? demoPluginId,
  script: script,
  input: input,
  timeout: timeout,
  configAppend: configAppend,
  kinds: kinds,
);

/// Spins the event loop until [done] (at most ~2 s).
Future<void> waitFor(bool Function() done) async {
  for (var i = 0; i < 400 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue, reason: 'the condition was never met');
}
