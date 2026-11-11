import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/browse/selection_providers.dart';
import 'selection_back.dart';

/// What a click on a song row does, by the modifier keys held and whether a
/// selection exists.
enum SongClick {
  /// Plays the row.
  play,

  /// Adds the row to the selection, or removes it.
  toggle,

  /// Selects the rows between the last clicked one and this one.
  range,
}

/// The meaning of a click on a song row now. Shift extends the selection
/// from the last clicked row; Ctrl (⌘ on macOS) or an existing selection
/// toggles the row; anything else plays it.
SongClick songClick({required bool selecting}) {
  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isShiftPressed) return SongClick.range;
  if (keyboard.isControlPressed || keyboard.isMetaPressed || selecting) {
    return SongClick.toggle;
  }
  return SongClick.play;
}

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
