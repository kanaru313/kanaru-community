import 'package:material_ui/material_ui.dart';

/// One criterion the "Sắp xếp theo" box can offer.
class KSortOption<T> {
  const KSortOption({
    required this.value,
    required this.label,
    required this.ascendingLabel,
    required this.descendingLabel,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// Words for each direction of this criterion ("A → Z", "Cũ trước").
  final String ascendingLabel;
  final String descendingLabel;
}

/// One chosen criterion and its own direction.
class KSortEntry<T> {
  const KSortEntry({required this.value, required this.descending});

  final T value;
  final bool descending;

  @override
  bool operator ==(Object other) =>
      other is KSortEntry<T> &&
      other.value == value &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(value, descending);
}

/// Every text of the box, from the app's localizations.
class KSortDialogStrings {
  const KSortDialogStrings({
    required this.title,
    required this.chosen,
    required this.notChosen,
    required this.reset,
    required this.done,
    required this.dragHint,
    required this.flipTooltip,
    required this.flipSemantics,
    required this.remove,
    required this.add,
  });

  final String title;
  final String chosen;
  final String notChosen;
  final String reset;
  final String done;

  /// Label of a row's drag handle, from the criterion name.
  final String Function(String label) dragHint;

  /// Tooltip of the direction button: [word] is the direction it switches to.
  final String Function(String word) flipTooltip;

  /// Spoken label of the direction button: [word] is the current direction.
  final String Function(String label, String word) flipSemantics;
  final String Function(String label) remove;
  final String Function(String label) add;
}
