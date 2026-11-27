import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/loop/card_results.dart';
import 'card_texts.dart';

/// A write whose outcome is not known: Kanaru closed (or the tool timed out)
/// while it ran, and it is never run again by itself. The card says to check
/// the queue or playlist before asking again; it has no button.
class UnknownResultCard extends StatelessWidget {
  const UnknownResultCard({super.key, required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asked = CardRequest.of(callOf(message));
    final timedOut = message.parts.whereType<ToolResultPart>().any(
      (r) => r.content.whereType<TextPart>().any(
        (t) => t.text == writeTimedOutText,
      ),
    );
    return KActionCard(
      icon: KIcons.help,
      emphasis: KActionCardEmphasis.caution,
      title: l10n.aiChatCardUnknownTitle(actionPhrase(l10n, asked)),
      subtitle:
          '${timedOut ? l10n.aiChatCardUnknownTimedOut : l10n.aiChatCardUnknownClosed} '
          '${asked.isPlaylistTool ? l10n.aiChatCardLookPlaylist : l10n.aiChatCardLookQueue}',
    );
  }
}
