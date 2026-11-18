import 'list_sort.dart';

/// An ordered, non-empty list of sort criteria with distinct criteria: the
/// first one orders the list, each next one breaks the ties of those before
/// it. Immutable, with value equality (it is part of provider family keys).
class SortOrder {
  SortOrder(Iterable<SortSpec> specs) : specs = List.unmodifiable(specs) {
    assert(this.specs.isNotEmpty, 'a sort order needs a criterion');
    assert(
      this.specs.map((s) => s.criterion).toSet().length == this.specs.length,
      'criteria must be distinct',
    );
  }

  /// One criterion.
  SortOrder.single(SortSpec spec) : this([spec]);

  /// One criterion in the given direction.
  SortOrder.by(SortCriterion c, {bool descending = false})
    : this([SortSpec(c, descending: descending)]);

  /// Repairs [specs] (e.g. read from storage): drops criteria [offered] does
  /// not contain and repeated ones (first wins); empty falls back to
  /// [fallback].
  factory SortOrder.normalized(
    Iterable<SortSpec> specs,
    List<SortCriterion> offered, {
    required SortOrder fallback,
  }) {
    final seen = <SortCriterion>{};
    final kept = [
      for (final s in specs)
        if (offered.contains(s.criterion) && seen.add(s.criterion)) s,
    ];
    return kept.isEmpty ? fallback : SortOrder(kept);
  }

  final List<SortSpec> specs;

  SortSpec get primary => specs.first;

  /// Criteria after the first one.
  int get extra => specs.length - 1;

  bool contains(SortCriterion c) => specs.any((s) => s.criterion == c);

  /// Dropdown pick: [c] alone, in the direction of the first criterion.
  SortOrder pick(SortCriterion c) =>
      SortOrder.single(SortSpec(c, descending: primary.descending));

  /// Appends [c] (dates newest first). No-op when already present.
  SortOrder add(SortCriterion c) => contains(c)
      ? this
      : SortOrder([...specs, SortSpec(c, descending: c.kind == SortKind.date)]);

  /// Drops [c]; no-op when it is absent or the only one.
  SortOrder remove(SortCriterion c) => specs.length < 2 || !contains(c)
      ? this
      : SortOrder(specs.where((s) => s.criterion != c));

  /// Toggles the direction of [c].
  SortOrder flip(SortCriterion c) => SortOrder([
    for (final s in specs)
      s.criterion == c ? s.withDirection(descending: !s.descending) : s,
  ]);

  /// Every direction toggled.
  SortOrder reversed() => SortOrder([
    for (final s in specs) s.withDirection(descending: !s.descending),
  ]);

  /// Moves the spec at [from] so that it ends at index [to] (its final
  /// position, as `onReorderItem` reports it).
  SortOrder move(int from, int to) {
    RangeError.checkValidIndex(from, specs);
    RangeError.checkValidIndex(to, specs);
    if (from == to) return this;
    final list = [...specs];
    list.insert(to, list.removeAt(from));
    return SortOrder(list);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SortOrder || other.specs.length != specs.length) return false;
    for (var i = 0; i < specs.length; i++) {
      if (specs[i] != other.specs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(specs);

  @override
  String toString() => 'SortOrder($specs)';
}

/// The first criterion of [list], ascending, except where the biggest or
/// newest comes first: songs on a detail page start with the most played,
/// languages with the largest one and playlists with the latest changed.
SortOrder defaultSortOf(BrowseList list) => SortOrder.single(
  SortSpec(
    criteriaOf(list).first,
    descending:
        list == BrowseList.detailSongs ||
        list == BrowseList.languages ||
        list == BrowseList.playlists,
  ),
);
