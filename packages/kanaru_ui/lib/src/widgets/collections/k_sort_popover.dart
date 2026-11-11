import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../tokens/k_layout.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../../icons/k_icons.dart';
import '../k_gap.dart';
import '../selection_row.dart';

/// One sort criterion of [showKSortPopover].
class KSortCriterion<T> {
  const KSortCriterion({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Sort dropdown anchored under [anchor] on both shells (never a sheet).
///
/// Top row: two order buttons. Tapping one reports through
/// [onAscendingChanged] and the popover stays open. Below a divider the
/// criteria are selection rows; choosing one closes the popover and resolves
/// to its value (null when dismissed). The criteria scroll when they do not
/// fit; the order row stays. Esc and Back close it. Opens on the root
/// navigator so the app's shortcut guard sees it.
Future<T?> showKSortPopover<T>(
  BuildContext context, {
  required GlobalKey anchor,
  required List<KSortCriterion<T>> criteria,
  required T selected,
  required bool ascending,
  required String ascendingLabel,
  required String descendingLabel,
  required ValueChanged<bool> onAscendingChanged,
}) {
  final box = anchor.currentContext?.findRenderObject();
  final rect = box is RenderBox && box.attached
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    // The panel position is in global coordinates; a SafeArea would shift it.
    useSafeArea: false,
    barrierColor: const Color(0x00000000),
    builder: (context) => CustomSingleChildLayout(
      delegate: _PopoverLayout(rect),
      child: Material(
        elevation: 3,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: KShape.of(KRadius.lg, continuous: true),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
          child: _PopoverBody<T>(
            criteria: criteria,
            selected: selected,
            ascending: ascending,
            ascendingLabel: ascendingLabel,
            descendingLabel: descendingLabel,
            onAscendingChanged: onAscendingChanged,
          ),
        ),
      ),
    ),
  );
}

const double _width = 280;

/// Under the anchor, right edges aligned (the chip sits at the end of the
/// bar), clamped to the screen; above the anchor when there is no room below.
class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout(this.anchor);

  final Rect? anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth - 2 * KSpace.x4,
        maxHeight: constraints.maxHeight - 2 * KSpace.x4,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final rect = anchor;
    if (rect == null) {
      return Offset(
        (size.width - childSize.width) / 2,
        (size.height - childSize.height) / 2,
      );
    }
    final maxX = (size.width - childSize.width - KSpace.x4).clamp(
      KSpace.x4,
      size.width,
    );
    final x = (rect.right - childSize.width).clamp(KSpace.x4, maxX);
    final below = rect.bottom + KSpace.x1;
    final y = below + childSize.height <= size.height - KSpace.x4
        ? below
        : (rect.top - KSpace.x1 - childSize.height).clamp(
            KSpace.x4,
            size.height,
          );
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  bool shouldRelayout(_PopoverLayout old) => anchor != old.anchor;
}

class _PopoverBody<T> extends StatefulWidget {
  const _PopoverBody({
    required this.criteria,
    required this.selected,
    required this.ascending,
    required this.ascendingLabel,
    required this.descendingLabel,
    required this.onAscendingChanged,
  });

  final List<KSortCriterion<T>> criteria;
  final T selected;
  final bool ascending;
  final String ascendingLabel;
  final String descendingLabel;
  final ValueChanged<bool> onAscendingChanged;

  @override
  State<_PopoverBody<T>> createState() => _PopoverBodyState<T>();
}

class _PopoverBodyState<T> extends State<_PopoverBody<T>> {
  late bool _ascending = widget.ascending;

  void _setOrder(bool ascending) {
    if (ascending == _ascending) return;
    setState(() => _ascending = ascending);
    widget.onAscendingChanged(ascending);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(KSpace.x2),
              child: Row(
                children: [
                  Expanded(
                    child: _OrderButton(
                      icon: KIcons.sortAsc,
                      label: widget.ascendingLabel,
                      selected: _ascending,
                      onTap: () => _setOrder(true),
                    ),
                  ),
                  const KGap(KSpace.x1),
                  Expanded(
                    child: _OrderButton(
                      icon: KIcons.sortDesc,
                      label: widget.descendingLabel,
                      selected: !_ascending,
                      onTap: () => _setOrder(false),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(KSpace.x2),
                itemCount: widget.criteria.length,
                separatorBuilder: (_, _) => const KGap(KSpace.x1),
                itemBuilder: (context, i) {
                  final c = widget.criteria[i];
                  return SelectionRow(
                    leading: c.icon == null ? null : Icon(c.icon),
                    title: Text(c.label),
                    selected: c.value == widget.selected,
                    onTap: () => Navigator.of(context).pop(c.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderButton extends StatelessWidget {
  const _OrderButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : const Color(0x00000000),
        shape: KShape.of(KRadius.full),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KLayout.minTarget),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const KGap(KSpace.x1),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: selected ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
