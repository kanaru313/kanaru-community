import 'package:material_ui/material_ui.dart';

/// Floating snack bar through the nearest [ScaffoldMessenger]; replaces the
/// one on screen. The shell supplies the bottom inset so it clears the mini
/// player or player bar.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final hasAction = actionLabel != null && onAction != null;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: hasAction
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
}
