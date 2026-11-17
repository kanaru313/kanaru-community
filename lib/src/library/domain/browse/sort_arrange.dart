import 'list_sort.dart';
import 'sort_order.dart';

/// Orders items that are already in ascending name order ([byName]) by [sort].
///
/// Each spec is one comparison and the next one breaks its ties. Title
/// compares the rank of the folded name ([nameKey]; equal keys share a rank,
/// so a later criterion still applies), with the spec's direction; every other
/// criterion comes from [compareFor], which returns the comparison of two
/// items for that spec (direction applied, missing values last) and is
/// called once per spec, not per comparison. Items equal on every spec keep
/// name order (their position in [byName]) whatever the directions.
List<T> arrangeByName<T>(
  List<T> byName,
  SortOrder sort,
  String Function(T item) nameKey,
  int Function(T a, T b) Function(SortSpec spec) compareFor,
) {
  final first = sort.primary;
  if (sort.specs.length == 1 && first.criterion == SortCriterion.title) {
    return first.descending ? byName.reversed.toList() : byName;
  }
  final indexed = [for (var i = 0; i < byName.length; i++) (i, byName[i])];
  // Dense rank by name key; [byName] is already ordered by name.
  final rank = List<int>.filled(byName.length, 0);
  for (var i = 1; i < byName.length; i++) {
    rank[i] =
        rank[i - 1] + (nameKey(byName[i]) == nameKey(byName[i - 1]) ? 0 : 1);
  }
  final steps = <int Function((int, T) a, (int, T) b)>[
    for (final spec in sort.specs)
      if (spec.criterion == SortCriterion.title)
        (a, b) => spec.descending
            ? rank[b.$1].compareTo(rank[a.$1])
            : rank[a.$1].compareTo(rank[b.$1])
      else
        _onItems(compareFor(spec)),
  ];
  indexed.sort((a, b) {
    for (final step in steps) {
      final c = step(a, b);
      if (c != 0) return c;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

int Function((int, T), (int, T)) _onItems<T>(int Function(T, T) compare) =>
    (a, b) => compare(a.$2, b.$2);
