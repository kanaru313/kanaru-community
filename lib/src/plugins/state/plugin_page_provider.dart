import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/tables.dart';
import '../data/install/sweep_and_restore.dart';
import '../data/store/plugin_row_types.dart';
import '../domain/config/config_field.dart';
import '../domain/package/plugin_kind.dart';
import '../domain/package/plugin_manifest.dart';
import 'alerts_provider.dart';
import 'async_join.dart';
import 'plugin_actions_provider.dart';
import 'plugin_store_providers.dart';
import 'updates_provider.dart';

// Screens read the origin type through this file, never from `plugins/data`.
export '../data/store/plugin_row_types.dart' show PluginOrigin;

/// The newer version the repository lists for the plugin of the page.
class PluginPageUpdate {
  const PluginPageUpdate({
    required this.version,
    required this.needsReview,
    required this.newHosts,
    required this.repoId,
  });

  final int version;

  /// The new version adds hosts or permissions: the user looks first.
  final bool needsReview;

  /// The hosts the catalog says the new version adds (may be empty when only
  /// the downloaded package showed them).
  final List<String> newHosts;
  final int repoId;
}

/// A field the user types a web address into, with the hosts typed so far.
class PageEndpoint {
  const PageEndpoint({required this.label, required this.hosts});

  final String label;

  /// Host names of the addresses entered; empty when none is entered.
  final List<String> hosts;
}

/// One installed plugin as the page of the plugin shows it.
class PluginPageData {
  const PluginPageData({
    required this.row,
    required this.manifest,
    required this.alerts,
    required this.updating,
    required this.waitingReview,
    required this.missing,
    this.update,
    this.endpoints = const [],
    this.missingConfig = const [],
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

  /// A newer version in the repository; null for a file or link install, a
  /// removed repository or when there is none.
  final PluginPageUpdate? update;

  /// One entry per address field of the manifest.
  final List<PageEndpoint> endpoints;

  /// Titles of the required settings that have no value.
  final List<String> missingConfig;

  /// Null for a kind this app does not know.
  PluginKind? get kind => row.pluginKind;

  /// Where the package came from; null for a row that names no known origin.
  PluginOrigin? get origin => row.originKind;

  /// The repository address (repository install) or the file name / link.
  String? get originLabel => row.repoUrl ?? row.originLabel;

  /// The hosts the user agreed to.
  List<String> get consentedHosts => row.consentedHosts;
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
      final config = ref.watch(pluginConfigStatusProvider(installId)).value;
      final manifest = ref.watch(pluginRowsProvider).manifestOf(installed);
      final updates = ref.watch(updatesProvider).value;
      final candidate = [
        ...?updates?.needsReview,
        ...?updates?.silent,
      ].where((u) => u.row.installId == installId).firstOrNull;
      return AsyncData(
        PluginPageData(
          row: installed,
          manifest: manifest,
          update: candidate == null
              ? null
              : PluginPageUpdate(
                  version: candidate.entry.version,
                  needsReview:
                      candidate.needsReview ||
                      (activity?.needsReview.contains(installId) ?? false),
                  newHosts: candidate.diff.newHosts,
                  repoId: candidate.repo.id,
                ),
          endpoints: [
            for (final field
                in manifest?.userEndpointFields ?? const <ConfigField>[])
              PageEndpoint(
                label: field.title.isEmpty ? field.key : field.title,
                hosts: _hostsOf(config?.data.values[field.key]),
              ),
          ],
          missingConfig: [
            for (final field
                in config?.missingRequired ?? const <ConfigField>[])
              field.title.isEmpty ? field.key : field.title,
          ],
          alerts: alerts.requireValue.of(installId),
          updating: ref.watch(updatingIdsProvider).contains(installId),
          waitingReview: activity?.needsReview.contains(installId) ?? false,
          missing: activity?.missing[installId],
        ),
      );
    });

/// Host names of the address, or of each address of a list; entries that do
/// not parse are left out.
List<String> _hostsOf(Object? value) {
  final texts = switch (value) {
    final String text => [text],
    final List<Object?> list => list.whereType<String>(),
    _ => const <String>[],
  };
  return [
    for (final text in texts)
      if (Uri.tryParse(text.trim())?.host case final host? when host.isNotEmpty)
        host,
  ];
}

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
