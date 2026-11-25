import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Focus of a seek bar and whether the keyboard drives it, so a focus ring
/// shows for keyboard focus only: a mouse click on desktop leaves the
/// highlight mode on keyboard, and focus coming back after a mouse-only route
/// (a menu or dialog opened and closed by mouse) is not keyboard focus either.
class SeekFocusTracker {
  /// [onChanged] is called whenever what [keyboardFocus] returns may change.
  SeekFocusTracker(this._onChanged) {
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  final VoidCallback _onChanged;
  bool _focused = false;

  /// A pointer focused the bar or touched it while focused; cleared by a key
  /// and by focus the keyboard brings. Kept while focus is away, so focus
  /// restored without a key (a route closed by mouse) shows no ring.
  bool _pointer = false;

  bool get focused => _focused;

  /// Focused, driven by the keyboard and not hidden by a running drag.
  bool keyboardFocus({required bool dragging}) =>
      _focused &&
      !_pointer &&
      !dragging &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    if (_focused) _onChanged();
  }

  void focusChanged(bool focused) {
    // Focus moved by a key (Tab, Shift+Tab, Esc closing a dialog) arrives
    // while that key is still down.
    if (focused && HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty) {
      _pointer = false;
    }
    _focused = focused;
    _onChanged();
  }

  /// A pointer went down on the bar: a focused bar hides its ring. A tap that
  /// brings focus calls [pointerFocuses] itself.
  void pointerDown() {
    if (_focused && !_pointer) {
      _pointer = true;
      _onChanged();
    }
  }

  /// A tap is about to request focus for the bar.
  void pointerFocuses() => _pointer = true;

  /// A key reached the bar: the keyboard drives it now (its ring shows).
  /// Returns -1 for a Left press or repeat, 1 for Right, null otherwise.
  int? arrowKey(KeyEvent event) {
    if (_pointer) {
      _pointer = false;
      _onChanged();
    }
    if (event is KeyUpEvent) return null;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) return -1;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) return 1;
    return null;
  }
}
