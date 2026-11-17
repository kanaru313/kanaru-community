import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';

/// Drag handle of a reorderable row: starts a reorder on drag, swallows a
/// tap (so it does not trigger the row), shows a grab cursor for a mouse.
/// Takes the colour of the surrounding icons.
///
/// The touch target is [KLayout.minTargetDesktop] on the desktop shell and
/// [KLayout.minTarget] on mobile; a caller that knows its shell better than
/// the window width (a row that is told its size) passes [dimension].
/// [semanticLabel] names the handle for screen readers; [tooltip] adds a
/// long-press / hover tooltip (which also names it). One of them is required.
class KDragHandle extends StatelessWidget {
  const KDragHandle({
    super.key,
    required this.index,
    this.dimension,
    this.iconSize,
    this.compact = false,
    this.semanticLabel,
    this.tooltip,
  }) : assert(
         semanticLabel != null || tooltip != null,
         'a drag handle needs a semanticLabel or a tooltip',
       );

  /// Index of the row in its [ReorderableList].
  final int index;
  final double? dimension;

  /// Glyph size; null keeps the ambient icon size. Rows that set their
  /// action buttons to `KIconSize.sm` pass the same size so the handle sits
  /// in the same cluster.
  final double? iconSize;

  /// Narrow handle for a dense row with several controls (the sort box):
  /// [compactWidth] wide and [KLayout.minTarget] tall; [dimension] is ignored.
  final bool compact;

  static const double compactWidth = 28;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final size =
        dimension ??
        (FormFactor.of(context) == FormFactor.desktop
            ? KLayout.minTargetDesktop
            : KLayout.minTarget);
    final icon = Icon(KIcons.dragHandle, size: iconSize);
    Widget handle = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: compact
          ? SizedBox(
              width: compactWidth,
              height: KLayout.minTarget,
              child: icon,
            )
          : SizedBox.square(dimension: size, child: icon),
    );
    if (tooltip != null) handle = Tooltip(message: tooltip, child: handle);
    if (semanticLabel != null) {
      handle = Semantics(label: semanticLabel, child: handle);
    }
    return ReorderableDragStartListener(
      index: index,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Swallows the tap without a do-nothing semantics action.
        excludeFromSemantics: true,
        onTap: () {},
        child: handle,
      ),
    );
  }
}
