import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// The [Cancel] text button and the filled confirm button of a playlist
/// dialog. The confirm button follows [enabled] (the form is valid) and shows
/// a progress indicator while [busy]: its label stays in semantics. While
/// busy neither button reacts, so a second submit is impossible.
List<Widget> playlistDialogActions(
  BuildContext context, {
  required String confirmLabel,
  required ValueListenable<bool> enabled,
  required bool busy,
  required VoidCallback onConfirm,
  required VoidCallback onCancel,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    TextButton(
      onPressed: busy ? null : onCancel,
      child: Text(l10n.playlistCancel),
    ),
    ValueListenableBuilder<bool>(
      valueListenable: enabled,
      builder: (context, valid, _) => FilledButton(
        onPressed: valid && !busy ? onConfirm : null,
        child: busy
            ? Semantics(
                label: confirmLabel,
                child: const SizedBox.square(
                  dimension: KIconSize.sm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Text(confirmLabel),
      ),
    ),
  ];
}
