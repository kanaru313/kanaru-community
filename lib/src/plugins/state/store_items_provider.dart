import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/tables.dart';
import '../../foundation/text/text_fold.dart';
import '../data/install/update_candidates.dart';
import '../data/repos/catalog_cache.dart';
import '../data/store/plugin_row_types.dart';
import '../domain/catalog/catalog.dart';
import '../domain/install/free_rule.dart';
import '../domain/install/install_id.dart';
import '../domain/search/store_search.dart';
import 'async_join.dart';
import 'plugin_actions_provider.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';
import 'store_filter.dart';

export 'store_filter.dart';

/// One catalog entry with what is known about it locally.
class StoreItem {
  const StoreItem({
    required this.repo,
    required this.entry,
    required this.installId,
    required this.state,
    this.installed,
  });

  final PluginRepoRow repo;
  final CatalogEntry entry;
  final String installId;
  final StoreItemState state;

  /// The live plugin installed from this entry, if any.
  final PluginRow? installed;
}

/// The list the store shows: updates first, then installed, then the rest.
class StoreSections {
  const StoreSections({
    required this.updates,
    required this.installed,
    required this.notInstalled,
  });

  /// An updatable plugin is listed here only, never under [installed].
  final List<StoreItem> updates;
  final List<StoreItem> installed;
  final List<StoreItem> notInstalled;

  int get length => updates.length + installed.length + notInstalled.length;
  bool get isEmpty => length == 0;
}

/// Every entry of every repository against the installed plugins (no filter).
final storeItemsProvider = Provider<AsyncValue<List<StoreItem>>>((ref) {
  final catalogs = ref.watch(pluginServicesProvider).catalogs;
  final unlocked = ref.watch(pluginStreamingUnlockedProvider);
  final missing =
      ref.watch(pluginActivityProvider).value?.missing.keys.toSet() ??
      const <String>{};
  return joinAsync(
    ref.watch(pluginReposProvider),
    ref.watch(installedPluginsProvider),
    (repos, live) => buildStoreItems(repos, live, catalogs, unlocked, missing),
  );
});

/// Pure core of [storeItemsProvider].
List<StoreItem> buildStoreItems(
  List<PluginRepoRow> repos,
  List<PluginRow> live,
  CatalogCache catalogs,
  bool unlocked,
  Set<String> missingIds,
) {
  final byId = {for (final row in live) row.installId: row};
  final streaming = [
    for (final row in live)
      if (row.pluginKind == PluginKind.streaming) row.installId,
  ];
  final locked = lockedStreamingIds(
    unlocked: unlocked,
    liveStreamingIds: streaming,
    missingIds: missingIds,
  );
  return [
    for (final repo in repos)
      for (final entry
          in catalogs.catalogOf(repo)?.entries ?? const <CatalogEntry>[])
        () {
          final id = repoInstallId(repo.url, entry.slug);
          final row = byId[id];
          // The same test as the updates count: a newer entry of a kind the
          // app would refuse is no update.
          final update = row == null
              ? null
              : resolveUpdate(row, repo, catalogs).update;
          final state = row != null
              ? (update != null && !update.kindRefused && !locked.contains(id)
                    ? StoreItemState.updateAvailable
                    : StoreItemState.installed)
              : entry.needsNewerApp
              ? StoreItemState.needsNewerApp
              : entry.kind == PluginKind.streaming &&
                    !streamingInstallAllowed(
                      unlocked: unlocked,
                      installId: id,
                      liveStreamingIds: streaming,
                      missingIds: missingIds,
                    )
              ? StoreItemState.locked
              : StoreItemState.notInstalled;
          return StoreItem(
            repo: repo,
            entry: entry,
            installId: id,
            state: state,
            installed: row,
          );
        }(),
  ];
}

/// Whether [item] passes [filter]: the search folds case and diacritics over
/// name, author, repository name and hosts; every word must be found.
bool storeItemMatches(StoreItem item, StoreFilter filter) {
  final entry = item.entry;
  // An entry that needs a newer app has no row, only the footer count: the
  // default hiding of cosmetic kinds does not apply to it (explicit Loại
  // chips and `#tag` still do).
  final installed =
      item.state == StoreItemState.installed ||
      item.state == StoreItemState.updateAvailable;
  if (!storeKindVisible(
    kind: entry.kind,
    installed: installed || item.state == StoreItemState.needsNewerApp,
    filter: filter,
  )) {
    return false;
  }
  final search = parseStoreSearch(filter.query);
  if (filter.states.isNotEmpty &&
      !filter.states.any((chip) => chip.matches(item.state))) {
    return false;
  }
  if (filter.authors.isNotEmpty && !filter.authors.contains(entry.author)) {
    return false;
  }
  if (filter.repoIds.isNotEmpty && !filter.repoIds.contains(item.repo.id)) {
    return false;
  }
  if (filter.languages.isNotEmpty &&
      entry.languages.isNotEmpty &&
      !entry.languages.any(filter.languages.contains)) {
    return false;
  }
  final words = [for (final w in search.words) foldDiacritics(w)];
  if (words.isEmpty) return true;
  final haystack = foldDiacritics(
    [entry.name, entry.author, item.repo.name, ...entry.hosts].join('\n'),
  );
  return words.every(haystack.contains);
}

/// [storeItemsProvider] filtered by [storeFilterProvider], in the sections
/// Cập nhật / Đã cài / Chưa cài, each sorted by folded name.
final storeSectionsProvider = Provider<AsyncValue<StoreSections>>((ref) {
  final filter = ref.watch(storeFilterProvider);
  return ref.watch(storeItemsProvider).whenData((items) {
    final shown = [
      for (final item in items)
        if (storeItemMatches(item, filter)) item,
    ]..sort(_byName);
    List<StoreItem> pick(bool Function(StoreItemState) test) => [
      for (final item in shown)
        if (test(item.state)) item,
    ];
    return StoreSections(
      updates: pick((s) => s == StoreItemState.updateAvailable),
      installed: pick((s) => s == StoreItemState.installed),
      notInstalled: pick(
        (s) =>
            s == StoreItemState.notInstalled ||
            s == StoreItemState.locked ||
            s == StoreItemState.needsNewerApp,
      ),
    );
  });
});

int _byName(StoreItem a, StoreItem b) {
  final byName = foldDiacritics(a.entry.name)
      .compareTo(foldDiacritics(b.entry.name));
  return byName != 0 ? byName : a.installId.compareTo(b.installId);
}
