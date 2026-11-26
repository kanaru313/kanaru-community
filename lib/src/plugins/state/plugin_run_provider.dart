import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/net/plugin_http.dart';
import '../data/net/plugin_http_stream.dart';
import '../data/run/fetch_handler.dart';
import '../data/run/plugin_limiter.dart';
import '../data/run/plugin_pauses.dart';
import '../data/run/plugin_runner.dart';
import '../data/run/run_admission.dart';
import '../data/run/run_log_recorder.dart';
import '../data/run/rust_plugin_engine.dart';
import '../data/run/stream_fetch_handler.dart';
import '../domain/run/plugin_engine.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';

/// The plugin runtime. Tests override it with a fake.
final pluginEngineProvider = Provider<PluginEngine>(
  (ref) => const RustPluginEngine(),
);

/// The request spacing clock of every plugin, shared by all runs.
final pluginLimiterProvider = Provider<PluginLimiter>((ref) => PluginLimiter());

/// The HTTP client of every plugin request, one-shot and streamed.
final pluginHttpClientProvider = Provider<PluginHttpClient>(
  (ref) => PluginHttpClient(),
);

/// The host `fetch` of a run: the only network path of a plugin.
final pluginFetchHandlerProvider = Provider<PluginFetchHandler>(
  (ref) => HttpPluginFetchHandler(
    http: ref.watch(pluginHttpClientProvider),
    limiter: ref.watch(pluginLimiterProvider),
  ),
);

/// The host side of streamed `fetch` calls (open, read, close).
final pluginStreamHandlerProvider = Provider<StreamFetchHandler>(
  (ref) => StreamFetchHandler(
    http: PluginHttpStreamClient(ref.watch(pluginHttpClientProvider)),
    limiter: ref.watch(pluginLimiterProvider),
  ),
);

/// The one slot of streaming runs. Watches nothing, so a rebuilt
/// [pluginRunnerProvider] still sees a stream that is running.
final streamRunAdmissionProvider = Provider<RunAdmission>(
  (ref) => RunAdmission(slots: 1),
);

/// The per-plugin pauses after a rate-limited run.
final pluginPausesProvider = Provider<PluginPauses>((ref) {
  final pauses = PluginPauses();
  ref.onDispose(pauses.dispose);
  return pauses;
});

/// When the pause of a plugin ends, or null when it is not paused. Updates
/// when a pause starts and when it ends.
final pluginPauseProvider = Provider.autoDispose.family<DateTime?, String>((
  ref,
  installId,
) {
  final pauses = ref.watch(pluginPausesProvider);
  ref.onDispose(pauses.listen(installId, ref.invalidateSelf));
  return pauses.until(installId);
});

/// Runs plugin scripts: the one way lyrics and translation reach a plugin.
final pluginRunnerProvider = Provider<PluginRunner>(
  (ref) => PluginRunner(
    engine: ref.watch(pluginEngineProvider),
    handler: ref.watch(pluginFetchHandlerProvider),
    gate: ref.watch(pluginServicesProvider).runGate,
    pauses: ref.watch(pluginPausesProvider),
    streamAdmission: ref.watch(streamRunAdmissionProvider),
    streamHandler: ref.watch(pluginStreamHandlerProvider),
    rows: ref.watch(pluginRowsProvider),
    files: ref.watch(pluginFilesProvider),
    config: ref.watch(pluginConfigStoreProvider),
    storage: ref.watch(pluginStorageStoreProvider),
    recorder: RunLogRecorder(
      log: ref.watch(pluginRunLogProvider),
      rows: ref.watch(pluginRowsProvider),
      config: ref.watch(pluginConfigStoreProvider),
      storage: ref.watch(pluginStorageStoreProvider),
    ),
  ),
);
