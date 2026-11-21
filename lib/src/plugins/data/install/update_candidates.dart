import '../../../database/tables.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/install/install_result.dart';
import '../../domain/install/update_diff.dart';
import '../repos/catalog_cache.dart';
import '../store/plugin_row_types.dart';

/// A newer version of an installed repository plugin, read from the catalog
/// (nothing is downloaded to know it).
class PluginUpdate {
  const PluginUpdate({
    required this.row,
    required this.repo,
    required this.entry,
    required this.diff,
  });

  final PluginRow row;
  final PluginRepoRow repo;
  final CatalogEntry entry;

  /// What the entry says it changes (hosts, kind). The zip is authoritative
  /// once downloaded.
  final UpdateDiff diff;

  /// The entry lists hosts the user has not agreed to: "Cần xem".
  bool get needsReview => diff.needsReview;

  /// The entry is another kind of plugin: the update would be refused.
  bool get kindRefused => diff.kindChange == KindChange.refused;
}

/// Whether [row] has an update in [repo] (null when its repository was
/// removed), or the reason it has none: the plugin is not from a repository,
/// the repository is gone or no longer lists it, the entry needs a newer app,
/// or the entry is not newer.
({PluginUpdate? update, InstallFailure? failure}) resolveUpdate(
  PluginRow row,
  PluginRepoRow? repo,
  CatalogCache catalogs,
) {
  if (row.originKind != PluginOrigin.repo || row.repoSlug == null) {
    return (update: null, failure: InstallFailure.otherOrigin);
  }
  if (repo == null) return (update: null, failure: InstallFailure.repoRemoved);
  final entry = catalogs.entryOf(repo, row.repoSlug!);
  if (entry == null) return (update: null, failure: InstallFailure.entryGone);
  final kind = row.pluginKind;
  if (entry.needsNewerApp || kind == null) {
    return (update: null, failure: InstallFailure.needsNewerApp);
  }
  if (entry.version <= row.version) {
    return (update: null, failure: InstallFailure.noNewerVersion);
  }
  return (
    update: PluginUpdate(
      row: row,
      repo: repo,
      entry: entry,
      diff: diffUpdate(
        consentedHosts: row.consentedHosts,
        installedVersion: row.version,
        installedKind: kind,
        candidate: UpdateCandidate.fromEntry(entry),
      ),
    ),
    failure: null,
  );
}

/// Every live repository plugin whose repository still lists a newer version
/// it can install: live + from a repository + repository still added + entry
/// exists + supported API version + newer version. In install order.
List<PluginUpdate> findUpdates({
  required Iterable<PluginRow> live,
  required Iterable<PluginRepoRow> repos,
  required CatalogCache catalogs,
  Set<String> lockedIds = const {},
}) {
  final byUrl = {for (final repo in repos) repo.url: repo};
  return [
    for (final row in live)
      if (row.originKind == PluginOrigin.repo &&
          !lockedIds.contains(row.installId))
        ?resolveUpdate(row, byUrl[row.repoUrl], catalogs).update,
  ];
}
