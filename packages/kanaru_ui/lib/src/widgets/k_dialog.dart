import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';

/// Centred dialog using the theme's soft shape, capped at [KLayout.dialog].
Future<T?> showKDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: KLayout.dialog),
      child: builder(context),
    ),
  );
}

/// Asks for confirmation. True only when the user confirms; Cancel, Back and
/// a tap on the scrim all give false.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showKDialog<bool>(
    context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
