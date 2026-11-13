import 'package:flutter/services.dart';

/// What a click on a row of a selectable list does, by the modifier keys held
/// and whether a selection exists.
enum SongClick {
  /// Plays the row.
  play,

  /// Adds the row to the selection, or removes it.
  toggle,

  /// Selects the rows between the last clicked one and this one.
  range,
}

/// The meaning of a click on a row of a selectable list now. Shift extends
/// the selection from the last clicked row; Ctrl (⌘ on macOS) or an existing
/// selection toggles the row; anything else plays it.
SongClick songClick({required bool selecting}) {
  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isShiftPressed) return SongClick.range;
  if (keyboard.isControlPressed || keyboard.isMetaPressed || selecting) {
    return SongClick.toggle;
  }
  return SongClick.play;
}
