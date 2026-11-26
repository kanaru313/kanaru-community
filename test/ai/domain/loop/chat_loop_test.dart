import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/chat_loop.dart';
import 'package:kanaru/src/ai/domain/loop/loop_ports.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';

final _now = DateTime(2026, 11, 27, 12);
const _tools = ChatCapabilities(tools: true);
const _plain = ChatCapabilities();

int _seq = 0;

AiMessage _row(
  AiMessageRole role,
  AiMessageState state, {
  List<AiPart> parts = const [],
  DateTime? createdAt,
}) {
  _seq++;
  return AiMessage(
    id: _seq,
    conversationId: 1,
    seq: _seq,
    role: role,
    parts: parts,
    state: state,
    createdAt: createdAt ?? _now,
  );
}

ToolCallPart _call(String id) =>
    ToolCallPart.parsed(id: id, name: 'read_a', args: const {});

/// An assistant row (with calls) and one tool row per call state.
List<AiMessage> _round(
  List<AiMessageState> cards, {
  AiMessageState assistant = AiMessageState.complete,
  DateTime? createdAt,
}) {
  final calls = [for (var i = 0; i < cards.length; i++) _call('c${_seq}_$i')];
  return [
    _row(
      AiMessageRole.assistant,
      assistant,
      parts: [const TextPart('t'), ...calls],
    ),
    for (var i = 0; i < cards.length; i++)
      _row(
        AiMessageRole.tool,
        cards[i],
        parts: [calls[i]],
        createdAt: createdAt,
      ),
  ];
}

LoopAction _next(
  List<AiMessage> rows, {
  bool armed = true,
  ChatCapabilities caps = _tools,
  LoopSettings settings = const LoopSettings(),
}) => const ChatLoop().next(
  LoopTranscript(turnId: 1, rows: rows),
  settings,
  caps,
  armed: armed,
  now: _now,
);

void main() {
  const done = AiMessageState.done;
  const allowed = AiMessageState.allowed;
  const pending = AiMessageState.pending;

  setUp(() => _seq = 10);

  group('a model round', () {
    test('starts for a fresh turn only when armed', () {
      expect(_next([]), isA<RunModel>().having((a) => a.round, 'round', 1));
      expect(
        _next([], armed: false),
        isA<NeedsUserTap>().having(
          (a) => a.reason,
          'reason',
          TapReason.modelRound,
        ),
      );
    });

    test('a reply without calls ends the turn', () {
      expect(
        _next([_row(AiMessageRole.assistant, AiMessageState.complete)]),
        isA<Done>(),
      );
    });

    test('model without tools: one reply, then done', () {
      final rows = [_row(AiMessageRole.assistant, AiMessageState.complete)];
      expect(_next(rows, caps: _plain), isA<Done>());
    });

    test('after resolved calls the next round starts', () {
      final a = _next([
        ..._round([done, done]),
      ]);
      expect(a, isA<RunModel>().having((r) => r.round, 'round', 2));
      expect((a as RunModel).finalRound, isFalse);
    });

    test('round seven is the final round, then the turn is done', () {
      final rows = [
        for (var i = 0; i < 6; i++) ..._round([done]),
      ];
      final a = _next(rows) as RunModel;
      expect(a.round, 7);
      expect(a.finalRound, isTrue);
      rows.addAll(_round([AiMessageState.skipped]));
      expect(_next(rows), isA<Done>());
    });

    test('a model without tools never gets a final-round flag', () {
      final rows = [
        for (var i = 0; i < 6; i++) ..._round([done]),
      ];
      expect((_next(rows, caps: _plain) as RunModel).finalRound, isFalse);
    });

    test('the round limit follows the settings', () {
      final rows = [
        ..._round([done]),
        ..._round([done]),
      ];
      final a = _next(rows, settings: const LoopSettings(maxRounds: 2));
      expect((a as RunModel).finalRound, isTrue);
    });
  });

  group('cards', () {
    test('pending cards wait for the user, even when armed', () {
      final rows = _round([pending, allowed, pending]);
      final a = _next(rows);
      expect(a, isA<AwaitConfirms>());
      expect((a as AwaitConfirms).cardIds, [rows[1].id, rows[3].id]);
    });

    test('allowed calls run in the model order once nothing is pending', () {
      final rows = _round([allowed, done, allowed]);
      final a = _next(rows) as RunTools;
      expect(a.cards.map((c) => c.id), [rows[1].id, rows[3].id]);
    });

    test('allowed calls wait for a tap when not armed', () {
      expect(
        _next(_round([allowed]), armed: false),
        isA<NeedsUserTap>().having(
          (a) => a.reason,
          'reason',
          TapReason.toolsWaiting,
        ),
      );
    });

    test('pending cards older than 24 h expire', () {
      final rows = _round([
        pending,
      ], createdAt: _now.subtract(const Duration(hours: 24)));
      expect(_next(rows), isA<ExpireCards>());
      final fresh = _round([
        pending,
      ], createdAt: _now.subtract(const Duration(hours: 23)));
      expect(_next(fresh), isA<AwaitConfirms>());
    });

    test('a call still running without an owner is not restarted', () {
      expect(
        _next(_round([AiMessageState.running])),
        isA<NeedsUserTap>().having(
          (a) => a.reason,
          'reason',
          TapReason.strayRunning,
        ),
      );
    });

    test('unknown and failed calls count as resolved', () {
      final a = _next(_round([AiMessageState.unknown, AiMessageState.error]));
      expect(a, isA<RunModel>());
    });
  });

  group('failures', () {
    for (final state in [AiMessageState.error, AiMessageState.stopped]) {
      test('${state.name} round: retry runs the same round again', () {
        final rows = [
          ..._round([done]),
          _row(AiMessageRole.assistant, state),
        ];
        final a = _next(rows) as RunModel;
        expect(a.round, 2);
        expect(_next(rows, armed: false), isA<NeedsUserTap>());
      });
    }

    test('a message still streaming with no owner needs a tap', () {
      final rows = [_row(AiMessageRole.assistant, AiMessageState.streaming)];
      expect(
        _next(rows),
        isA<NeedsUserTap>().having(
          (a) => a.reason,
          'reason',
          TapReason.strayStreaming,
        ),
      );
    });

    test('event rows are ignored', () {
      final rows = [
        _row(AiMessageRole.event, AiMessageState.complete),
        _row(AiMessageRole.assistant, AiMessageState.complete),
      ];
      expect(_next(rows), isA<Done>());
    });
  });
}
