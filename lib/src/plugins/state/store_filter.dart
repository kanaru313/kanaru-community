import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/package/plugin_kind.dart';
import '../domain/search/store_search.dart';

/// Where a store entry stands against the installed plugins.
enum StoreItemState {
  notInstalled,
  installed,
  updateAvailable,

  /// A streaming plugin the Free rule would refuse (another one is
  /// installed).
  locked,

  /// The entry needs a newer app.
  needsNewerApp,
}

/// The values of Lọc › Trạng thái, each a set of [StoreItemState]s. They
/// overlap on purpose: "Đã cài" holds every installed plugin, one with an
/// update included.
enum StoreStateChip {
  installed({StoreItemState.installed, StoreItemState.updateAvailable}),
  notInstalled({
    StoreItemState.notInstalled,
    StoreItemState.locked,
    StoreItemState.needsNewerApp,
  }),
  updatable({StoreItemState.updateAvailable});

  const StoreStateChip(this.states);

  final Set<StoreItemState> states;

  bool matches(StoreItemState state) => states.contains(state);
}

/// Kinds that only restyle the app (seekbar styles; covers later). The store
/// lists them under Chưa cài only when asked for.
const cosmeticPluginKinds = {PluginKind.seekbar};

/// The kinds Lọc › Loại has selected before the user touches it: every
/// functional kind (every kind but [cosmeticPluginKinds]).
const defaultStoreKinds = {
  PluginKind.lyrics,
  PluginKind.translate,
  PluginKind.aiTranslate,
  PluginKind.streaming,
  PluginKind.aiChat,
};

/// The search text and filters of the store list. [kinds] starts as
/// [defaultStoreKinds]; the other sets mean "all" while empty.
class StoreFilter {
  const StoreFilter({
    this.query = '',
    this.kinds = defaultStoreKinds,
    this.states = const {},
    this.languages = const {},
    this.authors = const {},
    this.repoIds = const {},
  });

  final String query;
  final Set<PluginKind> kinds;
  final Set<StoreStateChip> states;

  /// Normalized language keys; a global plugin matches any of them.
  final Set<String> languages;
  final Set<String> authors;
  final Set<int> repoIds;

  /// Nothing differs from the filter the store opens with.
  bool get isEmpty =>
      query.trim().isEmpty &&
      setEquals(kinds, defaultStoreKinds) &&
      states.isEmpty &&
      languages.isEmpty &&
      authors.isEmpty &&
      repoIds.isEmpty;

  StoreFilter copyWith({
    String? query,
    Set<PluginKind>? kinds,
    Set<StoreStateChip>? states,
    Set<String>? languages,
    Set<String>? authors,
    Set<int>? repoIds,
  }) => StoreFilter(
    query: query ?? this.query,
    kinds: kinds ?? this.kinds,
    states: states ?? this.states,
    languages: languages ?? this.languages,
    authors: authors ?? this.authors,
    repoIds: repoIds ?? this.repoIds,
  );
}

class StoreFilterNotifier extends Notifier<StoreFilter> {
  @override
  StoreFilter build() => const StoreFilter();

  /// Replaces the whole filter (a route opens the store with its search text).
  void set(StoreFilter filter) => state = filter;

  /// Back to the filter the store opens with (default Loại chips, no search).
  void clear() => state = const StoreFilter();
}

final storeFilterProvider = NotifierProvider<StoreFilterNotifier, StoreFilter>(
  StoreFilterNotifier.new,
);

/// Whether the store lists an entry of [kind] under [filter]. A functional
/// kind is listed while its chip is selected. A cosmetic kind is also listed
/// when a `#tag` names it or when [installed] (only its uninstalled plugins
/// are hidden by default). A `#tag` then narrows to the kinds it names. A
/// plugin of a kind this app does not know ([kind] null) shows while the
/// Loại chips are untouched and no tag is typed.
bool storeKindVisible({
  required PluginKind? kind,
  required bool installed,
  required StoreFilter filter,
}) {
  final tags = parseStoreSearch(filter.query).kinds;
  if (kind == null) {
    return tags.isEmpty && setEquals(filter.kinds, defaultStoreKinds);
  }
  final asked = tags.contains(kind);
  final listed =
      filter.kinds.contains(kind) ||
      (cosmeticPluginKinds.contains(kind) && (asked || installed));
  return listed && (tags.isEmpty || asked);
}
