import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../support/icon_button_finders.dart';
import 'support/chat_list_harness.dart';
import 'support/chat_ui_support.dart';

AiMessage _user(int id, String text) =>
    chatMessage(id, role: AiMessageRole.user, parts: [TextPart(text)]);

AiMessage _answer(
  int id,
  String text, {
  AiMessageState state = AiMessageState.complete,
}) => chatMessage(
  id,
  parts: [TextPart(text)],
  state: state,
  model: 'claude-sonnet-4-5',
);

/// A conversation long enough to scroll: [pairs] user/answer pairs.
List<AiMessage> _long(int pairs) => [
  for (var i = 0; i < pairs; i++) ...[
    _user(i * 2 + 1, 'question $i'),
    _answer(i * 2 + 2, 'answer $i\n\nmore of answer $i\n\nand more $i'),
  ],
];

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

/// The first user message in view: its text and where it sits.
({String text, double top}) _firstVisible(WidgetTester tester) {
  final finder = find.textContaining('question').first;
  final text = tester.widget<Text>(finder).data!;
  return (text: text, top: tester.getTopLeft(finder).dy);
}

void main() {
  group('scrolling', () {
    testWidgets('streaming does not move a scrolled-up reader', (tester) async {
      final setup = await pumpChatList(tester);
      await setup.setMessages(tester, [
        ..._long(20),
        _answer(900, 'start', state: AiMessageState.streaming),
      ]);
      setup.session.setTurn(TurnState.streaming);
      final live = setup.container.read(fakeLiveTextProvider.notifier);
      live.set('start');
      await tester.pump();
      // Well over a screen above the end.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pump();
      final before = _firstVisible(tester);
      final pixels = _position(tester).pixels;

      for (var i = 0; i < 5; i++) {
        live.set(
          'start${'\n\nanother paragraph of streamed text' * (i + 1) * 4}',
        );
        await tester.pump();
        await tester.pump();
      }
      expect(_position(tester).pixels, pixels);
      expect(
        tester.getTopLeft(find.text(before.text)).dy,
        before.top,
        reason: 'the message under the reader stayed where it was',
      );
    });

    testWidgets('at bottom it follows new text', (tester) async {
      final setup = await pumpChatList(tester);
      await setup.setMessages(tester, [
        ..._long(20),
        _answer(900, 'start', state: AiMessageState.streaming),
      ]);
      setup.session.setTurn(TurnState.streaming);
      final live = setup.container.read(fakeLiveTextProvider.notifier);
      live.set('start');
      await tester.pump();
      await tester.pump();
      expect(_position(tester).pixels, _position(tester).maxScrollExtent);

      live.set('start${'\n\nanother paragraph of streamed text' * 30}');
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      final p = _position(tester);
      expect(p.maxScrollExtent, greaterThan(0));
      expect(p.pixels, p.maxScrollExtent);
    });

    testWidgets('open 1000-message conversation reads one page', (
      tester,
    ) async {
      final setup = await pumpChatList(tester);
      // The store answers with the newest page only; 950 older ones exist.
      await setup.setMessages(tester, _long(25), hasMore: true);
      expect(setup.data.olderRequests, 0);
      // Reading the newest page does not reach for the older ones.
      expect(find.text('and more 24', findRichText: true), findsOneWidget);
      expect(find.text('question 0'), findsNothing);

      _position(tester).jumpTo(_position(tester).minScrollExtent);
      await tester.pump();
      await tester.pump();
      expect(setup.data.olderRequests, 1);
    });
  });

  group('messages', () {
    testWidgets('dots only while streaming, static with disableAnimations', (
      tester,
    ) async {
      final setup = await pumpChatList(tester, disableAnimations: true);
      await setup.setMessages(tester, [
        _user(1, 'hi'),
        _answer(2, 'partial', state: AiMessageState.streaming),
      ]);
      expect(find.byType(KStreamingDots), findsNothing);
      setup.session.setTurn(TurnState.streaming);
      await tester.pump();
      expect(find.byType(KStreamingDots), findsOneWidget);
      // No ticker runs: settling returns at once.
      await tester.pumpAndSettle();

      await setup.setMessages(tester, [_user(1, 'hi'), _answer(2, 'partial')]);
      setup.session.setTurn(TurnState.idle);
      await tester.pump();
      expect(find.byType(KStreamingDots), findsNothing);
    });

    testWidgets('stop shows Stopped and keeps the text', (tester) async {
      final setup = await pumpChatList(tester);
      await setup.setMessages(tester, [
        _user(1, 'hi'),
        _answer(2, 'received so far', state: AiMessageState.stopped),
      ]);
      expect(find.text('received so far', findRichText: true), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('time expands on tap', (tester) async {
      final setup = await pumpChatList(tester, size: const Size(400, 800));
      await setup.setMessages(tester, [_user(1, 'hi'), _answer(2, 'hello')]);
      expect(find.text('14:32'), findsNWidgets(2));
      await tester.tap(find.text('14:32').last);
      await tester.pump();
      expect(find.text('14:32 · 27/11/2026'), findsOneWidget);
      await tester.tap(find.text('14:32 · 27/11/2026'));
      await tester.pump();
      expect(find.text('14:32 · 27/11/2026'), findsNothing);
    });

    testWidgets('the footer names the model after the time', (tester) async {
      final setup = await pumpChatList(tester);
      await setup.setMessages(tester, [_user(1, 'hi'), _answer(2, 'hello')]);
      expect(find.text('claude-sonnet-4-5'), findsOneWidget);
    });

    testWidgets('copy puts text on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final setup = await pumpChatList(tester);
      await setup.setMessages(tester, [
        _user(1, 'my question'),
        _answer(2, 'the answer'),
      ]);
      await tester.tap(byIconButton('Copy').first);
      await tester.pump();
      expect(copied, 'my question');
      await tester.tap(byIconButton('Copy').last);
      await tester.pump();
      expect(copied, 'the answer');
    });

    testWidgets('plugin switch divider shown', (tester) async {
      final setup = await pumpChatList(tester);
      await setup.setMessages(tester, [
        _user(1, 'hi'),
        _answer(2, 'hello'),
        chatMessage(
          3,
          role: AiMessageRole.event,
          parts: const [
            EventPart.pluginSwitch(fromName: 'Claude', toName: 'Gemini'),
          ],
        ),
        _user(4, 'again'),
        chatMessage(
          5,
          parts: [const TextPart('ok')],
          model: 'gemini-2.5-flash',
        ),
      ]);
      expect(
        find.text('From here on: Gemini · gemini-2.5-flash'),
        findsOneWidget,
      );
    });

    testWidgets('a failed read shows a notice with a retry, not a blank body', (
      tester,
    ) async {
      await pumpChatList(tester, failMessages: true);
      expect(find.text('Could not load this conversation.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
