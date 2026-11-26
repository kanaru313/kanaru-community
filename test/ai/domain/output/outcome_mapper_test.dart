import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/output/ai_error_code.dart';
import 'package:kanaru/src/ai/domain/output/chat_outcome.dart';
import 'package:kanaru/src/ai/domain/output/chat_output_parser.dart';
import 'package:kanaru/src/ai/domain/output/outcome_mapper.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

final now = DateTime(2026, 11, 27, 12);

const _out = ChatOutputContext(
  turn: 1,
  round: 1,
  offeredNames: {'search_library'},
  finalRound: false,
);

ChatOutcomeContext ctx({
  DateTime? pausedUntil,
  bool pluginRowExists = true,
  int busyInARow = 1,
  bool streamActive = false,
  String? host = 'api.example.com',
}) => ChatOutcomeContext(
  now: now,
  output: _out,
  pausedUntil: pausedUntil,
  pluginRowExists: pluginRowExists,
  busyInARow: busyInARow,
  streamActive: streamActive,
  host: host,
);

final goodJson = jsonEncode({'finish': 'stop', 'text': 'hello'});

ChatOutcomeView map(RunOutcome o, [ChatOutcomeContext? c]) =>
    mapChatOutcome(o, c ?? ctx());

const netFailure = FetchFailureInfo(kind: FetchFailureKind.network);

void expectCard(
  ChatOutcomeView v,
  ChatCardKind card,
  ChatCardAction action, {
  ChatMessageEnd end = ChatMessageEnd.error,
}) {
  expect(v.card, card);
  expect(v.action, action);
  expect(v.end, end);
}

void main() {
  group('RunOk', () {
    test('valid output is complete, text replaced', () {
      final v = map(RunOk(goodJson));
      expect(v.end, ChatMessageEnd.complete);
      expect(v.card, isNull);
      expect(v.keepStreamedText, isFalse);
      expect(v.output!.text, 'hello');
    });

    test('valid output with a caught network failure is complete', () {
      final v = map(
        RunOk(
          goodJson,
          fetchFailure: netFailure,
          rateLimitSeen: const Duration(seconds: 5),
        ),
      );
      expect(v.end, ChatMessageEnd.complete);
      expect(v.card, isNull);
    });

    test('rejected output → bad_request, text kept', () {
      final v = map(const RunOk('{"finish":"stop"}'));
      expectCard(v, ChatCardKind.badRequest, ChatCardAction.retry);
      expect(v.errorCode, AiErrorCode.badRequest);
      expect(v.keepStreamedText, isTrue);
    });

    test('rejected output with rateLimitSeen shows the rate-limit card', () {
      final v = map(
        const RunOk('nope', rateLimitSeen: Duration(seconds: 30)),
        ctx(pausedUntil: now.add(const Duration(seconds: 90))),
      );
      expectCard(v, ChatCardKind.rateLimited, ChatCardAction.retry);
      expect(v.retryAt, now.add(const Duration(seconds: 90)));
      final noPause = map(
        const RunOk('nope', rateLimitSeen: Duration(seconds: 30)),
      );
      expect(noPause.retryAt, now.add(const Duration(seconds: 30)));
    });

    test('rejected output with a fetch failure shows the fetch card', () {
      final v = map(const RunOk('nope', fetchFailure: netFailure));
      expectCard(v, ChatCardKind.network, ChatCardAction.retry);
      expect(v.host, 'api.example.com');
    });

    test('item limit output shows its own card, no retry', () {
      final v = map(
        RunOk(
          jsonEncode({
            'finish': 'tool_calls',
            'text': '',
            'toolCalls': [
              {'name': 'search_library'},
            ],
          }),
        ),
        ChatOutcomeContext(
          now: now,
          output: ChatOutputContext(
            turn: 1,
            round: 1,
            offeredNames: const {'search_library'},
            finalRound: false,
            itemLimit: (_) => const ChatLimitExceeded(ChatLimitKind.itemsAdded),
          ),
        ),
      );
      expectCard(v, ChatCardKind.limitReached, ChatCardAction.none);
      expect(v.limit!.kind, ChatLimitKind.itemsAdded);
    });
  });

  group('RunScriptError codes', () {
    ChatOutcomeView code(String c, {RunErrorKind? kind, Duration? retry}) =>
        map(
          RunScriptError(
            kind ?? RunErrorKind.invalidResponse,
            'ai:$c',
            retryAfter: retry,
          ),
        );

    test('every contract code maps to its card', () {
      expectCard(
        map(const RunScriptError(RunErrorKind.auth, 'ai:key')),
        ChatCardKind.badKey,
        ChatCardAction.openPluginSettings,
      );
      expectCard(
        code('config'),
        ChatCardKind.config,
        ChatCardAction.openPluginSettings,
      );
      expectCard(
        code('bad_request'),
        ChatCardKind.badRequest,
        ChatCardAction.retry,
      );
      expectCard(
        code('model_not_found'),
        ChatCardKind.modelNotFound,
        ChatCardAction.changeModel,
      );
      expectCard(
        code('context_length'),
        ChatCardKind.contextLength,
        ChatCardAction.newConversation,
      );
      expectCard(code('blocked'), ChatCardKind.blocked, ChatCardAction.none);
      expectCard(code('empty'), ChatCardKind.empty, ChatCardAction.retry);
      expectCard(
        map(const RunScriptError(RunErrorKind.server, 'ai:server')),
        ChatCardKind.server,
        ChatCardAction.retry,
      );
      expect(
        map(const RunScriptError(RunErrorKind.server, 'ai:whatever: text'))
            .errorCode,
        AiErrorCode.server,
      );
    });

    test('quota maps to a retry card', () {
      final v = map(const RunScriptError(RunErrorKind.quota, 'ai:quota'));
      expectCard(v, ChatCardKind.quota, ChatCardAction.retry);
      expect(v.errorCode, AiErrorCode.quota);
    });

    test('too_large maps to a new-conversation card', () {
      final v = code('too_large');
      expectCard(v, ChatCardKind.tooLarge, ChatCardAction.newConversation);
      expect(v.errorCode, AiErrorCode.tooLarge);
    });

    test('rate limit: retryAt is the later of retryAfter and the pause', () {
      final v = code(
        'rate_limit',
        kind: RunErrorKind.rateLimited,
        retry: const Duration(seconds: 20),
      );
      expectCard(v, ChatCardKind.rateLimited, ChatCardAction.retry);
      expect(v.retryAt, now.add(const Duration(seconds: 20)));
      final paused = map(
        const RunScriptError(
          RunErrorKind.rateLimited,
          'ai:rate_limit',
          retryAfter: Duration(seconds: 20),
        ),
        ctx(pausedUntil: now.add(const Duration(minutes: 5))),
      );
      expect(paused.retryAt, now.add(const Duration(minutes: 5)));
      final none = code('rate_limit', kind: RunErrorKind.rateLimited);
      expect(none.retryAt, now.add(chatDefaultRateWait));
    });

    test('server error with a failing fetch shows the fetch card', () {
      final v = map(
        const RunScriptError(
          RunErrorKind.server,
          'ai:server',
          fetchFailure: netFailure,
        ),
      );
      expectCard(v, ChatCardKind.network, ChatCardAction.retry);
      // A specific code wins over the fetch failure.
      final key = map(
        const RunScriptError(
          RunErrorKind.auth,
          'ai:key',
          fetchFailure: netFailure,
        ),
      );
      expect(key.card, ChatCardKind.badKey);
    });
  });

  group('fetch failure kinds', () {
    ChatOutcomeView fetch(FetchFailureInfo f) =>
        map(RunFailed(RunFailReason.internal, fetchFailure: f));

    test('network and abandoned name the host', () {
      for (final k in [FetchFailureKind.network, FetchFailureKind.abandoned]) {
        final v = fetch(FetchFailureInfo(kind: k));
        expectCard(v, ChatCardKind.network, ChatCardAction.retry);
        expect(v.host, 'api.example.com');
      }
    });

    test('blockedHost and notConsented have no button', () {
      for (final k in [
        FetchFailureKind.blockedHost,
        FetchFailureKind.notConsented,
      ]) {
        final v = fetch(FetchFailureInfo(kind: k));
        expectCard(v, ChatCardKind.hostNotAllowed, ChatCardAction.none);
        expect(v.host, 'api.example.com');
      }
    });

    test('rateLimited uses its retryAfter', () {
      final v = fetch(
        const FetchFailureInfo(
          kind: FetchFailureKind.rateLimited,
          retryAfter: Duration(seconds: 45),
        ),
      );
      expectCard(v, ChatCardKind.rateLimited, ChatCardAction.retry);
      expect(v.retryAt, now.add(const Duration(seconds: 45)));
    });

    test('invalidRequest is too_large only when the body was refused', () {
      final big = fetch(
        const FetchFailureInfo(
          kind: FetchFailureKind.invalidRequest,
          message: 'the request body is larger than 1 MiB',
        ),
      );
      expectCard(big, ChatCardKind.tooLarge, ChatCardAction.none);
      final other = fetch(
        const FetchFailureInfo(
          kind: FetchFailureKind.invalidRequest,
          message: 'too many requests',
        ),
      );
      expect(other.card, ChatCardKind.badRequest);
    });

    test('invalidResponse is generic', () {
      final v = fetch(
        const FetchFailureInfo(kind: FetchFailureKind.invalidResponse),
      );
      expectCard(v, ChatCardKind.badRequest, ChatCardAction.retry);
    });
  });

  test('RunPaused shows the countdown card', () {
    final until = now.add(const Duration(seconds: 42));
    final v = map(RunPaused(until));
    expectCard(v, ChatCardKind.rateLimited, ChatCardAction.retry);
    expect(v.retryAt, until);
  });

  group('RunBusy', () {
    test('RunBusy text names the previous turn', () {
      final v = map(const RunBusy());
      expectCard(v, ChatCardKind.previousTurnBusy, ChatCardAction.retry);
    });

    test('third RunBusy shows the restart text with Thử lại', () {
      final v = map(const RunBusy(), ctx(busyInARow: 3));
      expectCard(v, ChatCardKind.previousTurnStuck, ChatCardAction.retry);
    });

    test('a busy answer while a stream is active is never stuck', () {
      final v = map(const RunBusy(), ctx(busyInARow: 5, streamActive: true));
      expect(v.card, ChatCardKind.previousTurnBusy);
    });
  });

  test('RunNeedsConfig blocks before send and lists the titles', () {
    final v = map(const RunNeedsConfig(['Base URL', 'Region']));
    expectCard(
      v,
      ChatCardKind.needsConfig,
      ChatCardAction.openPluginSettings,
      end: ChatMessageEnd.blocked,
    );
    expect(v.titles, ['Base URL', 'Region']);
  });

  group('RunUnavailable', () {
    test('notInstalled is blocked: plugin removed, choose another', () {
      expectCard(
        map(const RunUnavailable(RunUnavailableReason.notInstalled)),
        ChatCardKind.pluginRemoved,
        ChatCardAction.choosePlugin,
        end: ChatMessageEnd.blocked,
      );
    });

    test('packageUnreadable and noScript: plugin broken, open it', () {
      for (final r in [
        RunUnavailableReason.packageUnreadable,
        RunUnavailableReason.noScript,
      ]) {
        expectCard(
          map(RunUnavailable(r)),
          ChatCardKind.pluginBroken,
          ChatCardAction.openPlugin,
        );
      }
    });
  });

  group('RunCancelled', () {
    test('caller stops, text kept, no button', () {
      final v = map(const RunCancelled(RunCancelReason.caller));
      expectCard(
        v,
        ChatCardKind.stopped,
        ChatCardAction.none,
        end: ChatMessageEnd.stopped,
      );
      expect(v.keepStreamedText, isTrue);
    });

    test('pluginChanged with the row alive offers retry', () {
      expectCard(
        map(const RunCancelled(RunCancelReason.pluginChanged)),
        ChatCardKind.pluginUpdated,
        ChatCardAction.retry,
        end: ChatMessageEnd.stopped,
      );
    });

    test('pluginChanged with removed row shows Plugin đã gỡ', () {
      final v = map(
        const RunCancelled(RunCancelReason.pluginChanged),
        ctx(pluginRowExists: false),
      );
      expectCard(
        v,
        ChatCardKind.pluginRemoved,
        ChatCardAction.choosePlugin,
        end: ChatMessageEnd.stopped,
      );
      expect(v.keepStreamedText, isTrue);
    });
  });

  group('RunFailed', () {
    test('timeout stops with a retry', () {
      expectCard(
        map(const RunFailed(RunFailReason.timeout)),
        ChatCardKind.timeout,
        ChatCardAction.retry,
        end: ChatMessageEnd.stopped,
      );
    });

    test('memory, stack, outputTooLarge, internal → plugin error', () {
      for (final r in [
        RunFailReason.memory,
        RunFailReason.stack,
        RunFailReason.outputTooLarge,
        RunFailReason.internal,
      ]) {
        final v = map(RunFailed(r));
        expectCard(v, ChatCardKind.pluginError, ChatCardAction.retry);
        expect(v.keepStreamedText, isTrue);
      }
    });

    test('a timeout with a failing fetch keeps the stopped state', () {
      final v = map(
        const RunFailed(RunFailReason.timeout, fetchFailure: netFailure),
      );
      expectCard(
        v,
        ChatCardKind.network,
        ChatCardAction.retry,
        end: ChatMessageEnd.stopped,
      );
    });
  });

  test('app closed mid-turn maps to the cut-off card', () {
    const v = ChatOutcomeView.interrupted();
    expectCard(
      v,
      ChatCardKind.interrupted,
      ChatCardAction.retry,
      end: ChatMessageEnd.stopped,
    );
    expect(v.keepStreamedText, isTrue);
  });
}
