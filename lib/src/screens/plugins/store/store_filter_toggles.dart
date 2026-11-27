import '../../../plugins/state/store_filter.dart';
import '../common/plugin_labels.dart';

/// Reads and edits the filter values the Lọc sheet shows, one chip at a time.
extension StoreFilterToggles on StoreFilter {
  bool hasKind(StoreKindGroup group) => kinds.any(group.kinds.contains);

  /// A kind chip that is not as the store opens it (functional kinds on,
  /// cosmetic kinds off).
  bool _kindDiffers(StoreKindGroup group) => hasKind(group) == group.isCosmetic;

  bool hasState(StoreStateChip chip) => states.contains(chip);

  /// How many values differ from the default filter (a kind group counts
  /// once): the badge.
  int get valueCount =>
      StoreKindGroup.values.where(_kindDiffers).length +
      StoreStateChip.values.where(hasState).length +
      languages.length +
      authors.length +
      repoIds.length;

  StoreFilter toggleKind(StoreKindGroup group) => copyWith(
    kinds: hasKind(group)
        ? ({...kinds}..removeAll(group.kinds))
        : {...kinds, ...group.kinds},
  );

  StoreFilter toggleState(StoreStateChip chip) =>
      copyWith(states: _flip(states, chip));

  StoreFilter toggleLanguage(String key) =>
      copyWith(languages: _flip(languages, key));

  StoreFilter toggleAuthor(String author) =>
      copyWith(authors: _flip(authors, author));

  StoreFilter toggleRepo(int id) => copyWith(repoIds: _flip(repoIds, id));

  /// Every value cleared; the search text stays.
  StoreFilter get withoutValues => StoreFilter(query: query);
}

Set<T> _flip<T>(Set<T> set, T value) =>
    set.contains(value) ? ({...set}..remove(value)) : {...set, value};
