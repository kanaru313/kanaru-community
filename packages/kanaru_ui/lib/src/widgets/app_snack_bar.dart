import 'package:material_ui/material_ui.dart';

/// Floating snack bar through the nearest [ScaffoldMessenger]; replaces the
/// one on screen. The shell supplies the bottom inset so it clears the mini
/// player or player bar. It always closes after [duration], also with an
/// action (Material keeps an action snack bar until tapped unless
/// `persist: false`), so an "Undo" never outlives its undo window.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppSnackBarOn(
    ScaffoldMessenger.of(context),
    message,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
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
}) {
  final hasAction = actionLabel != null && onAction != null;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
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
}
