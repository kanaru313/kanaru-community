import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/output/chat_outcome.dart';
import 'package:kanaru/src/ai/state/stored_error_card.dart';

StoredErrorCard _card(String code, [String kind = 'server', int? retry]) =>
    cardOfStoredError(code: code, kind: kind, retryAfterSec: retry);

void main() {
  test('every contract code has its card', () {
    const expected = {
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
    };
    for (final e in expected.entries) {
      expect(_card(e.key).card, e.value, reason: e.key);
    }
  });

  test('the app codes of a card name are told apart', () {
    expect(
      _card('limit_reached', 'invalidResponse').card,
      ChatCardKind.limitReached,
    );
    expect(_card('network').card, ChatCardKind.network);
    expect(_card('host_not_allowed').card, ChatCardKind.hostNotAllowed);
    expect(_card('timeout').card, ChatCardKind.timeout);
    expect(_card('plugin_updated').card, ChatCardKind.pluginUpdated);
    expect(_card('cutOffByClose').card, ChatCardKind.interrupted);
  });

  test('limit reached, network and host not allowed are distinct cards', () {
    final cards = {
      for (final c in [
        'limit_reached',
        'network',
        'host_not_allowed',
        'server',
      ])
        _card(c).card,
    };
    expect(cards, hasLength(4));
  });

  test('actions follow the card', () {
    expect(_card('key').action, ChatCardAction.openPluginSettings);
    expect(_card('model_not_found').action, ChatCardAction.changeModel);
    expect(_card('context_length').action, ChatCardAction.newConversation);
    expect(_card('network').action, ChatCardAction.retry);
    expect(_card('host_not_allowed').action, ChatCardAction.openPlugin);
    expect(_card('limit_reached').action, ChatCardAction.none);
    expect(_card('blocked').action, ChatCardAction.none);
  });

  test('retryAfterSec is kept only when positive', () {
    expect(_card('rate_limit', 'rateLimited', 30).retryAfterSec, 30);
    expect(_card('rate_limit', 'rateLimited', 0).retryAfterSec, isNull);
    expect(_card('rate_limit', 'rateLimited').retryAfterSec, isNull);
  });

  test('an unknown code falls back to its kind, then to server', () {
    expect(
      _card('from_the_future', 'rateLimited').card,
      ChatCardKind.rateLimited,
    );
    expect(_card('from_the_future', 'auth').card, ChatCardKind.badKey);
    expect(_card('from_the_future', 'odd').card, ChatCardKind.server);
  });
}
