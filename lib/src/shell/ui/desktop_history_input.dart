import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../state/nav_history.dart';

/// History keys of the desktop shell, around its left region:
/// Alt+Left / Alt+Right and the mouse Back / Forward buttons walk
/// [NavHistory]; Esc goes back when nothing else wants it.
///
/// Key events arrive by bubbling from a focused shell descendant that did not
/// handle them. Dialogs, sheets and menus live in other routes or overlays,
/// so their own Esc never reaches here. A focused text field keeps Esc.
/// Mouse side buttons are ignored while focus is outside this subtree (a menu
/// or modal is open).
class DesktopHistoryInput extends StatefulWidget {
  const DesktopHistoryInput({
    super.key,
    required this.history,
    required this.focusNode,
    required this.child,
    this.interceptBack,
    this.onKey,
  });

  final NavHistory history;

  /// The node that receives bubbled key events. The owner keeps it so its
  /// global key handler can ask [shellOwnsFocus].
  final FocusNode focusNode;
  final Widget child;

  /// Asked before a Back (Esc, the mouse Back button) walks the history: true
  /// means something else took it (the Now Playing overlay closed).
  final bool Function()? interceptBack;

  /// Offered every key event that bubbled up here and is not a history key
  /// (a focused widget below had its chance first, so a slider keeps its
  /// arrows). True = taken. Not called while a popup route owns the focus.
  final bool Function(KeyEvent event)? onKey;

  /// Whether keys reach the shell's focus tree, or nobody inside it is
  /// focused: nothing has focus, the root scope has it, or an ancestor scope
  /// (the shell's own route) has it. A dialog, sheet or menu has its own
  /// scope, which is none of these, so it keeps the keys.
  static bool shellOwnsFocus(FocusNode shellNode) {
    final focus = FocusManager.instance.primaryFocus;
    if (_inPopupRoute(focus)) return false;
    return focus == null ||
        focus == FocusManager.instance.rootScope ||
        shellNode.ancestors.contains(focus);
  }

  /// A dialog, sheet, popup menu route or open [MenuAnchor] can sit inside the
  /// shell's tree, so focus in one counts as outside.
  static bool _inPopupRoute(FocusNode? focus) {
    final context = focus?.context;
    if (context == null) return false;
    return ModalRoute.of(context) is PopupRoute ||
        (MenuController.maybeIsOpenOf(context) ?? false);
  }

  /// Whether focus is in the shell's tree or [shellOwnsFocus]. Alt+arrows are
  /// taken at this level (a text field would otherwise keep them).
  static bool shellHasFocus(FocusNode shellNode) {
    if (_inPopupRoute(FocusManager.instance.primaryFocus)) return false;
    if (shellOwnsFocus(shellNode)) return true;
    for (
      FocusNode? n = FocusManager.instance.primaryFocus;
      n != null;
      n = n.parent
    ) {
      if (n == shellNode) return true;
    }
    return false;
  }

  /// Whether a text input has focus, so plain keys and arrows belong to it.
  static bool textFieldFocused() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Whether [event] is Alt+Left, Alt+Right or Esc.
  static bool isHistoryKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    final alt = HardwareKeyboard.instance.isAltPressed;
    return key == LogicalKeyboardKey.escape ||
        (alt &&
            (key == LogicalKeyboardKey.arrowLeft ||
                key == LogicalKeyboardKey.arrowRight));
  }

  @override
  State<DesktopHistoryInput> createState() => _DesktopHistoryInputState();
}

class _DesktopHistoryInputState extends State<DesktopHistoryInput> {
  FocusNode get _node => widget.focusNode;

  // A global pointer route runs before the event reaches any widget, so focus
  // still belongs to the menu or dialog this very click dismisses.
  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!DesktopHistoryInput.isHistoryKey(event)) {
      final onKey = widget.onKey;
      if (onKey == null || !DesktopHistoryInput.shellHasFocus(_node)) {
        return KeyEventResult.ignored;
      }
      return onKey(event) ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    // Alt+arrows are taken earlier, by the shell's global key handler.
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    if (DesktopHistoryInput.textFieldFocused()) return KeyEventResult.ignored;
    if (widget.interceptBack?.call() ?? false) return KeyEventResult.handled;
    if (!widget.history.canGoBack) return KeyEventResult.ignored;
    widget.history.back();
    return KeyEventResult.handled;
  }

  void _onPointer(PointerEvent e) {
    if (e is! PointerDownEvent || e.kind != PointerDeviceKind.mouse) return;
    // Focus in another route's scope (a menu or modal): it owns the input.
    if (!DesktopHistoryInput.shellHasFocus(_node)) return;
    if (e.buttons & kBackMouseButton != 0) {
      if (widget.interceptBack?.call() ?? false) return;
      widget.history.back();
    } else if (e.buttons & kForwardMouseButton != 0) {
      widget.history.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
