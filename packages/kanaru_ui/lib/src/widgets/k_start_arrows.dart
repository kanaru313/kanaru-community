import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

/// Asks the enclosing `KStartArea` to move focus one start button in
/// [direction].
class KStartMoveIntent extends Intent {
  const KStartMoveIntent(this.direction);

  final TraversalDirection direction;
}

/// The four arrow keys as [KStartMoveIntent]s, for a start button's own
/// shortcuts (`FocusableActionDetector.shortcuts`) so only a focused start
/// button reacts to arrows: a text field or ruler inside the same area keeps
/// its own arrow keys. Not exported.
Map<ShortcutActivator, Intent> kStartArrowShortcuts(TextDirection direction) {
  final rtl = direction == TextDirection.rtl;
  return {
    const SingleActivator(LogicalKeyboardKey.arrowUp): const KStartMoveIntent(
      TraversalDirection.up,
    ),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const KStartMoveIntent(
      TraversalDirection.down,
    ),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): KStartMoveIntent(
      rtl ? TraversalDirection.right : TraversalDirection.left,
    ),
    const SingleActivator(LogicalKeyboardKey.arrowRight): KStartMoveIntent(
      rtl ? TraversalDirection.left : TraversalDirection.right,
    ),
  };
}

/// Marks everything below it as a start button: the focus nodes under a
/// marker are the targets and sources of `KStartArea` arrow navigation, any
/// other focusable inside the area is left alone. Not exported.
class KStartMarker extends InheritedWidget {
  const KStartMarker({super.key, required super.child});

  /// True when [context] sits below a [KStartMarker].
  static bool isIn(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KStartMarker>() != null;

  @override
  bool updateShouldNotify(KStartMarker old) => false;
}
