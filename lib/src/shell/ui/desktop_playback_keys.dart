import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../playback/state/player_controller.dart';
import 'desktop_history_input.dart';

/// Seek step of the arrow keys.
const desktopSeekStep = Duration(seconds: 5);

/// Minimum interval between repeated seeks from holding an arrow key.
const desktopSeekRepeatInterval = Duration(milliseconds: 80);

int _lastArrowSeekMs = 0;

/// Resets the repeat throttle timer (for tests).
@visibleForTesting
void resetDesktopPlaybackKeysThrottle() {
  _lastArrowSeekMs = 0;
}

/// Desktop transport keys: Space plays or pauses, Left/Right seek by
/// [desktopSeekStep], Ctrl+S toggles shuffle. Returns true when [event] was
/// one of them and was acted on.
///
/// Left alone (false): a text field has focus, other modifiers are held,
/// nothing is queued. Space and Ctrl+S act once per press, not per
/// auto-repeat; the arrows repeat at most once per [desktopSeekRepeatInterval].
/// The caller decides whether a modal, menu or sheet owns the focus.
bool handleDesktopPlaybackKey(KeyEvent event, PlayerController player) {
  if (event is KeyUpEvent) return false;
  final key = event.logicalKey;
  final keyboard = HardwareKeyboard.instance;
  final plain =
      !keyboard.isControlPressed &&
      !keyboard.isAltPressed &&
      !keyboard.isMetaPressed &&
      !keyboard.isShiftPressed;
  final ctrlOnly =
      keyboard.isControlPressed &&
      !keyboard.isAltPressed &&
      !keyboard.isMetaPressed &&
      !keyboard.isShiftPressed;
  final isArrow =
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight;
  final wanted =
      (plain && (key == LogicalKeyboardKey.space || isArrow)) ||
      (ctrlOnly && key == LogicalKeyboardKey.keyS);
  if (!wanted) return false;
  if (DesktopHistoryInput.textFieldFocused()) return false;
  if (player.queueState.items.isEmpty) return false;
  if (isArrow) {
    if (event is KeyRepeatEvent) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastArrowSeekMs < desktopSeekRepeatInterval.inMilliseconds) {
        return true;
      }
      _lastArrowSeekMs = now;
    } else if (event is KeyDownEvent) {
      _lastArrowSeekMs = DateTime.now().millisecondsSinceEpoch;
    }
    player.seekRelative(
      key == LogicalKeyboardKey.arrowLeft ? -desktopSeekStep : desktopSeekStep,
    );
  } else if (event is KeyDownEvent) {
    if (key == LogicalKeyboardKey.space) {
      player.playPause();
    } else {
      player.setShuffle(!player.queueState.shuffled);
    }
  }
  return true;
}
