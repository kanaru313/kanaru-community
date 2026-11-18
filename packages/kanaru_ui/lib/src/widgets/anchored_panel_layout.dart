import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';

/// Places a panel under [anchor] (left edges aligned), clamped to the screen
/// and flipped above the anchor when there is no room below. Used by the
/// desktop popovers and panels that open from a row or an icon.
class AnchoredPanelLayout extends SingleChildLayoutDelegate {
  AnchoredPanelLayout(this.anchor);

  final Rect anchor;

  /// Global rect of the box behind [key], or null when it is not on screen.
  static Rect? rectOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject();
    return box is RenderBox && box.attached
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
  }

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
        : (anchor.top - KSpace.x1 - childSize.height).clamp(
            KSpace.x4,
            size.height,
          );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(AnchoredPanelLayout oldDelegate) =>
      anchor != oldDelegate.anchor;
}
