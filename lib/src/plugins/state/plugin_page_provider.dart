import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/tables.dart';
import '../data/install/sweep_and_restore.dart';
import '../data/store/plugin_row_types.dart';
import '../domain/package/plugin_kind.dart';
import '../domain/package/plugin_manifest.dart';
import 'alerts_provider.dart';
import 'async_join.dart';
import 'plugin_actions_provider.dart';
import 'plugin_store_providers.dart';
import 'updates_provider.dart';

/// One installed plugin as the page of the plugin shows it.
class PluginPageData {
  const PluginPageData({
    required this.row,
    required this.manifest,
    required this.alerts,
    required this.updating,
    required this.waitingReview,
    required this.missing,
  });

  final PluginRow row;

  /// Null when the stored manifest no longer parses (shown as broken).
  final PluginManifest? manifest;
  final Set<PluginAlert> alerts;
  final bool updating;

  /// An update waits for the user ("Cần xem").
  final bool waitingReview;

  /// What the missing package folder needs; null when it is there.
  final RestoreAction? missing;
}

/// The live plugin [installId]; data null when it is not installed.
final pluginPageProvider = Provider.autoDispose
    .family<AsyncValue<PluginPageData?>, String>((ref, installId) {
      final row = ref.watch(installedPluginProvider(installId));
      final alerts = ref.watch(pluginAlertsProvider);
      if (row.hasError) {
        return asyncFailure(row.error!, row.stackTrace!, 'plugin page');
      }
      if (alerts.hasError) {
        return asyncFailure(alerts.error!, alerts.stackTrace!, 'plugin page');
      }
      if (!row.hasValue || !alerts.hasValue) return const AsyncLoading();
      final installed = row.requireValue;
      if (installed == null) return const AsyncData(null);
      final activity = ref.watch(pluginActivityProvider).value;
      return AsyncData(
        PluginPageData(
          row: installed,
          manifest: ref.watch(pluginRowsProvider).manifestOf(installed),
          alerts: alerts.requireValue.of(installId),
          updating: ref.watch(updatingIdsProvider).contains(installId),
          waitingReview: activity?.needsReview.contains(installId) ?? false,
          missing: activity?.missing[installId],
        ),
      );
    });

/// An installed plugin in a list, with the state the list shows.
class InstalledEntry {
  const InstalledEntry({
    required this.row,
    required this.updating,
    required this.missing,
  });

  final PluginRow row;
  final bool updating;

  /// `download`: "Đang cài lại / cài lại"; `pickFile`: pick the file again.
  final RestoreAction? missing;
}

/// Live plugins grouped by kind, install order within a kind. Restore states
/// ride on each entry; rows of a kind this app does not know are in
/// [unknownKind].
class InstalledByKind {
  const InstalledByKind(this.byKind, this.unknownKind);

  final Map<PluginKind, List<InstalledEntry>> byKind;
  final List<InstalledEntry> unknownKind;

  List<InstalledEntry> of(PluginKind kind) => byKind[kind] ?? const [];
}

final installedByKindProvider = Provider<AsyncValue<InstalledByKind>>((ref) {
  final activity = ref.watch(pluginActivityProvider).value;
  return ref.watch(installedPluginsProvider).whenData((rows) {
    final byKind = <PluginKind, List<InstalledEntry>>{};
    final unknown = <InstalledEntry>[];
    for (final row in rows) {
      final entry = InstalledEntry(
        row: row,
        updating: activity?.updating.contains(row.installId) ?? false,
        missing: activity?.missing[row.installId],
      );
      final kind = row.pluginKind;
      kind == null ? unknown.add(entry) : (byKind[kind] ??= []).add(entry);
    }
    return InstalledByKind(byKind, unknown);
  });
});
