import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import '../output/ai_error_code.dart';
import '../output/chat_outcome.dart';
import '../output/chat_output_parser.dart';

/// The card of a turn that failed for a reason inside the app (a flight that
/// threw, a round that could not be written).
const internalErrorView = ChatOutcomeView(
  end: ChatMessageEnd.error,
  card: ChatCardKind.server,
  action: ChatCardAction.retry,
  errorCode: AiErrorCode.server,
);

/// What the model reads for a call that did not run.
const stoppedByUserText = 'not run: stopped by the user';
const newMessageText = 'not run: the user sent a new message instead';
const deniedByUserText = 'not run: the user declined this action';
const expiredText = 'not run: the request expired';
const tooLargeSkippedText = 'not run: the conversation grew too large to go on';
const limitSkippedText = 'not run: the limit for this turn was reached';
const toolTimedOutText = 'the tool took too long and was stopped';
const writeTimedOutText =
    'the tool took too long; it is not known whether it changed anything';

/// The stored error code of a turn that hit the item or call limit.
const limitReachedCode = 'limit_reached';

ToolCallPart? callOf(AiMessage card) {
  for (final p in card.parts) {
    if (p is ToolCallPart) return p;
  }
  return null;
}

ConfirmPart? confirmOf(AiMessage card) {
  for (final p in card.parts) {
    if (p is ConfirmPart) return p;
  }
  return null;
}

ToolResultPart errorResult(ToolCallPart call, String text) => ToolResultPart(
  id: call.id,
  providerId: call.providerId,
  name: call.name,
  isError: true,
  content: [TextPart(text)],
);

/// The parts of a card that did not run: the call, its confirm part (when it
/// had one) with the new [status] and [reason], and the result text.
List<AiPart> skippedParts(
  AiMessage card,
  ToolCallPart call,
  String text, {
  ConfirmStatus status = ConfirmStatus.denied,
  String? reason,
}) {
  final confirm = confirmOf(card);
  return [
    call,
    if (confirm != null)
      ConfirmPart(callId: call.id, status: status, reason: reason),
    errorResult(call, text),
  ];
}

/// The parts of a finished call: call, its confirm part, the result and, for
/// a write, what it changed.
List<AiPart> finishedParts(
  AiMessage card,
  ToolCallPart call,
  ToolResultPart result, {
  DonePart? done,
}) {
  final confirm = confirmOf(card);
  return [call, ?confirm, result, ?done];
}

/// Snake-case form of a card name, for stored codes (`pluginUpdated` ->
/// `plugin_updated`).
String snakeCase(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// The error the model gets for a call the app refuses before it runs.
String refusalText(ChatCallRefusal refusal) => 'not run: ${refusal.modelText}';
