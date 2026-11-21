import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/install/sweep_and_restore.dart';
import '../data/store/plugin_config_values.dart';
import '../data/store/plugin_row_types.dart';
import '../domain/config/config_required.dart';
import '../domain/install/free_rule.dart';
import 'async_join.dart';
import '../domain/package/plugin_kind.dart';
import 'plugin_actions_provider.dart';
import 'plugin_store_providers.dart';

enum PluginAlert {
  /// A required setting has no value.
  missingRequiredConfig,

  /// The package folder is gone and can be downloaded again.
  packageMissing,

  /// The stored manifest no longer reads.
  broken,

  /// The package folder is gone and only the user can pick the file again.
  reinstallFromFile,

  /// A second streaming plugin without Pro (it is not restored or run).
  proRequired,
}

/// What needs the user's attention, per installed plugin.
class PluginAlerts {
  const PluginAlerts(this.byId);

  final Map<String, Set<PluginAlert>> byId;

  Set<PluginAlert> of(String installId) => byId[installId] ?? const {};

  /// Any plugin needs attention: the red dot on the plugins entry.
  bool get any => byId.isNotEmpty;
}

/// Alerts of every live plugin. A database error is the error state.
final pluginAlertsProvider = Provider<AsyncValue<PluginAlerts>>((ref) {
  final live = ref.watch(installedPluginsProvider);
  if (live.hasError) {
    return asyncFailure(live.error!, live.stackTrace!, 'alerts');
  }
  if (!live.hasValue) return const AsyncLoading();
  final rows = ref.watch(pluginRowsProvider);
  final missing =
      ref.watch(pluginActivityProvider).value?.missing ??
      const <String, RestoreAction>{};
  final unlocked = ref.watch(pluginStreamingUnlockedProvider);
  final byId = <String, Set<PluginAlert>>{};
  final streamingIds = [
    for (final row in live.requireValue)
      if (row.pluginKind == PluginKind.streaming) row.installId,
  ];
  final holder = streamingSlotHolder(streamingIds, missing.keys.toSet());
  for (final row in live.requireValue) {
    final alerts = <PluginAlert>{};
    final manifest = rows.manifestOf(row);
    if (manifest == null || row.pluginKind == null) {
      alerts.add(PluginAlert.broken);
    } else {
      final config = ref.watch(pluginConfigProvider(row.installId));
      if (config.hasError) {
        return asyncFailure(config.error!, config.stackTrace!, 'alerts');
      }
      if (!config.hasValue) return const AsyncLoading();
      if (missingRequiredConfig(
        manifest.config,
        resolveRunConfig(manifest.config, config.requireValue),
      ).isNotEmpty) {
        alerts.add(PluginAlert.missingRequiredConfig);
      }
    }
    switch (missing[row.installId]) {
      case RestoreAction.download:
        alerts.add(PluginAlert.packageMissing);
      case RestoreAction.pickFile:
        alerts.add(PluginAlert.reinstallFromFile);
      case null:
    }
    // The slot rule is the install gate's: the others need Pro.
    if (row.pluginKind == PluginKind.streaming &&
        !unlocked &&
        row.installId != holder) {
      alerts.add(PluginAlert.proRequired);
    }
    if (alerts.isNotEmpty) byId[row.installId] = alerts;
  }
  return AsyncData(PluginAlerts(byId));
});
