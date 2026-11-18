import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../selection/selection_back.dart';
import '../../selection/selection_shortcuts.dart';

/// Ctrl+N / ⌘+N: "new playlist" while the Playlists page is the one on screen.
///
/// A global key handler (like `SelectAllShortcut`), so it works right after a
/// click on the sidebar, when the page holds no focus. It stays quiet while a
/// dialog, sheet or another page covers the app, while the page sits in a tab
/// that is not showing (`TickerMode` off), and while a text field has focus.
/// [onNew] runs only when all of that allows it.
class NewPlaylistShortcut {
  NewPlaylistShortcut(this._context, this._onNew);

  final BuildContext _context;
  final VoidCallback _onNew;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    HardwareKeyboard.instance.removeHandler(_onKey);
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.keyN) return false;
    final keyboard = HardwareKeyboard.instance;
    // Plain Ctrl+N / ⌘+N only: Shift or Alt change the meaning of the chord.
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) return false;
    if (keyboard.isShiftPressed || keyboard.isAltPressed) return false;
    if (!_context.mounted ||
        !TickerMode.getValuesNotifier(_context).value.enabled ||
        rootModalOpen(_context) ||
        ModalRoute.isCurrentOf(_context) == false ||
        textFieldHasFocus()) {
      return false;
    }
    _onNew();
    return true;
  }
}
