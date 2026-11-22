import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import 'anchored_panel_layout.dart';
import 'k_row_edges.dart';

/// Opens [child] as the desktop panel anchored to [anchor] (a global rect, see
/// [AnchoredPanelLayout.rectOf]): tonal surface, large squircle corners,
/// elevation 3, placed under the anchor (flipped above when there is no
/// room), no barrier tint. A tap outside and Esc close it. [child] sets its
/// own width. [insetRows] gives rows inside the rounded, inset tint of a
/// panel; false leaves them as the caller built them.
///
/// The one place that builds this panel: pickers, dropdowns and popovers call
/// it, a screen never builds its own.
Future<T?> showKAnchoredPanel<T>(
  BuildContext context, {
  required Rect anchor,
  required WidgetBuilder builder,
  KAnchorAlign align = KAnchorAlign.start,
  bool insetRows = true,
}) {
  return showDialog<T>(
    context: context,
    animationStyle: KMotion.routeAnimationStyle(context),
    // The panel is placed in global coordinates; the route's safe area would
    // shift it by the insets.
    useSafeArea: false,
    barrierColor: const Color(0x00000000),
    builder: (context) {
      final panel = CustomSingleChildLayout(
        delegate: AnchoredPanelLayout(
          anchor,
          align: align,
          bottomInset: MediaQuery.paddingOf(context).bottom,
        ),
        child: Material(
          elevation: 3,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: KShape.of(KRadius.lg, continuous: true),
          clipBehavior: Clip.antiAlias,
          child: builder(context),
        ),
      );
      return insetRows
          ? KRowEdgesScope(edges: KRowEdges.inset, child: panel)
          : panel;
    },
  );
}

/// Global rect of the widget behind [key], or null when it is not on screen:
/// the anchor of [showKAnchoredPanel].
Rect? kAnchorRectOf(GlobalKey? key) => AnchoredPanelLayout.rectOf(key);
