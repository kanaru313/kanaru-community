import 'fold_for_match.dart';
import 'multi_selection_parts.dart';
import 'selection_picker.dart';

/// What one entry of the scrolling list of a multi picker is.
enum MultiKind { banner, selectAll, option, divider, action, empty, footer }

class MultiEntry<T> {
  const MultiEntry(this.kind, [this.option]);

  final MultiKind kind;
  final SelectionOption<T>? option;
}

/// Everything a build of the multi picker derives from its inputs, computed
/// once: rows after the filter, enabled values, counted picks and the ordered
/// list entries.
///
/// Entry order: banner, select-all, pinned rows, a divider (only while a
/// pinned row is visible and a row follows), the action row, rows the action
/// added (newest first), options, the empty note, the list footer.
class MultiSelectionView<T> {
  MultiSelectionView({
    required this.pinned,
    required List<SelectionOption<T>> added,
    required this.options,
    required this.chosen,
    required String query,
    required this.action,
    required this.hasBanner,
    required this.hasEmptyNote,
    required this.hasListFooter,
    required this.hasSelectAll,
    this.minSelected = 0,
  }) {
    final known = {
      for (final o in pinned) o.value,
      for (final o in options) o.value,
    };
    addedRows = added.where((o) => !known.contains(o.value)).toList();
    allRows = [...pinned, ...addedRows, ...options];
    enabledValues = {
      for (final o in allRows)
        if (o.enabled) o.value,
    }.toList();
    picks = {
      for (final v in enabledValues)
        if (chosen.contains(v)) v,
    };
    iconRows =
        enabledValues.isNotEmpty &&
        allRows.where((o) => o.enabled).every((o) => o.leading != null);
    showAll = hasSelectAll && enabledValues.length >= 2;

    final match = foldedMatcher(query);
    bool shown(SelectionOption<T> o) =>
        o.filterText == null || match(o.filterText!);
    final visiblePinned = pinned.where(shown).toList();
    final visibleAdded = addedRows.where(shown).toList();
    final visibleOptions = options.where(shown).toList();
    final followsDivider =
        action != null || visibleAdded.isNotEmpty || visibleOptions.isNotEmpty;
    entries = [
      if (hasBanner) const MultiEntry(MultiKind.banner),
      if (showAll) const MultiEntry(MultiKind.selectAll),
      for (final o in visiblePinned) MultiEntry(MultiKind.option, o),
      if (visiblePinned.isNotEmpty && followsDivider)
        const MultiEntry(MultiKind.divider),
      if (action != null) const MultiEntry(MultiKind.action),
      for (final o in visibleAdded) MultiEntry(MultiKind.option, o),
      for (final o in visibleOptions) MultiEntry(MultiKind.option, o),
      if (allRows.isEmpty && hasEmptyNote) const MultiEntry(MultiKind.empty),
      if (hasListFooter) const MultiEntry(MultiKind.footer),
    ];
  }

  final List<SelectionOption<T>> pinned;
  final List<SelectionOption<T>> options;
  final Set<T> chosen;
  final MultiSelectionAction<T>? action;
  final bool hasBanner;
  final bool hasEmptyNote;
  final bool hasListFooter;
  final bool hasSelectAll;

  /// Fewest enabled options that must stay chosen (0 = no minimum).
  final int minSelected;

  late final List<SelectionOption<T>> addedRows;
  late final List<SelectionOption<T>> allRows;
  late final List<T> enabledValues;
  late final Set<T> picks;
  late final bool iconRows;
  late final bool showAll;
  late final List<MultiEntry<T>> entries;

  /// True while the chosen options are all that the minimum allows: none of
  /// them can be unchosen.
  bool get atMinimum => minSelected > 0 && picks.length <= minSelected;

  /// Whether [value] is chosen and must stay so.
  bool isLocked(T value) => atMinimum && picks.contains(value);

  /// Select-all is off only with a minimum and every enabled option chosen:
  /// its tap would clear them all.
  bool get selectAllLocked =>
      minSelected > 0 && picks.length == enabledValues.length;
}
