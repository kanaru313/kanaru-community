import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../selection_row.dart';
import 'k_sort_pick.dart';
import '../k_row_edges.dart';

export 'k_sort_pick.dart';

/// Share of a short screen the dropdown may take.
const double _maxHeightShare = 0.7;

/// Sort dropdown anchored under [anchor] on both shells (never a sheet).
///
/// Content: the "Nâng cao…" row ([advancedLabel], left out when null), a
/// divider, then the criteria as compact icon rows; the criteria scroll when
/// they do not fit and "Nâng cao…" stays put. The width follows the content
/// ([KLayout.dropdownMinWidth] to [KLayout.dropdownMaxWidth], long names are
/// ellipsized) and the height stops at [KLayout.dropdownMaxHeight] or 70 % of
/// the screen. The criterion in use ([selected]) is tinted and bold, with no
/// tick. Resolves to [KSortPicked] (a criterion, closes), [KSortAdvanced]
/// ("Nâng cao…", closes) or null (dismissed by Esc, Back or a tap outside).
/// Opens on the root navigator so the app's shortcut guard sees it. [onRoute]
/// gets the pushed route, so a caller can remove exactly this route later.
Future<KSortPick<T>?> showKSortPopover<T>(
  BuildContext context, {
  required GlobalKey anchor,
  required List<KSortCriterion<T>> criteria,
  required T selected,
  String? advancedLabel,
  ValueChanged<Route<dynamic>>? onRoute,
}) {
  final box = anchor.currentContext?.findRenderObject();
  final rect = box is RenderBox && box.attached
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<KSortPick<T>>(
    context: context,
    animationStyle: KMotion.routeAnimationStyle(context),
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    // The panel position is in global coordinates; a SafeArea would shift it.
    useSafeArea: false,
    barrierColor: const Color(0x00000000),
    builder: (context) => KRowEdgesScope(
      edges: KRowEdges.inset,
      child: CustomSingleChildLayout(
        delegate: _PopoverLayout(rect),
        child: Material(
          elevation: 3,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: KShape.of(KRadius.lg, continuous: true),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicWidth(
            child: _PopoverBody<T>(
              criteria: criteria,
              selected: selected,
              advancedLabel: advancedLabel,
            ),
          ),
        ),
      ),
    ),
  );
  onRoute?.call(route);
  return navigator.push(route);
}

/// Under the anchor, horizontally centred on it (symmetric, so RTL needs no
/// special case), shifted inward to keep [KSpace.x4] from both screen edges;
/// above the anchor when there is no room below.
class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout(this.anchor);

  final Rect? anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth = math.max(0.0, constraints.maxWidth - 2 * KSpace.x4);
    return BoxConstraints(
      minWidth: math.min(KLayout.dropdownMinWidth, maxWidth),
      maxWidth: math.min(KLayout.dropdownMaxWidth, maxWidth),
      maxHeight: math.max(
        0.0,
        math.min(
          KLayout.dropdownMaxHeight,
          math.min(
            constraints.maxHeight * _maxHeightShare,
            constraints.maxHeight - 2 * KSpace.x4,
          ),
        ),
      ),
    );
  }

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
    final x = (rect.center.dx - childSize.width / 2).clamp(KSpace.x4, maxX);
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

class _PopoverBody<T> extends StatelessWidget {
  const _PopoverBody({
    required this.criteria,
    required this.selected,
    required this.advancedLabel,
  });

  final List<KSortCriterion<T>> criteria;
  final T selected;
  final String? advancedLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The chosen row takes keyboard focus; the first row when none is chosen.
    final hasSelected = criteria.any((c) => c.value == selected);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (advancedLabel != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: KSpace.x2),
              child: SelectionRow(
                dense: true,
                autofocus: !hasSelected,
                leading: const Icon(KIcons.sortAdvanced, size: KIconSize.sm),
                title: _RowText(advancedLabel!),
                selected: false,
                onTap: () => Navigator.of(context).pop(KSortAdvanced<T>()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KSpace.x2,
                vertical: KSpace.x1,
              ),
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant,
              ),
            ),
          ],
          // SingleChildScrollView (not a ListView) so the dropdown can size to
          // its content: a viewport has no intrinsic width.
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: advancedLabel == null ? KSpace.x2 : 0,
                bottom: KSpace.x2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < criteria.length; i++) ...[
                    SelectionRow(
                      dense: true,
                      autofocus: criteria[i].value == selected,
                      leading: criteria[i].icon == null
                          ? null
                          : Icon(criteria[i].icon, size: KIconSize.sm),
                      title: _RowText(criteria[i].label),
                      selected: criteria[i].value == selected,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(KSortPicked<T>(criteria[i].value)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
}
