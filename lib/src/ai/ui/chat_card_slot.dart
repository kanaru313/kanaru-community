import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/conversation/ai_message.dart';

/// Draws the card of a stored row (a confirmation, a done / skipped / unknown
/// result, an error). Returns null for a row it does not draw.
typedef ChatCardBuilder = Widget? Function(
  BuildContext context,
  AiMessage message,
);

/// The slot the message list hands card rows to. The cards are built by a
/// later part, which replaces this provider's value; until then no card is
/// drawn.
final chatCardBuilderProvider = Provider<ChatCardBuilder>(
  (ref) =>
      (context, message) => null,
);
