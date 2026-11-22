import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../database/tables.dart';
import '../data/repos/catalog_cache.dart';
import '../domain/install/repo_results.dart';
import 'plugin_actions_provider.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';
import 'store_items_provider.dart';
import 'store_view_models.dart';

final _log = Logger('plugin_store_ops');

/// What the store screens do to repositories and what runs when the store
/// opens. Screens read this interface only; tests replace it.
abstract interface class StoreOps {
  /// Runs once per open of the store: refreshes the repositories that are
  /// stale, and retries the plugins whose package was missing. Never throws.
  Future<void> onOpen();

  /// Refreshes every repository. Never throws.
  Future<List<RepoRefreshResult>> refreshAll();

  /// Refreshes one repository; null when it is gone. Never throws.
  Future<RepoRefreshResult?> refresh(int repoId);

  /// Adds the repository at [input]. Never throws.
  Future<RepoAddResult> add(String input);

  /// The repository [repoId] as the list shows it (read from the database, so
  /// it is there right after an add); null when it is gone. Never throws.
  Future<RepoView?> describe(int repoId);

  /// Removes repository [repoId]. Never throws.
  Future<RepoRemoveResult> remove(int repoId);
}

class _ServiceStoreOps implements StoreOps {
  _ServiceStoreOps(this._ref);

  final Ref _ref;

  @override
  Future<void> onOpen() async {
    try {
      final services = _ref.read(pluginServicesProvider);
      await Future.wait([
        services.refresher.refreshStale(),
        _ref.read(pluginActionsProvider).restorer.restoreMissing(),
      ]);
    } on Object catch (error) {
      _log.warning('Store open tasks failed: ${error.runtimeType}');
    }
  }

  @override
  Future<List<RepoRefreshResult>> refreshAll() =>
      _ref.read(pluginServicesProvider).refresher.refreshAll();

  @override
  Future<RepoRefreshResult?> refresh(int repoId) =>
      _ref.read(pluginServicesProvider).refresher.refresh(repoId);

  @override
  Future<RepoAddResult> add(String input) =>
      _ref.read(pluginServicesProvider).repos.add(input);

  @override
  Future<RepoView?> describe(int repoId) async {
    try {
      final row = await _ref.read(pluginRepoRowsProvider).byId(repoId);
      if (row == null) return null;
      return _viewOf(row, _ref.read(pluginServicesProvider).catalogs);
    } on Object catch (error) {
      _log.warning('Reading a repository failed: ${error.runtimeType}');
      return null;
    }
  }

  @override
  Future<RepoRemoveResult> remove(int repoId) =>
      _ref.read(pluginServicesProvider).repos.remove(repoId);
}

final storeOpsProvider = Provider<StoreOps>(_ServiceStoreOps.new);

/// The repositories with the number of plugins each lists.
final repoViewsProvider = Provider<AsyncValue<List<RepoView>>>((ref) {
  final catalogs = ref.watch(pluginServicesProvider).catalogs;
  return ref
      .watch(pluginReposProvider)
      .whenData((rows) => [for (final row in rows) _viewOf(row, catalogs)]);
});

RepoView _viewOf(PluginRepoRow row, CatalogCache catalogs) => RepoView(
  id: row.id,
  name: row.name,
  url: row.url,
  pluginCount: catalogs.catalogOf(row)?.entries.length ?? 0,
  errorKind: row.lastError,
  refreshedAt: row.refreshedAt,
);

/// The icon bytes of a plugin of the store list (installed icon from its
/// package folder, else the catalog icon); null when it has none.
final pluginIconProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, installId) async {
      final icons = ref.watch(pluginServicesProvider).icons;
      final live = ref.watch(installedPluginProvider(installId)).value;
      if (live != null) return icons.installedIcon(live);
      final items = ref.watch(storeItemsProvider).value ?? const <StoreItem>[];
      for (final item in items) {
        if (item.installId == installId) {
          return icons.catalogIcon(item.repo, item.entry);
        }
      }
      return null;
    });
