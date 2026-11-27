import 'package:flutter/widgets.dart';

import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/loop/card_results.dart' show limitReachedCode;
import 'confirm_card.dart';
import 'done_card.dart';
import 'error_card.dart';
import 'limit_card.dart';
import 'skipped_card.dart';
import 'unknown_result_card.dart';

/// The card of a stored row the message list hands over, or null for a row
/// that is not a card (a plain stop draws "Đã dừng" in the answer itself; a
/// failed read is a tool card).
Widget? buildChatCard(BuildContext context, AiMessage message) {
  final limit = message.parts.any(
    (p) => p is ErrorPart && p.code == limitReachedCode,
  );
  switch (message.role) {
    case AiMessageRole.assistant:
      if (limit) return LimitCard(message: message);
      final failed =
          message.state == AiMessageState.error ||
          (message.state == AiMessageState.stopped &&
              message.parts.any((p) => p is ErrorPart));
      return failed ? ErrorCard(message: message) : null;
    case AiMessageRole.tool:
      return switch (message.state) {
        AiMessageState.pending ||
        AiMessageState.allowed => ConfirmCard(message: message),
        AiMessageState.done => DoneCard(message: message),
        AiMessageState.skipped => SkippedCard(message: message),
        AiMessageState.unknown => UnknownResultCard(message: message),
        AiMessageState.error when limit => LimitCard(message: message),
        _ => null,
      };
    case AiMessageRole.user || AiMessageRole.event:
      return null;
  }
}
