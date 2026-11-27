import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/loop/card_results.dart';
import '../../domain/loop/may_execute.dart' show ExecRefusal, notAllowedNowText;
import '../../domain/output/ai_error_code.dart';
import 'card_texts.dart';

/// Why a call never ran, read from what the engine stored with it.
enum SkipReason {
  declined,
  declinedByNewMessage,
  expired,
  stopped,
  refusedNow,
  itemLimit,
  tooLarge,
  other,
}

/// A call that did not run: declined, expired, stopped or refused. Dimmed,
/// never any button. What it would have done is the second line, "không có
/// gì thay đổi".
class SkippedCard extends StatelessWidget {
  const SkippedCard({super.key, required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final call = callOf(message);
    final why = skipReasonOf(message);
    final action = sentenceCase(actionPhrase(l10n, CardRequest.of(call)));
    final refusal = why == SkipReason.refusedNow ? refusalOf(message) : null;
    return KActionCard(
      tone: KActionCardTone.finished,
      icon: switch (why) {
        SkipReason.expired => KIcons.duration,
        SkipReason.stopped ||
        SkipReason.itemLimit ||
        SkipReason.tooLarge ||
        SkipReason.other => KIcons.skipNext,
        _ => KIcons.cancel,
      },
      title: switch (why) {
        SkipReason.declined => l10n.aiChatCardDenied,
        SkipReason.declinedByNewMessage => l10n.aiChatCardDeniedByNewMessage,
        SkipReason.refusedNow => l10n.aiChatCardDeniedNotAllowed,
        SkipReason.expired => l10n.aiChatCardExpired,
        SkipReason.stopped => l10n.aiChatCardSkippedStopped,
        SkipReason.itemLimit ||
        SkipReason.tooLarge ||
        SkipReason.other => l10n.aiChatCardSkipped,
      },
      subtitle: l10n.aiChatCardNothingChanged(action),
      reason: switch (why) {
        SkipReason.expired => l10n.aiChatCardExpiredWhy,
        SkipReason.refusedNow => switch (refusal) {
          ExecRefusal.readOnly => l10n.aiChatCardWhyReadOnly,
          ExecRefusal.groupOff => l10n.aiChatCardWhyGroupOff,
          ExecRefusal.pluginChanged => l10n.aiChatCardWhyPluginChanged,
          ExecRefusal.modelChanged => l10n.aiChatCardWhyModelChanged,
          ExecRefusal.hashMismatch => l10n.aiChatCardWhyChangedAfterAllow,
          _ => l10n.aiChatCardWhyNotAllowed,
        },
        SkipReason.itemLimit => l10n.aiChatCardWhyLimit,
        SkipReason.tooLarge => l10n.aiChatCardWhyTooLarge,
        _ => null,
      },
    );
  }
}

String? _resultText(AiMessage m) {
  for (final p in m.parts) {
    if (p is ToolResultPart) {
      return p.content.whereType<TextPart>().map((t) => t.text).join();
    }
  }
  return null;
}

/// The engine's refusal behind a "not allowed now" card: the code stored with
/// the card, else the one the model's result text names (Auto mode keeps no
/// confirm part).
ExecRefusal? refusalOf(AiMessage m) {
  final code = confirmOf(m)?.reason;
  final text = _resultText(m);
  for (final r in ExecRefusal.values) {
    if (r.code == code || (text != null && text == notAllowedNowText(r))) {
      return r;
    }
  }
  return null;
}

/// Why the skipped card [m] did not run.
SkipReason skipReasonOf(AiMessage m) {
  final confirm = confirmOf(m);
  final text = _resultText(m);
  if (confirm?.status == ConfirmStatus.expired || text == expiredText) {
    return SkipReason.expired;
  }
  if (confirm?.status == ConfirmStatus.deniedByNewMessage ||
      text == newMessageText) {
    return SkipReason.declinedByNewMessage;
  }
  if (confirm?.reason == 'stopped' || text == stoppedByUserText) {
    return SkipReason.stopped;
  }
  if (confirm?.reason == AiErrorCode.tooLarge.wire ||
      text == tooLargeSkippedText) {
    return SkipReason.tooLarge;
  }
  if (text == limitSkippedText) return SkipReason.itemLimit;
  if (refusalOf(m) != null) return SkipReason.refusedNow;
  if (confirm?.status == ConfirmStatus.denied || text == deniedByUserText) {
    return SkipReason.declined;
  }
  return SkipReason.other;
}
