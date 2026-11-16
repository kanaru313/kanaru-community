import 'package:material_ui/material_ui.dart';

/// One sort criterion offered by [showKSortPopover].
class KSortCriterion<T> {
  const KSortCriterion({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// What the sort dropdown resolves to; null when it was dismissed.
sealed class KSortPick<T> {
  const KSortPick();
}

/// A criterion row was chosen.
final class KSortPicked<T> extends KSortPick<T> {
  const KSortPicked(this.value);

  final T value;
}

/// The "Nâng cao…" row was chosen: the caller opens `showKSortDialog`.
final class KSortAdvanced<T> extends KSortPick<T> {
  const KSortAdvanced();
}
