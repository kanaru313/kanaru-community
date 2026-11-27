import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// "Bỏ thay đổi?": true when the user chooses to discard, false for
/// "Tiếp tục sửa" (also Back, Esc and a tap on the scrim).
Future<bool> showPromptDiscardDialog(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final scheme = Theme.of(context).colorScheme;
  final discard = await showKDialog<bool>(
    context,
    builder: (context) => AlertDialog(
      title: Text(l10n.aiSetEdDiscardTitle),
      content: Text(l10n.aiSetEdDiscardBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.aiSetEdDiscardKeep),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.aiSetEdDiscardConfirm),
        ),
      ],
    ),
  );
  return discard ?? false;
}
