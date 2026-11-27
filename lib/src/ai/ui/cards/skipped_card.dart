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

/// The only place that reads the engine's result wording. A call run in Auto
/// mode keeps no confirm part, so the text the model was given is all that
/// says why it did not run; the engine exposes no reason code for it.
@visibleForTesting
({SkipReason? reason, ExecRefusal? refusal}) skipFromResultText(String? text) {
  if (text == null) return (reason: null, refusal: null);
  for (final r in ExecRefusal.values) {
    if (text == notAllowedNowText(r)) {
      return (reason: SkipReason.refusedNow, refusal: r);
    }
  }
  final reason = switch (text) {
    expiredText => SkipReason.expired,
    newMessageText => SkipReason.declinedByNewMessage,
    stoppedByUserText => SkipReason.stopped,
    tooLargeSkippedText => SkipReason.tooLarge,
    limitSkippedText => SkipReason.itemLimit,
    deniedByUserText => SkipReason.declined,
    _ => null,
  };
  return (reason: reason, refusal: null);
}

/// The engine's refusal behind a "not allowed now" card: the code stored with
/// the card, else the one the result text names.
ExecRefusal? refusalOf(AiMessage m) {
  final code = confirmOf(m)?.reason;
  for (final r in ExecRefusal.values) {
    if (r.code == code) return r;
  }
  return skipFromResultText(_resultText(m)).refusal;
}

/// Why the skipped card [m] did not run: the stored confirm first, the result
/// text (see [skipFromResultText]) when the call had none.
SkipReason skipReasonOf(AiMessage m) {
  final confirm = confirmOf(m);
  final text = skipFromResultText(_resultText(m)).reason;
  if (confirm?.status == ConfirmStatus.expired || text == SkipReason.expired) {
    return SkipReason.expired;
  }
  if (confirm?.status == ConfirmStatus.deniedByNewMessage ||
      text == SkipReason.declinedByNewMessage) {
    return SkipReason.declinedByNewMessage;
  }
  if (confirm?.reason == 'stopped' || text == SkipReason.stopped) {
    return SkipReason.stopped;
  }
  if (confirm?.reason == AiErrorCode.tooLarge.wire ||
      text == SkipReason.tooLarge) {
    return SkipReason.tooLarge;
  }
  if (text == SkipReason.itemLimit) return SkipReason.itemLimit;
  if (refusalOf(m) != null) return SkipReason.refusedNow;
  if (confirm?.status == ConfirmStatus.denied || text == SkipReason.declined) {
    return SkipReason.declined;
  }
  return SkipReason.other;
}
