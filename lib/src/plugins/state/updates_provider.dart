import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/install/plugin_activity.dart';
import '../data/install/update_candidates.dart';
import '../data/store/plugin_row_types.dart';
import '../domain/install/free_rule.dart';
import '../domain/package/plugin_kind.dart';
import 'async_join.dart';
import 'plugin_actions_provider.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';

/// The updates the catalogs offer for the installed repository plugins.
class PluginUpdates {
  const PluginUpdates({required this.silent, required this.needsReview});

  /// Updates "Cập nhật tất cả" installs without asking.
  final List<PluginUpdate> silent;

  /// Updates that wait for the user: the catalog lists hosts they did not
  /// agree to, or a download turned out to add some.
  final List<PluginUpdate> needsReview;

  /// Every plugin with a newer version (the badge count).
  int get count => silent.length + needsReview.length;

  /// What "Cập nhật tất cả (n)" will update.
  int get updateAllCount => silent.length;
}

/// The plugins with a newer version. A kind change the app would refuse is
/// not counted as an update.
final updatesProvider = Provider<AsyncValue<PluginUpdates>>((ref) {
  final catalogs = ref.watch(pluginServicesProvider).catalogs;
  final unlocked = ref.watch(pluginStreamingUnlockedProvider);
  final missing =
      ref.watch(pluginActivityProvider).value?.missing.keys.toSet() ??
      const <String>{};
  final flagged =
      ref.watch(pluginActivityProvider).value?.needsReview ?? const <String>{};
  return joinAsync(
    ref.watch(installedPluginsProvider),
    ref.watch(pluginReposProvider),
    (live, repos) {
      final locked = lockedStreamingIds(
        unlocked: unlocked,
        liveStreamingIds: [
          for (final row in live)
            if (row.pluginKind == PluginKind.streaming) row.installId,
        ],
        missingIds: missing,
      );
      final updates = findUpdates(
        live: live,
        repos: repos,
        catalogs: catalogs,
        lockedIds: locked,
      )..removeWhere((u) => u.kindRefused);
      return PluginUpdates(
        silent: [
          for (final u in updates)
            if (!u.needsReview && !flagged.contains(u.row.installId)) u,
        ],
        needsReview: [
          for (final u in updates)
            if (u.needsReview || flagged.contains(u.row.installId)) u,
        ],
      );
    },
  );
});

/// Plugins being installed, updated or repaired right now.
final updatingIdsProvider = Provider<Set<String>>(
  (ref) =>
      ref.watch(pluginActivityProvider).value?.updating ?? const <String>{},
);

/// The progress and result of the "update all" run.
final updateAllStateProvider = Provider<UpdateAllState>(
  (ref) =>
      ref.watch(pluginActivityProvider).value?.updateAll ??
      const UpdateAllState(),
);
