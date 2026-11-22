import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/package/plugin_kind.dart';

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

/// The search text and filters of the store list. An empty set means "all".
class StoreFilter {
  const StoreFilter({
    this.query = '',
    this.kinds = const {},
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

  bool get isEmpty =>
      query.trim().isEmpty &&
      kinds.isEmpty &&
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

  /// A route preset (the list of one kind) sets [StoreFilter.kinds] this way.
  void set(StoreFilter filter) => state = filter;

  void clear() => state = const StoreFilter();
}

final storeFilterProvider = NotifierProvider<StoreFilterNotifier, StoreFilter>(
  StoreFilterNotifier.new,
);
