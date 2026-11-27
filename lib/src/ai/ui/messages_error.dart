import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Shown in place of the messages when reading them failed.
class ChatMessagesError extends StatelessWidget {
  const ChatMessagesError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(KSpace.x4),
      child: KInlineNotice(
        icon: KIcons.warning,
        tone: KInlineNoticeTone.error,
        message: l10n.aiChatMessagesError,
        actionLabel: l10n.aiChatMessagesRetry,
        onAction: onRetry,
      ),
    );
  }
}
