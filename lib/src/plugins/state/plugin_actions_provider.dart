import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extension/domain/license.dart';
import '../../extension/state/extension_providers.dart';
import '../data/install/plugin_actions.dart';
import '../data/install/plugin_activity.dart';
import '../data/install/restore_reinstall.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';

/// The Pro feature that lifts the Free one-music-source rule.
const multiStreamingFeature = ProFeature('plugins.multi-streaming');

/// Whether more than one streaming plugin may work, for the screens. It
/// follows `licenseServiceProvider` (and is rebuilt only when that changes);
/// the services do not use it, they ask the license at every check.
final pluginStreamingUnlockedProvider = Provider<bool>(
  (ref) =>
      ref.watch(licenseServiceProvider).statusOf(multiStreamingFeature) ==
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
    held: services.held,
    catalogs: services.catalogs,
    // Asked at every check, never cached, so a change of license applies at
    // once.
    streamingUnlocked: () =>
        ref.read(licenseServiceProvider).statusOf(multiStreamingFeature) ==
        LicenseStatus.granted,
    startupRestore: services.startupRestore,
    findMissing: services.findMissingPackages,
  );
  ref.onDispose(actions.activity.dispose);
  return actions;
});

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
