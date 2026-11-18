import 'package:material_ui/material_ui.dart';

import '../k_sheet.dart';
import '../multi_selection_body.dart';
import '../selection_picker.dart';

/// Multi-choice sheet (a dialog from 600 dp up, like [showKSheet]): one
/// [SelectionRow] per option, the check on the right and a tinted fill for
/// the chosen ones, and a footer with [cancelLabel] and a confirm button
/// labelled by [confirmLabel] (called with the number chosen, 0 included).
/// Confirm is off while nothing is chosen.
///
/// With [selectAllLabel] and at least two enabled options, a first row
/// chooses or clears every enabled option (clears when all are chosen); its
/// subtitle is [selectedCountLabel] (chosen, enabled total) and its mark is
/// off / partial / on.
///
/// Resolves to the chosen values, or null on cancel, Back or a tap outside.
/// [emptyNote] replaces the list when [options] is empty. [banner] sits above
/// the list and [footerNote] after the list (or the empty note), both inside
/// the scrolling area. See [MultiSelectionSheet] for what happens when the
/// options change while the sheet is open.
Future<Set<T>?> showMultiSelectionSheet<T>(
  BuildContext context, {
  required List<SelectionOption<T>> options,
  required Widget title,
  required String Function(int n) confirmLabel,
  required String cancelLabel,
  Set<T> initial = const {},
  Widget? subtitle,
  Widget? emptyNote,
  Widget? banner,
  Widget? footerNote,
  String? selectAllLabel,
  String Function(int n, int total)? selectedCountLabel,
  bool useRootNavigator = false,
}) => showKSheet<Set<T>>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (_) => MultiSelectionSheet<T>(
    options: options,
    title: title,
    subtitle: subtitle,
    emptyNote: emptyNote,
    banner: banner,
    footerNote: footerNote,
    selectAllLabel: selectAllLabel,
    selectedCountLabel: selectedCountLabel,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    initial: initial,
  ),
);

/// The body of [showMultiSelectionSheet], rendered by the same
/// `MultiSelectionBody` as `showMultiSelectionPicker`. Use it directly when
/// the options change while the sheet is open (a list that loads, reloads or is
/// rescanned): rebuild it with the new [options] and it keeps its state.
///
/// Picks are never pruned: a pick whose option disappears (a reload frame) is
/// kept and comes back with the option, but the select-all row, the confirm
/// label and the result only count picks that have a currently enabled option.
/// Values that appear in [initial] after the first build are chosen once (the
/// user can untick them).
class MultiSelectionSheet<T> extends StatelessWidget {
  const MultiSelectionSheet({
    super.key,
    required this.options,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.subtitle,
    this.emptyNote,
    this.banner,
    this.footerNote,
    this.selectAllLabel,
    this.selectedCountLabel,
    this.initial = const {},
  });

  final List<SelectionOption<T>> options;
  final Widget title;
  final Widget? subtitle;
  final Widget? emptyNote;

  /// Above the list, scrolls with it.
  final Widget? banner;

  /// After the list (or [emptyNote]), scrolls with it.
  final Widget? footerNote;
  final String? selectAllLabel;
  final String Function(int n, int total)? selectedCountLabel;
  final String Function(int n) confirmLabel;
  final String cancelLabel;
  final Set<T> initial;

  @override
  Widget build(BuildContext context) => MultiSelectionBody<T>(
    options: options,
    title: title,
    subtitle: subtitle,
    emptyNote: emptyNote,
    banner: banner,
    listFooter: footerNote,
    selectAllLabel: selectAllLabel,
    selectedCountLabel: selectedCountLabel,
    confirmLabel: (picked) => confirmLabel(picked.length),
    cancelLabel: cancelLabel,
    initial: initial,
  );
}
