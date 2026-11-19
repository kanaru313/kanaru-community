import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import 'anchored_panel_layout.dart';
import 'k_sheet.dart';
import 'multi_selection_body.dart';
import 'selection_picker.dart';
import 'k_row_edges.dart';

export 'multi_selection_body.dart' show MultiSelectionAction;

/// Largest height of the desktop dialog.
const double _dialogMaxHeight = 620;

/// Multi-choice picker with fixed header and footer and scrolling rows.
/// Mobile: a sheet fixed at 85 % of the height. Desktop: a dialog
/// [KLayout.dialog] wide, at most 620 tall. Resolves to the chosen values, or
/// null on cancel, Back or a tap outside.
///
/// Rows, top to bottom: [pinned] options, a divider (only while a pinned row
/// shows and a row follows), the [leadingAction] row, rows that action added
/// (selected, newest first), then [options]. Icon options show a tinted row and
/// a plain tick on the right; text options a [KCheckMark] at the start. The
/// tristate "select all" first row exists only with [selectAllLabel] (and at
/// least two enabled options); its subtitle is [selectedCountLabel]. It acts
/// on every enabled row, whether the filter shows it or not.
///
/// [filterHint] non-null adds a filter field (not focused on open) that
/// matches [SelectionOption.filterText] only; rows it hides stay chosen.
///
/// Confirm is on only while something is chosen and [canConfirm] (when given)
/// agrees. [confirm] runs before closing: while it runs the confirm button
/// shows a progress ring and the buttons, the rows and every way to pop are
/// blocked. `false` (or running past [confirmTimeout]; the late answer is
/// ignored) unblocks with the same ticks; `true` closes with the set.
/// [confirmTimeout] null means the caller bounds its own [confirm].
///
/// With [onChanged] the picker is live: no footer, every tap reports the
/// chosen set, [cancelLabel] / [confirmLabel] / [footerNote] are not needed
/// and the future resolves to null on close. [minSelected] locks the last
/// chosen rows ([minSelectedNote] is added to their subtitle). On desktop
/// [anchor] opens a panel under that row ([anchorAlign] picks the aligned
/// edge, `end` for Settings rows); without it, a centred dialog.
Future<Set<T>?> showMultiSelectionPicker<T>(
  BuildContext context, {
  required Widget title,
  required List<SelectionOption<T>> options,
  Widget Function(BuildContext context, Set<T> selected)? footerNote,
  String? cancelLabel,
  String Function(Set<T> selected)? confirmLabel,
  Widget? subtitle,
  Set<T> initial = const {},
  String? selectAllLabel,
  String Function(int n, int total)? selectedCountLabel,
  int minSelected = 0,
  String? minSelectedNote,
  List<SelectionOption<T>> pinned = const [],
  MultiSelectionAction<T>? leadingAction,
  String? filterHint,
  Future<bool> Function(Set<T> selected)? confirm,
  Duration? confirmTimeout = const Duration(seconds: 10),
  bool Function(Set<T> selected)? canConfirm,
  ValueChanged<Set<T>>? onChanged,
  GlobalKey? anchor,
  KAnchorAlign anchorAlign = KAnchorAlign.start,
}) {
  Widget body({required bool sheet, bool dense = false}) =>
      MultiSelectionBody<T>(
        title: title,
        subtitle: subtitle,
        options: options,
        pinned: pinned,
        initial: initial,
        leadingAction: leadingAction,
        filterHint: filterHint,
        footerNote: footerNote,
        selectAllLabel: selectAllLabel,
        selectedCountLabel: selectedCountLabel,
        minSelected: minSelected,
        minSelectedNote: minSelectedNote,
        onChanged: onChanged,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        confirm: confirm,
        confirmTimeout: confirmTimeout,
        canConfirm: canConfirm,
        // A live list is short: the sheet fits it instead of filling 85 %.
        fillHeight: sheet && onChanged == null,
        footerBorder: true,
        dense: dense,
      );

  if (FormFactor.of(context) == FormFactor.mobile) {
    return showKSheet<Set<T>>(
      context,
      fixedHeight: onChanged == null,
      builder: (_) => body(sheet: true),
    );
  }
  final rect = AnchoredPanelLayout.rectOf(anchor);
  if (rect != null) {
    // Desktop with an anchor: a panel under the row, like the single picker.
    return showDialog<Set<T>>(
      context: context,
      animationStyle: KMotion.routeAnimationStyle(context),
      useSafeArea: false,
      barrierColor: const Color(0x00000000),
      builder: (context) => CustomSingleChildLayout(
        delegate: AnchoredPanelLayout(rect, align: anchorAlign),
        child: Material(
          elevation: 3,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: KShape.of(KRadius.lg, continuous: true),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            // A fixed width: the rows live in a lazy list, which cannot
            // report an intrinsic width.
            constraints: const BoxConstraints.tightFor(
              width: KLayout.anchoredPickerMaxWidth,
            ).enforce(const BoxConstraints(maxHeight: _dialogMaxHeight)),
            child: body(sheet: false, dense: true),
          ),
        ),
      ),
    );
  }
  return showDialog<Set<T>>(
    context: context,
    animationStyle: KMotion.routeAnimationStyle(context),
    builder: (_) => KRowEdgesScope(
      edges: KRowEdges.inset,
      child: Dialog(
        shape: KShape.of(KRadius.xl, continuous: true),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: KLayout.dialog,
            maxHeight: _dialogMaxHeight,
          ),
          child: body(sheet: false),
        ),
      ),
    ),
  );
}
