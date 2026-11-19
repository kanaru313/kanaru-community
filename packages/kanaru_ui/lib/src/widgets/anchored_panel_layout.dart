import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';

/// Which edge of an anchored panel lines up with its anchor.
enum KAnchorAlign {
  /// Left edges aligned (the default of every anchored panel).
  start,

  /// Right edges aligned: panels opened from a Settings or first-run row.
  end,
}

/// Places a panel under [anchor] ([align]: left or right edges aligned),
/// clamped to the screen and flipped above the anchor when there is no room
/// below. Used by the desktop popovers and panels that open from a row or an
/// icon.
class AnchoredPanelLayout extends SingleChildLayoutDelegate {
  AnchoredPanelLayout(this.anchor, {this.align = KAnchorAlign.start});

  final Rect anchor;
  final KAnchorAlign align;

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
    final wanted = switch (align) {
      KAnchorAlign.start => anchor.left,
      KAnchorAlign.end => anchor.right - childSize.width,
    };
    final x = wanted.clamp(
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
      anchor != oldDelegate.anchor || align != oldDelegate.align;
}
