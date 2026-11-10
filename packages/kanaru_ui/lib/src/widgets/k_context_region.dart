import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Opens a context menu from every platform gesture: right click, Menu key,
/// Shift+F10 and (when [longPressOpens]) long press. [onOpen] gets the global
/// pointer position, or null for the keyboard (anchor to the widget itself).
///
/// The keyboard shortcuts need a focusable descendant (wrap the content in a
/// `KPressable` or `KListRow`). A child with its own long-press handler wins
/// the gesture over [longPressOpens].
class KContextRegion extends StatelessWidget {
  const KContextRegion({
    super.key,
    required this.child,
    required this.onOpen,
    this.longPressOpens = true,
  });

  final Widget child;
  final void Function(Offset? globalPosition) onOpen;

  /// Pass false where long press already means something else (selection).
  final bool longPressOpens;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final shiftF10 = key == LogicalKeyboardKey.f10 &&
            HardwareKeyboard.instance.isShiftPressed;
        if (key == LogicalKeyboardKey.contextMenu || shiftF10) {
          onOpen(null);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onSecondaryTapDown: (d) => onOpen(d.globalPosition),
        onLongPressStart:
            longPressOpens ? (d) => onOpen(d.globalPosition) : null,
        child: child,
      ),
    );
  }
}
