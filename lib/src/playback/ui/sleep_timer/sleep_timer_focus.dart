import 'package:material_ui/material_ui.dart';

/// Every focus node the sleep timer modal moves focus to by itself: the first
/// control of each screen, and the pairs a focused button hands focus to when
/// it turns off. Owned by the modal, so a screen switch can aim at a control of
/// the screen that has just been built.
class SleepTimerFocus {
  /// The "45 phút" tile of the first screen.
  final tile45 = FocusNode(debugLabel: 'sleep tile 45');

  /// Wraps the "Đang chạy" card of the first screen; [focusRunningCard] gives
  /// focus to the button inside it.
  final runningCard = FocusNode(
    debugLabel: 'sleep running card',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// The big number of the custom screen and its − / + buttons.
  final number = FocusNode(debugLabel: 'sleep number');
  final customMinus = FocusNode(debugLabel: 'sleep custom minus');
  final customPlus = FocusNode(debugLabel: 'sleep custom plus');

  /// Running screen: −5 / −1 and +5 / +1 (one pair is built at a time), the
  /// pause / resume button (one node for both looks), Tắt and Đổi….
  final minus = FocusNode(debugLabel: 'sleep minus');
  final plus = FocusNode(debugLabel: 'sleep plus');
  final pause = FocusNode(debugLabel: 'sleep pause');
  final off = FocusNode(debugLabel: 'sleep off');
  final change = FocusNode(debugLabel: 'sleep change');

  /// Gives focus to the button inside the "Đang chạy" card, if it is built.
  bool focusRunningCard() {
    for (final node in runningCard.traversalDescendants) {
      if (node.canRequestFocus) {
        node.requestFocus();
        return true;
      }
    }
    return false;
  }

  void dispose() {
    for (final node in [
      tile45,
      runningCard,
      number,
      customMinus,
      customPlus,
      minus,
      plus,
      pause,
      off,
      change,
    ]) {
      node.dispose();
    }
  }
}
