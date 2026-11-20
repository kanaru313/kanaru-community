/// What changed in the play log since the last emission: plays came in
/// ([inserted]) and/or went out ([removed]). An undo revives plays in any
/// year, so it reports both.
class HistoryChange {
  const HistoryChange({this.inserted = false, this.removed = false});

  final bool inserted;
  final bool removed;

  /// The changes of both, for several events folded into one.
  HistoryChange merge(HistoryChange other) => HistoryChange(
    inserted: inserted || other.inserted,
    removed: removed || other.removed,
  );

  @override
  bool operator ==(Object other) =>
      other is HistoryChange &&
      other.inserted == inserted &&
      other.removed == removed;

  @override
  int get hashCode => Object.hash(inserted, removed);

  @override
  String toString() => 'HistoryChange(inserted: $inserted, removed: $removed)';
}
