import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/chat_view/composer_view.dart';

/// Send, or Stop while the model streams or a tool runs. Send is off until
/// the chat can send (see the lock table). Stop is always on; while a tool
/// runs it says the running tool finishes and the later ones do not run.
class SendButton extends StatelessWidget {
  const SendButton({
    super.key,
    required this.action,
    required this.canSend,
    required this.toolsRunning,
    required this.onSend,
    required this.onStop,
  });

  final ComposerAction action;
  final bool canSend;
  final bool toolsRunning;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (action == ComposerAction.stop) {
      final label = toolsRunning ? l10n.aiChatStopTools : l10n.aiChatStop;
      return Semantics(
        button: true,
        enabled: true,
        label: label,
        excludeSemantics: true,
        onTap: onStop,
        child: IconButton.filledTonal(
          onPressed: onStop,
          tooltip: label,
          // The stop square: no glyph for it in the icon set.
          icon: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.onSecondaryContainer,
              borderRadius: KRadius.xxs,
            ),
            child: const SizedBox.square(dimension: KIconSize.xs - 4),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      enabled: canSend,
      label: l10n.aiChatSend,
      excludeSemantics: true,
      onTap: canSend ? onSend : null,
      child: IconButton.filled(
        onPressed: canSend ? onSend : null,
        tooltip: l10n.aiChatSend,
        icon: const Icon(KIcons.arrowUp),
      ),
    );
  }
}
