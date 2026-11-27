import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';
import 'package:kanaru/src/ai/state/chat_view/message_view.dart';
import 'package:kanaru/src/ai/state/chat_view/card_view.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/chat_list_harness.dart';
import '../support/chat_ui_support.dart';
import 'card_harness.dart';

const _vi = Locale('vi');

AiMessage _tool(
  int id,
  AiMessageState state,
  ToolCallPart call, [
  List<AiPart> more = const [],
]) => chatMessage(
  id,
  role: AiMessageRole.tool,
  state: state,
  parts: [call, ...more],
);

void main() {
  group('which rows are cards', () {
    test('a stopped round with a reason ends in a card, a plain stop not', () {
      final cut = chatMessage(
        2,
        state: AiMessageState.stopped,
        parts: const [ErrorPart(code: 'cutOffByClose', kind: 'closed')],
      );
      final plain = chatMessage(4, state: AiMessageState.stopped);
      final items = chatItemsOf([cut, plain]);
      expect(items.whereType<ChatCardItem>().map((i) => i.message.id), [2]);
    });

    test('a failed call is a tool card, the limit call is a card', () {
      final call = writeCall('search_library', {'query': 'x'});
      final failed = _tool(2, AiMessageState.error, call, [
        errorResult(call, 'tool failed'),
      ]);
      final limit = _tool(3, AiMessageState.error, call, [
        errorResult(call, 'limit reached'),
        const ErrorPart(code: limitReachedCode, kind: 'invalidResponse'),
      ]);
      final items = chatItemsOf([failed, limit]);
      expect(items.whereType<ChatToolItem>().map((i) => i.message.id), [2]);
      expect(items.whereType<ChatCardItem>().map((i) => i.message.id), [3]);
    });

    test('the edges of a conversation: newest user message and newest row', () {
      final edges = turnEdgesOf([
        chatMessage(1, role: AiMessageRole.user),
        chatMessage(2),
        chatMessage(3, role: AiMessageRole.user),
        chatMessage(4),
      ]);
      expect(edges.latestUserSeq, 3);
      expect(edges.newestSeq, 4);
      expect(turnEdgesOf(const []).latestUserSeq, -1);
    });

    test('an event row (plugin switch line) is not a newer turn', () {
      final edges = turnEdgesOf([
        chatMessage(1, role: AiMessageRole.user),
        chatMessage(2),
        chatMessage(3, role: AiMessageRole.event),
      ]);
      expect(edges.newestSeq, 2);
      expect(edges.latestUserSeq, 1);
      final after = turnEdgesOf([
        chatMessage(1, role: AiMessageRole.user),
        chatMessage(2),
        chatMessage(3, role: AiMessageRole.event),
        chatMessage(4),
      ]);
      expect(after.newestSeq, 4);
    });
  });

  group('in the message list', () {
    testWidgets('cut off when closing the app: unknown result, text kept, '
        'Đã dừng, then Thử lại', (tester) async {
      final setup = await pumpChatList(tester, locale: _vi);
      final queue = writeCall('queue_tracks', {
        'trackIds': [1, 2, 3, 4, 5, 6],
      });
      await setup.setMessages(tester, [
        chatMessage(
          1,
          role: AiMessageRole.user,
          parts: const [TextPart('Thêm vài bài giống Lạc trôi')],
        ),
        _tool(2, AiMessageState.unknown, queue),
        AiMessage(
          id: 3,
          conversationId: 1,
          seq: 3,
          role: AiMessageRole.assistant,
          parts: const [
            TextPart('Mình đã chọn 6 bài cùng chất V-Pop điện tử.'),
            ErrorPart(code: 'cutOffByClose', kind: 'closed'),
          ],
          state: AiMessageState.stopped,
          createdAt: DateTime(2026, 11, 27, 22, 41),
          installId: cardPluginId,
          model: 'claude-sonnet-4-5',
        ),
      ]);
      expect(
        find.text('Không rõ kết quả: thêm 6 bài vào hàng đợi'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mình đã chọn 6 bài cùng chất V-Pop'),
        findsOneWidget,
      );
      expect(find.text('Đã dừng'), findsOneWidget);
      expect(find.text('Lượt trả lời bị ngắt khi đóng Kanaru'), findsOneWidget);
      // The unknown card has no button; the error card has the only one.
      expect(find.byType(KActionCard), findsNWidgets(2));
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(setup.session.calls, contains('retry'));
    });

    testWidgets('a confirmation of the latest turn answers, an old one does '
        'not', (tester) async {
      final setup = await pumpChatList(
        tester,
        locale: _vi,
        extra: [
          chatConfirmPreviewProvider.overrideWith((ref, c) async => null),
        ],
      );
      final call = writeCall('queue_tracks', {
        'trackIds': [1, 2],
      });
      final confirm = ConfirmPart(
        callId: call.id,
        status: ConfirmStatus.pending,
      );
      await setup.setMessages(tester, [
        chatMessage(1, role: AiMessageRole.user, parts: const [TextPart('a')]),
        _tool(2, AiMessageState.pending, call, [confirm]),
      ]);
      expect(find.text('Cho phép'), findsOneWidget);
      await tester.tap(find.text('Cho phép'));
      await tester.pump();
      expect(setup.session.calls, contains('allow ${call.id}'));

      // The user wrote again: the same card is history.
      await setup.setMessages(tester, [
        chatMessage(1, role: AiMessageRole.user, parts: const [TextPart('a')]),
        _tool(2, AiMessageState.pending, call, [confirm]),
        chatMessage(3, role: AiMessageRole.user, parts: const [TextPart('b')]),
      ]);
      expect(find.text('Cho phép'), findsNothing);
      expect(find.text('Từ chối'), findsNothing);
    });
  });
}
