import '../domain/loop/card_results.dart' show limitReachedCode, snakeCase;
import '../domain/output/chat_outcome.dart';

/// The card a stored failure shows after a reload: what the chat UI needs
/// when the live [ChatOutcomeView] of the run is long gone.
class StoredErrorCard {
  const StoredErrorCard({
    required this.card,
    required this.action,
    this.retryAfterSec,
  });

  final ChatCardKind card;
  final ChatCardAction action;

  /// Seconds the provider asked to wait (rate limit), as stored.
  final int? retryAfterSec;
}

/// The stored code a startup sweep writes for a turn cut off by closing the
/// app (`ConversationStore.sweepAfterCrash`).
const cutOffByCloseCode = 'cutOffByClose';

// Contract codes (`ai:<code>`) to their card; every other stored code is the
// snake-case name of a card (`timeout`, `network`, `host_not_allowed`, ...).
const _contractCards = {
  'key': ChatCardKind.badKey,
  'quota': ChatCardKind.quota,
  'rate_limit': ChatCardKind.rateLimited,
  'config': ChatCardKind.config,
  'bad_request': ChatCardKind.badRequest,
  'model_not_found': ChatCardKind.modelNotFound,
  'context_length': ChatCardKind.contextLength,
  'too_large': ChatCardKind.tooLarge,
  'blocked': ChatCardKind.blocked,
  'empty': ChatCardKind.empty,
  'server': ChatCardKind.server,
  cutOffByCloseCode: ChatCardKind.interrupted,
  limitReachedCode: ChatCardKind.limitReached,
};

final Map<String, ChatCardKind> _byName = {
  for (final k in ChatCardKind.values) snakeCase(k.name): k,
  ..._contractCards,
};

// A code this build does not know still has a kind from the contract.
const _byKind = {
  'rateLimited': ChatCardKind.rateLimited,
  'auth': ChatCardKind.badKey,
  'quota': ChatCardKind.quota,
};

ChatCardAction _actionOf(ChatCardKind card) => switch (card) {
  ChatCardKind.rateLimited ||
  ChatCardKind.previousTurnBusy ||
  ChatCardKind.previousTurnStuck ||
  ChatCardKind.pluginUpdated ||
  ChatCardKind.timeout ||
  ChatCardKind.pluginError ||
  ChatCardKind.interrupted ||
  ChatCardKind.network ||
  ChatCardKind.badRequest ||
  ChatCardKind.quota ||
  ChatCardKind.empty ||
  ChatCardKind.server => ChatCardAction.retry,
  ChatCardKind.needsConfig ||
  ChatCardKind.badKey ||
  ChatCardKind.config => ChatCardAction.openPluginSettings,
  ChatCardKind.pluginBroken ||
  ChatCardKind.hostNotAllowed => ChatCardAction.openPlugin,
  ChatCardKind.pluginRemoved => ChatCardAction.choosePlugin,
  ChatCardKind.modelNotFound => ChatCardAction.changeModel,
  ChatCardKind.contextLength ||
  ChatCardKind.tooLarge => ChatCardAction.newConversation,
  ChatCardKind.stopped ||
  ChatCardKind.blocked ||
  ChatCardKind.limitReached => ChatCardAction.none,
};

/// Maps a stored `{code, kind, retryAfterSec?}` to its card. An unknown code
/// falls back to its kind, then to a server failure, so a newer build's code never breaks the chat.
///
/// Network, host-not-allowed and limit-reached failures are stored under
/// their own codes (`appErrorCodes`), so they come back as their own cards.
StoredErrorCard cardOfStoredError({
  required String code,
  required String kind,
  int? retryAfterSec,
}) {
  final card = _byName[code] ?? _byKind[kind] ?? ChatCardKind.server;
  return StoredErrorCard(
    card: card,
    action: _actionOf(card),
    retryAfterSec: retryAfterSec != null && retryAfterSec > 0
        ? retryAfterSec
        : null,
  );
}
