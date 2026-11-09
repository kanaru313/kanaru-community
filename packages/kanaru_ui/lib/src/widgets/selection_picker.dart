import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';
import 'k_sheet.dart';
import 'selection_row.dart';

/// One option of [showSelectionPicker].
class SelectionOption<T> {
  const SelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
  });

  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool enabled;
}

/// Single-choice picker. Mobile: sheet ([showKSheet]). Desktop: a panel
/// anchored under [anchor] when given, otherwise a centred dialog.
///
/// [header] sits above the options and stays put while they scroll.
/// [confirm] runs before the picker closes; returning false keeps it open
/// (the choice is never popped first and asked about afterwards).
/// Resolves to the chosen value, or null when dismissed.
Future<T?> showSelectionPicker<T>(
  BuildContext context, {
  required List<SelectionOption<T>> options,
  required T? selected,
  Widget? title,
  Widget? header,
  Future<bool> Function(T value)? confirm,
  GlobalKey? anchor,
}) {
  Widget body(BuildContext _) => _PickerBody<T>(
        options: options,
        selected: selected,
        title: title,
        header: header,
        confirm: confirm,
      );

  if (FormFactor.of(context) == FormFactor.mobile) {
    return showKSheet<T>(context, builder: body);
  }
  final box = anchor?.currentContext?.findRenderObject();
  final rect = box is RenderBox && box.attached
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  if (rect == null) {
    return showDialog<T>(
      context: context,
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
    // The panel position is computed in global coordinates; the route's
    // SafeArea would shift it by the insets.
    useSafeArea: false,
    barrierColor: const Color(0x00000000),
    builder: (context) => CustomSingleChildLayout(
      delegate: _AnchoredLayout(rect),
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

/// Places the panel under the anchor, left edges aligned, clamped to the
/// screen; flips above the anchor when there is no room below.
class _AnchoredLayout extends SingleChildLayoutDelegate {
  _AnchoredLayout(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth - 2 * KSpace.x4,
        maxHeight: constraints.maxHeight - 2 * KSpace.x4,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = anchor.left.clamp(
      KSpace.x4,
      (size.width - childSize.width - KSpace.x4).clamp(KSpace.x4, size.width),
    );
    final below = anchor.bottom + KSpace.x1;
    final y = below + childSize.height <= size.height - KSpace.x4
        ? below
        : (anchor.top - KSpace.x1 - childSize.height).clamp(KSpace.x4, size.height);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_AnchoredLayout oldDelegate) => anchor != oldDelegate.anchor;
}

class _PickerBody<T> extends StatefulWidget {
  const _PickerBody({
    required this.options,
    required this.selected,
    required this.title,
    required this.header,
    required this.confirm,
  });

  final List<SelectionOption<T>> options;
  final T? selected;
  final Widget? title;
  final Widget? header;
  final Future<bool> Function(T value)? confirm;

  @override
  State<_PickerBody<T>> createState() => _PickerBodyState<T>();
}

class _PickerBodyState<T> extends State<_PickerBody<T>> {
  /// Blocks a second tap while [_PickerBody.confirm] is pending.
  bool _busy = false;

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
            padding: const EdgeInsets.fromLTRB(KSpace.x6, KSpace.x4, KSpace.x6, KSpace.x2),
            child: DefaultTextStyle.merge(
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                selected: o.value == widget.selected,
                onTap: () => _pick(o.value),
              );
            },
          ),
        ),
      ],
    );
  }
}
