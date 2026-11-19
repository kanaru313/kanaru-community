import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'anchored_panel_layout.dart';
import 'k_gap.dart';
import 'k_sheet.dart';
import 'picker_footer.dart';
import 'selection_row.dart';

/// One option of [showSelectionPicker].
class SelectionOption<T> {
  const SelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.filterText,
    this.hint,
  });

  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool enabled;

  /// Plain text a multi picker filters on (the [title] widget is never
  /// searched). Without it the option always shows.
  final String? filterText;

  /// Accessible description of the option ([SelectionRow.hint]).
  final String? hint;
}

/// Where [showSelectionPicker] shows itself.
enum SelectionPickerPresentation {
  /// Mobile: a sheet. Desktop: a panel under the anchor, or a centred dialog
  /// without one.
  auto,

  /// A centred dialog ([KLayout.dialog] wide) on both shells; the anchor is
  /// ignored.
  dialog,
}

/// Single-choice picker. Mobile: sheet ([showKSheet]). Desktop: a panel
/// anchored under [anchor] when given, otherwise a centred dialog
/// ([presentation] `dialog` forces the dialog on both shells). [anchorAlign]
/// picks which edge of the panel lines up with the anchor (`end` for panels
/// opened from a Settings or first-run row).
///
/// [header] sits above the options and stays put while they scroll.
/// With [confirmLabel] and [cancelLabel] a tap only selects the row and the
/// footer [cancelLabel] / [confirmLabel] closes it; without them a tap chooses
/// and closes. Give both or neither: with only one, release builds stay in
/// tap-to-close mode (debug asserts). [confirm] runs before the picker closes;
/// returning false keeps it open (the choice is never popped first and asked
/// about afterwards). Resolves to the chosen value, or null when dismissed.
Future<T?> showSelectionPicker<T>(
  BuildContext context, {
  required List<SelectionOption<T>> options,
  required T? selected,
  Widget? title,
  Widget? header,
  Future<bool> Function(T value)? confirm,
  GlobalKey? anchor,
  String? confirmLabel,
  String? cancelLabel,
  SelectionPickerPresentation presentation = SelectionPickerPresentation.auto,
  KAnchorAlign anchorAlign = KAnchorAlign.start,
}) {
  assert(
    (confirmLabel == null) == (cancelLabel == null),
    'confirmLabel and cancelLabel go together',
  );
  Widget body(BuildContext _) => _PickerBody<T>(
    options: options,
    selected: selected,
    title: title,
    header: header,
    confirm: confirm,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
  );

  final centred = presentation == SelectionPickerPresentation.dialog;
  if (!centred && FormFactor.of(context) == FormFactor.mobile) {
    return showKSheet<T>(context, builder: body);
  }
  final box = centred ? null : anchor?.currentContext?.findRenderObject();
  final rect = box is RenderBox && box.attached
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  if (rect == null) {
    return showDialog<T>(
      context: context,
      animationStyle: KMotion.routeAnimationStyle(context),
      builder: (context) => Dialog(
        shape: KShape.of(KRadius.xl, continuous: true),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: KLayout.dialog),
          child: body(context),
        ),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    animationStyle: KMotion.routeAnimationStyle(context),
    // The panel position is computed in global coordinates; the route's
    // SafeArea would shift it by the insets.
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
          constraints: const BoxConstraints(maxWidth: KLayout.dialog),
          child: body(context),
        ),
      ),
    ),
  );
}

class _PickerBody<T> extends StatefulWidget {
  const _PickerBody({
    required this.options,
    required this.selected,
    required this.title,
    required this.header,
    required this.confirm,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final List<SelectionOption<T>> options;
  final T? selected;
  final Widget? title;
  final Widget? header;
  final Future<bool> Function(T value)? confirm;
  final String? confirmLabel;
  final String? cancelLabel;

  bool get footer => confirmLabel != null && cancelLabel != null;

  @override
  State<_PickerBody<T>> createState() => _PickerBodyState<T>();
}

class _PickerBodyState<T> extends State<_PickerBody<T>> {
  /// Blocks a second tap while [_PickerBody.confirm] is pending.
  bool _busy = false;

  /// The row chosen so far in footer mode (starts as [_PickerBody.selected]).
  late T? _pending = widget.selected;

  Future<void> _pick(T value) async {
    if (_busy) return;
    final confirm = widget.confirm;
    if (confirm != null) {
      setState(() => _busy = true);
      bool ok;
      try {
        ok = await confirm(value);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      if (!ok || !mounted) return;
    }
    if (mounted) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              KSpace.x4,
              KSpace.x6,
              KSpace.x2,
            ),
            child: DefaultTextStyle.merge(
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              child: widget.title!,
            ),
          ),
        if (widget.header != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
            child: widget.header,
          ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(KSpace.x2),
            itemCount: widget.options.length,
            separatorBuilder: (_, _) => const KGap(KSpace.x1),
            itemBuilder: (context, i) {
              final o = widget.options[i];
              return SelectionRow(
                title: o.title,
                subtitle: o.subtitle,
                leading: o.leading,
                enabled: o.enabled && !_busy,
                selected:
                    o.value == (widget.footer ? _pending : widget.selected),
                onTap: widget.footer
                    ? () => setState(() => _pending = o.value)
                    : () => _pick(o.value),
              );
            },
          ),
        ),
        if (widget.footer) _footer(context),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final pending = _pending;
    return PickerFooter(
      buttons: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel!),
        ),
        FilledButton(
          onPressed: _busy || pending == null
              ? null
              : () {
                  // Read at tap time: the row may have just changed.
                  final chosen = _pending;
                  if (chosen != null) _pick(chosen);
                },
          child: Text(widget.confirmLabel!),
        ),
      ],
    );
  }
}
