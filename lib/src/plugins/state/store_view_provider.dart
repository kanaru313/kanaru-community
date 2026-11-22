import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/text/text_fold.dart';
import '../../database/tables.dart';
import '../data/install/update_candidates.dart';
import '../domain/search/store_search.dart';
import '../data/store/plugin_row_types.dart';
import 'alerts_provider.dart';
import 'async_join.dart';
import 'plugin_store_providers.dart';
import 'store_items_provider.dart';
import 'store_view_models.dart';
import 'updates_provider.dart';

export 'store_view_models.dart';

/// The store list as the page draws it: [storeSectionsProvider] plus the
/// installed plugins that have no catalog entry (installed from a file or a
/// link, or whose repository no longer lists them), filtered the same way.
final storeViewProvider = Provider<AsyncValue<StoreView>>((ref) {
  final filter = ref.watch(storeFilterProvider);
  final sections = ref.watch(storeSectionsProvider);
  final live = ref.watch(installedPluginsProvider);
  final repos = ref.watch(pluginReposProvider);
  final joined = joinAsync(sections, live, (s, l) => (s, l));
  if (!joined.hasValue) {
    return joined.hasError
        ? AsyncError(joined.error!, joined.stackTrace!)
        : const AsyncLoading();
  }
  final (shown, rows) = joined.requireValue;
  final alerts =
      ref.watch(pluginAlertsProvider).value ?? const PluginAlerts({});
  final updates = ref.watch(updatesProvider).value;
  final reviewIds = {
    for (final u in updates?.needsReview ?? const <PluginUpdate>[])
      u.row.installId,
  };
  final manifests = ref.watch(pluginRowsProvider);
  final repoRows = repos.value ?? const [];
  // Every installed plugin with a catalog entry, whatever the filter hides.
  final known = {
    for (final item
        in ref.watch(storeItemsProvider).value ?? const <StoreItem>[])
      item.installId,
  };

  StoreRowView fromItem(StoreItem item) {
    final row = item.installed;
    return StoreRowView(
      installId: item.installId,
      name: row?.name ?? item.entry.name,
      author: (row?.author ?? item.entry.author).trim(),
      kind: row?.pluginKind ?? item.entry.kind,
      state: item.state,
      alerted: alerts.of(item.installId).isNotEmpty,
      needsReview: reviewIds.contains(item.installId),
    );
  }

  final extras = <StoreRowView>[];
  for (final row in rows) {
    if (known.contains(row.installId)) continue;
    final manifest = manifests.manifestOf(row);
    final matches = _extraMatches(
      row: row,
      hosts: manifest?.hosts ?? const [],
      languages: manifest?.languages ?? const [],
      repoUrls: {
        for (final repo in repoRows)
          if (filter.repoIds.contains(repo.id)) repo.url,
      },
      filter: filter,
    );
    if (!matches) continue;
    extras.add(
      StoreRowView(
        installId: row.installId,
        name: row.name,
        author: (row.author ?? '').trim(),
        kind: row.pluginKind,
        state: StoreItemState.installed,
        alerted: alerts.of(row.installId).isNotEmpty,
      ),
    );
  }
  int byName(StoreRowView a, StoreRowView b) {
    final c = foldDiacritics(a.name).compareTo(foldDiacritics(b.name));
    return c != 0 ? c : a.installId.compareTo(b.installId);
  }

  final installed = [...shown.installed.map(fromItem), ...extras]..sort(byName);
  // An entry that needs a newer app has no row: the footer counts it.
  final newerApp = [
    for (final item in shown.notInstalled)
      if (item.state == StoreItemState.needsNewerApp) item,
  ];
  final notInstalled = [
    for (final item in shown.notInstalled)
      if (item.state != StoreItemState.needsNewerApp) fromItem(item),
  ];
  return AsyncData(
    StoreView(
      updates: shown.updates.map(fromItem).toList(),
      installed: installed,
      notInstalled: notInstalled,
      updateAllCount: updates?.updateAllCount ?? 0,
      needsNewerAppCount: newerApp.length,
      repoCount: repoRows.length,
      installedCount: rows.length,
    ),
  );
});

/// The store's own filter applied to an installed plugin that has no catalog
/// entry: such a plugin is installed, has no repository entry and goes by its
/// manifest for hosts and languages.
bool _extraMatches({
  required PluginRow row,
  required List<String> hosts,
  required List<String> languages,
  required Set<String> repoUrls,
  required StoreFilter filter,
}) {
  final kind = row.pluginKind;
  if (filter.kinds.isNotEmpty &&
      (kind == null || !filter.kinds.contains(kind))) {
    return false;
  }
  if (filter.states.isNotEmpty &&
      !filter.states.any((chip) => chip.matches(StoreItemState.installed))) {
    return false;
  }
  final author = (row.author ?? '').trim();
  if (filter.authors.isNotEmpty && !filter.authors.contains(author)) {
    return false;
  }
  if (filter.repoIds.isNotEmpty && !repoUrls.contains(row.repoUrl)) {
    return false;
  }
  if (filter.languages.isNotEmpty &&
      languages.isNotEmpty &&
      !languages.any(filter.languages.contains)) {
    return false;
  }
  final search = parseStoreSearch(filter.query);
  final tagKinds = search.kinds;
  if (tagKinds.isNotEmpty && (kind == null || !tagKinds.contains(kind))) {
    return false;
  }
  final words = [for (final w in search.words) foldDiacritics(w)];
  if (words.isEmpty) return true;
  final haystack = foldDiacritics([row.name, author, ...hosts].join('\n'));
  return words.every(haystack.contains);
}

/// Languages and authors the filter sheet lists: those of the catalogs and of
/// the installed plugins, each once.
final storeFacetsProvider = Provider<StoreFacets>((ref) {
  final languages = <String>{};
  final authors = <String>{};
  for (final item
      in ref.watch(storeItemsProvider).value ?? const <StoreItem>[]) {
    languages.addAll(item.entry.languages);
    if (item.entry.author.trim().isNotEmpty) {
      authors.add(item.entry.author.trim());
    }
  }
  final rows = ref.watch(pluginRowsProvider);
  for (final row
      in ref.watch(installedPluginsProvider).value ?? const <PluginRow>[]) {
    final author = (row.author ?? '').trim();
    if (author.isNotEmpty) authors.add(author);
    languages.addAll(rows.manifestOf(row)?.languages ?? const []);
  }
  return StoreFacets(
    languages: languages.toList()..sort(),
    authors: authors.toList()
      ..sort((a, b) => foldDiacritics(a).compareTo(foldDiacritics(b))),
  );
});
