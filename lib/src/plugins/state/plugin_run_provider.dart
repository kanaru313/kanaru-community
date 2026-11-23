import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/run/fetch_handler.dart';
import '../data/run/plugin_pauses.dart';
import '../data/run/plugin_runner.dart';
import '../data/run/rust_plugin_engine.dart';
import '../domain/run/plugin_engine.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';

/// The plugin runtime. Tests override it with a fake.
final pluginEngineProvider = Provider<PluginEngine>(
  (ref) => const RustPluginEngine(),
);

/// The host `fetch` of a run. Refuses everything until the real handler is
/// wired in; tests override it.
final pluginFetchHandlerProvider = Provider<PluginFetchHandler>(
  (ref) => const BlockAllFetchHandler(),
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
    rows: ref.watch(pluginRowsProvider),
    files: ref.watch(pluginFilesProvider),
    config: ref.watch(pluginConfigStoreProvider),
  ),
);
