import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/conversation/ai_message.dart';
import 'cards/chat_cards.dart';

/// Draws the card of a stored row (a confirmation, a done / skipped / unknown
/// result, an error). Returns null for a row it does not draw.
typedef ChatCardBuilder = Widget? Function(
  BuildContext context,
  AiMessage message,
);

/// The slot the message list hands card rows to. Tests replace it to see a
/// row without its card.
final chatCardBuilderProvider = Provider<ChatCardBuilder>(
  (ref) => buildChatCard,
);
