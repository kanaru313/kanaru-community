import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/ai_message.dart';
import '../../domain/loop/card_results.dart';
import '../../domain/tools/item_caps.dart';
import 'card_texts.dart';

/// The turn asked for more changes than one message may make. It names the
/// call that did not run (when the card belongs to one) and has no button: it
/// never retries, the user sends a new message to go on.
class LimitCard extends StatelessWidget {
  const LimitCard({super.key, required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final call = callOf(message);
    return KActionCard(
      icon: KIcons.warning,
      emphasis: KActionCardEmphasis.caution,
      title: l10n.aiChatCardLimitTitle,
      subtitle: call == null
          ? l10n.aiChatCardLimitBody(
              maxRemovedItemsPerTurn,
              maxAddedItemsPerTurn,
            )
          : l10n.aiChatCardLimitBodyAction(
              maxRemovedItemsPerTurn,
              maxAddedItemsPerTurn,
              actionPhrase(l10n, CardRequest.of(call)),
            ),
    );
  }
}
