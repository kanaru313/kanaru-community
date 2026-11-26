import 'ai_error_code.dart';
import 'chat_output_parser.dart';

/// Where the assistant message ends up after a run.
enum ChatMessageEnd {
  /// The reply is complete; its final text replaces the streamed text.
  complete,

  /// The run failed; streamed text is kept.
  error,

  /// The run was stopped (by the user, a timeout, a plugin change, a closed
  /// app); streamed text is kept.
  stopped,

  /// Nothing was sent: the chat could not start.
  blocked,
}

/// The card a chat shows under a message. The chat UI turns it into text;
/// nothing here is a UI string.
enum ChatCardKind {
  /// The plugin is paused or the provider limited the rate; see `retryAt`.
  rateLimited,
  previousTurnBusy,
  previousTurnStuck,
  needsConfig,
  pluginRemoved,
  pluginBroken,
  pluginUpdated,
  stopped,
  timeout,
  pluginError,
  interrupted,
  network,
  hostNotAllowed,
  badKey,
  quota,
  config,
  badRequest,
  modelNotFound,
  contextLength,
  tooLarge,
  blocked,
  empty,
  server,

  /// The reply asked for more changes than one turn may make.
  limitReached,
}

/// The one button a card offers (none = no button).
enum ChatCardAction {
  none,
  retry,
  openPluginSettings,
  openPlugin,
  choosePlugin,
  newConversation,
  changeModel,
}

/// The pure result of mapping a run outcome: what the message becomes, which
/// card to show and its parameters.
class ChatOutcomeView {
  const ChatOutcomeView({
    required this.end,
    this.card,
    this.action = ChatCardAction.none,
    this.errorCode,
    this.host,
    this.retryAt,
    this.titles = const [],
    this.keepStreamedText = true,
    this.output,
    this.limit,
  });

  /// A reply that passed the parser.
  const ChatOutcomeView.complete(ChatRoundOutput this.output)
    : end = ChatMessageEnd.complete,
      card = null,
      action = ChatCardAction.none,
      errorCode = null,
      host = null,
      retryAt = null,
      titles = const [],
      keepStreamedText = false,
      limit = null;

  /// The app closed during the turn (the chat found the message still
  /// streaming after a restart). Retry acts on the latest turn only.
  const ChatOutcomeView.interrupted()
    : end = ChatMessageEnd.stopped,
      card = ChatCardKind.interrupted,
      action = ChatCardAction.retry,
      errorCode = AiErrorCode.server,
      host = null,
      retryAt = null,
      titles = const [],
      keepStreamedText = true,
      output = null,
      limit = null;

  final ChatMessageEnd end;
  final ChatCardKind? card;
  final ChatCardAction action;

  /// The contract code to store with the error (code and kind only); null
  /// when nothing is stored as an error.
  final AiErrorCode? errorCode;

  /// The host a network or permission card names, when known.
  final String? host;

  /// When a retry is allowed (rate limit, plugin pause).
  final DateTime? retryAt;

  /// Titles of the settings a plugin still needs.
  final List<String> titles;

  /// False only when the final text replaces the streamed text.
  final bool keepStreamedText;

  /// The valid reply, only for [ChatMessageEnd.complete].
  final ChatRoundOutput? output;

  /// Set with [ChatCardKind.limitReached].
  final ChatLimitExceeded? limit;

  bool get isError => end == ChatMessageEnd.error;
}
