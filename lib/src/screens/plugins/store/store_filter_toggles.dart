import '../../../plugins/state/store_filter.dart';
import '../common/plugin_labels.dart';

/// The three values of Lọc › Trạng thái. Each is one section of the list:
/// an updatable plugin is "có bản cập nhật" only, not "đã cài".
enum StoreStateChip {
  installed({StoreItemState.installed}),
  notInstalled({
    StoreItemState.notInstalled,
    StoreItemState.locked,
    StoreItemState.needsNewerApp,
  }),
  updatable({StoreItemState.updateAvailable});

  const StoreStateChip(this.states);

  final Set<StoreItemState> states;
}

/// Reads and edits the filter values the Lọc sheet shows, one chip at a time.
extension StoreFilterToggles on StoreFilter {
  bool hasKind(StoreKindGroup group) => kinds.any(group.kinds.contains);

  bool hasState(StoreStateChip chip) => states.any(chip.states.contains);

  /// How many values are chosen (a kind group counts once): the badge.
  int get valueCount =>
      StoreKindGroup.values.where(hasKind).length +
      StoreStateChip.values.where(hasState).length +
      languages.length +
      authors.length +
      repoIds.length;

  StoreFilter toggleKind(StoreKindGroup group) => copyWith(
    kinds: hasKind(group)
        ? ({...kinds}..removeAll(group.kinds))
        : {...kinds, ...group.kinds},
  );

  StoreFilter toggleState(StoreStateChip chip) => copyWith(
    states: hasState(chip)
        ? ({...states}..removeAll(chip.states))
        : {...states, ...chip.states},
  );

  StoreFilter toggleLanguage(String key) =>
      copyWith(languages: _flip(languages, key));

  StoreFilter toggleAuthor(String author) =>
      copyWith(authors: _flip(authors, author));

  StoreFilter toggleRepo(int id) => copyWith(repoIds: _flip(repoIds, id));

  /// Every value cleared; the search text stays.
  StoreFilter get withoutValues => StoreFilter(query: query);

  /// The list of one kind, as a route preset asks for: replaces the kinds and
  /// clears every other value (search included).
  static StoreFilter preset(StoreKindGroup? group) =>
      StoreFilter(kinds: group?.kinds ?? const {});
}

Set<T> _flip<T>(Set<T> set, T value) =>
    set.contains(value) ? ({...set}..remove(value)) : {...set, value};
