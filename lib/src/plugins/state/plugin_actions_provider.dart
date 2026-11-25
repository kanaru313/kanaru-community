import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extension/domain/license.dart';
import '../../extension/state/extension_providers.dart';
import '../data/install/plugin_actions.dart';
import '../data/install/plugin_activity.dart';
import '../data/install/restore_reinstall.dart';
import '../data/logs/plugin_log_reader.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';

/// The Pro feature that lifts the Free one-music-source rule.
const multiStreamingFeature = ProFeature('plugins.multi-streaming');

/// Whether more than one streaming plugin may work, for the screens. It
/// follows the license's `changes` through `proFeatureStatusProvider`, so a
/// purchase or an expiry while the app runs updates the screens.
final pluginStreamingUnlockedProvider = Provider<bool>(
  (ref) =>
      ref.watch(proFeatureStatusProvider(multiStreamingFeature)) ==
      LicenseStatus.granted,
);

/// Install, update, update all, repair, restore, remove and config writes,
/// all on the services' write queue.
final pluginActionsProvider = Provider<PluginActions>((ref) {
  final services = ref.watch(pluginServicesProvider);
  final actions = PluginActions(
    queue: services.queue,
    rows: ref.watch(pluginRowsProvider),
    repoRows: ref.watch(pluginRepoRowsProvider),
    files: ref.watch(pluginFilesProvider),
    config: ref.watch(pluginConfigStoreProvider),
    storage: ref.watch(pluginStorageStoreProvider),
    logs: ref.watch(pluginRunLogProvider),
    held: services.held,
    catalogs: services.catalogs,
    runGate: services.runGate,
    // Read at every check; the provider follows the license's `changes`, so a
    // change of license applies to the next check.
    streamingUnlocked: () =>
        ref.read(proFeatureStatusProvider(multiStreamingFeature)) ==
        LicenseStatus.granted,
    startupRestore: services.startupRestore,
    findMissing: services.findMissingPackages,
  );
  ref.onDispose(actions.activity.dispose);
  return actions;
});

/// Reads and clears a plugin's run log (`readLog`, `clearLog`, `logFolder`).
final pluginLogReaderProvider = Provider<PluginLogReader>(
  (ref) => ref.watch(pluginActionsProvider).logReader,
);

/// The startup restore: nothing reads it yet. The shell (phase 9 / app root)
/// must read it once at startup (it reinstalls plugins whose folder is
/// missing, in the background) and call `restorer.restoreMissing()` whenever
/// the store opens, to retry what was offline.
final pluginRestoreProvider = FutureProvider<List<RestoreOutcome>>(
  (ref) => ref.watch(pluginActionsProvider).restorer.restoreAtStartup(),
);

/// What the services are doing: updating ids, update-all progress, plugins
/// waiting for review or missing their folder.
final pluginActivityProvider = StreamProvider<PluginActivitySnapshot>(
  (ref) => ref.watch(pluginActionsProvider).activity.watch(),
);
