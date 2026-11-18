import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Floating snack bar through the nearest [ScaffoldMessenger]; replaces the
/// one on screen. The shell supplies the bottom inset so it clears the mini
/// player or player bar. It always closes after [duration], also with an
/// action (Material keeps an action snack bar until tapped unless
/// `persist: false`), so an "Undo" never outlives its undo window.
///
/// [onClosedWithoutAction] runs when it closes for any reason but a tap on the
/// action (timeout, swipe, replaced by another snack bar): an Undo toast
/// commits its removal there. Use a messenger that outlives the page (capture
/// it before an await, see [showAppSnackBarOn]): if the messenger is disposed
/// before the snack bar closes, the callback never runs.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onClosedWithoutAction,
}) {
  showAppSnackBarOn(
    ScaffoldMessenger.of(context),
    message,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
    onClosedWithoutAction: onClosedWithoutAction,
  );
}

/// [showAppSnackBar] on a [ScaffoldMessengerState] captured earlier, for
/// callers that show it after an await when their context may be gone.
void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onClosedWithoutAction,
}) {
  final hasAction = actionLabel != null && onAction != null;
  messenger.hideCurrentSnackBar();
  final shown = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      persist: false,
      behavior: SnackBarBehavior.floating,
      action: hasAction
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
  if (onClosedWithoutAction != null) {
    unawaited(
      shown.closed.then((reason) {
        if (reason != SnackBarClosedReason.action) onClosedWithoutAction();
      }),
    );
  }
}
