import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/browse/selection_providers.dart';
import 'selection_back.dart';

/// Whether a text field has the keyboard focus (a key then belongs to it).
bool textFieldHasFocus() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>() !=
    null;

/// Ctrl+A / ⌘+A adds every song of the list on screen to the selection.
///
/// A global key handler rather than a focus widget, so it works right after
/// a click on the sidebar, when the page holds no focus. It stays quiet
/// while a dialog, sheet or other page covers the app, and while a text
/// field has focus (Ctrl+A selects its text). The list it takes is
/// `activeTrackListProvider`, which only the page on screen registers.
class SelectAllShortcut {
  SelectAllShortcut(this._context, this._container);

  final BuildContext _context;
  final ProviderContainer _container;
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
    if (event.logicalKey != LogicalKeyboardKey.keyA) return false;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) return false;
    if (!_context.mounted ||
        rootModalOpen(_context) ||
        ModalRoute.isCurrentOf(_context) == false ||
        textFieldHasFocus()) {
      return false;
    }
    final ids = _container.read(activeTrackListProvider);
    if (ids == null || ids.isEmpty) return false;
    _container.read(librarySelectionProvider.notifier).addRange(ids);
    return true;
  }
}
