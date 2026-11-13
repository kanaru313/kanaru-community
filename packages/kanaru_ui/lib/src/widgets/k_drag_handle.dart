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
/// long-press / hover tooltip (which also names it). Pass one of them.
class KDragHandle extends StatelessWidget {
  const KDragHandle({
    super.key,
    required this.index,
    this.dimension,
    this.semanticLabel,
    this.tooltip,
  });

  /// Index of the row in its [ReorderableList].
  final int index;
  final double? dimension;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final size =
        dimension ??
        (FormFactor.of(context) == FormFactor.desktop
            ? KLayout.minTargetDesktop
            : KLayout.minTarget);
    Widget handle = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox.square(
        dimension: size,
        child: const Icon(KIcons.dragHandle),
      ),
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
