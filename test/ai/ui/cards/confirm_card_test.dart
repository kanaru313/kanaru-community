import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart' show KCappedList;
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';
import 'package:kanaru/src/ai/domain/loop/driver_results.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';

import '../../../support/kanaru_ui_finders.dart';
import 'card_harness.dart';

final _call = writeCall('create_playlist', {
  'name': 'Giống Lạc trôi',
  'trackIds': [100, 101, 102, 103, 104, 105],
});

AiMessage _row({
  AiMessageState state = AiMessageState.pending,
  ConfirmStatus status = ConfirmStatus.pending,
}) => toolRow(
  2,
  state: state,
  parts: [
    _call,
    ConfirmPart(callId: _call.id, status: status),
  ],
);

ToolPreview _preview(int songs) =>
    ToolPreview(summary: 'Giống Lạc trôi', tracks: songsOf(songs));

List<String> _answers(CardSetup setup) => [
  for (final c in setup.session.calls)
    if (c.startsWith('allow') || c.startsWith('deny')) c,
];

void main() {
  testWidgets('shows the action, what it needs and both answers', (
    tester,
  ) async {
    await pumpCard(tester, _row(), preview: _preview(6));
    expect(find.text('Tạo playlist “Giống Lạc trôi” · 6 bài'), findsOneWidget);
    expect(find.text('Tạo playlist · cần bạn cho phép'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
    expect(find.text('Cho phép'), findsOneWidget);
    // The six songs are listed in full.
    for (var i = 0; i < 6; i++) {
      expect(find.text('Bài $i'), findsOneWidget);
    }
  });

  testWidgets('without a preview the card still names the call', (
    tester,
  ) async {
    await pumpCard(tester, _row());
    expect(find.text('Tạo playlist “Giống Lạc trôi” · 6 bài'), findsOneWidget);
    expect(find.text('Bài 0'), findsNothing);
    expect(find.text('Cho phép'), findsOneWidget);
  });

  testWidgets('Allow calls controller once on double tap', (tester) async {
    final setup = await pumpCard(tester, _row(), preview: _preview(6));
    setup.session.cardAnswerGate = Completer<void>();
    await tester.tap(find.text('Cho phép'));
    await tester.tap(find.text('Cho phép'));
    // Declining meanwhile is the same answer, not a second one.
    await tester.tap(find.text('Từ chối'));
    await tester.pump();
    setup.session.cardAnswerGate!.complete();
    await settle(tester);
    expect(_answers(setup), ['allow t1-r1-1']);
  });

  testWidgets('Deny calls controller once on double tap', (tester) async {
    final setup = await pumpCard(tester, _row(), preview: _preview(6));
    setup.session.cardAnswerGate = Completer<void>();
    await tester.tap(find.text('Từ chối'));
    await tester.tap(find.text('Từ chối'));
    await tester.pump();
    setup.session.cardAnswerGate!.complete();
    await settle(tester);
    expect(_answers(setup), ['deny t1-r1-1']);
  });

  testWidgets('a refused answer leaves the card ready for another try', (
    tester,
  ) async {
    final setup = await pumpCard(tester, _row(), preview: _preview(6));
    setup.session.cardAnswer = CardAnswer.notPending;
    await tester.tap(find.text('Cho phép'));
    await settle(tester);
    await tester.tap(find.text('Cho phép'));
    await settle(tester);
    expect(_answers(setup), ['allow t1-r1-1', 'allow t1-r1-1']);
  });

  testWidgets('an allowed card waits without buttons', (tester) async {
    await pumpCard(
      tester,
      _row(state: AiMessageState.allowed, status: ConfirmStatus.allowed),
      preview: _preview(6),
    );
    expect(find.text('Bạn đã cho phép · Tạo playlist'), findsOneWidget);
    expectNoButtons();
  });

  testWidgets('a card of an older turn has no buttons', (tester) async {
    final card = _row();
    await pumpCard(tester, card, messages: [card, userRow(3)]);
    expect(find.text('Tạo playlist “Giống Lạc trôi” · 6 bài'), findsOneWidget);
    expectNoButtons();
  });

  testWidgets('track list shows 5 rows then +N', (tester) async {
    await pumpCard(tester, _row(), preview: _preview(12));
    for (var i = 0; i < 5; i++) {
      expect(find.text('Bài $i'), findsOneWidget);
    }
    expect(find.text('Bài 5'), findsNothing);
    expect(find.text('+7 bài'), findsOneWidget);
    await tester.tap(find.text('+7 bài'));
    await settle(tester);
    expect(find.text('+7 bài'), findsNothing);
    // Twelve rows: a box eight rows tall, rows built as they scroll in.
    expect(find.text('Bài 7'), findsOneWidget);
    expect(find.text('Bài 11'), findsNothing);
    expect(cappedBottomFade, findsOneWidget);
    await tester.drag(find.byType(KCappedList), const Offset(0, -2000));
    await settle(tester);
    expect(find.text('Bài 11'), findsOneWidget);
    expect(cappedBottomFade, findsNothing);
    expect(cappedTopFade, findsOneWidget);
  });

  testWidgets('eight songs opened show whole, no box', (tester) async {
    await pumpCard(tester, _row(), preview: _preview(8));
    await tester.tap(find.text('+3 bài'));
    await settle(tester);
    expect(cappedBottomFade, findsNothing);
    expect(cappedTopFade, findsNothing);
    expect(find.text('Bài 7'), findsOneWidget);
  });

  testWidgets('six songs show all of them, no +N', (tester) async {
    await pumpCard(tester, _row(), preview: _preview(6));
    expect(find.text('Bài 5'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('the two buttons share the row', (tester) async {
    await pumpCard(tester, _row(), preview: _preview(2));
    final deny = tester.getRect(find.text('Từ chối'));
    final allow = tester.getRect(find.text('Cho phép'));
    expect(deny.top, allow.top);
    expect(deny.right, lessThan(allow.left));
  });

  testWidgets('denied by new message shows the title without buttons', (
    tester,
  ) async {
    final skipped = toolRow(
      2,
      state: AiMessageState.skipped,
      parts: [
        _call,
        ConfirmPart(callId: _call.id, status: ConfirmStatus.deniedByNewMessage),
        errorResult(_call, newMessageText),
      ],
    );
    await pumpCard(tester, skipped);
    expect(find.text('Đã từ chối (bạn đã gửi tin khác)'), findsOneWidget);
    expect(
      find.text('Tạo playlist “Giống Lạc trôi” · 6 bài · không có gì thay đổi'),
      findsOneWidget,
    );
    expect(find.text('Cho phép'), findsNothing);
    expectNoButtons();
  });

  testWidgets('one-button cards put the button at the end', (tester) async {
    final queue = writeCall('queue_tracks', {
      'trackIds': [1, 2, 3],
    });
    final done = toolRow(
      2,
      state: AiMessageState.done,
      parts: [
        queue,
        const ToolResultPart(
          id: 't1-r1-1',
          name: 'queue_tracks',
          content: [TextPart('{"queued":3}')],
        ),
        DonePart(callId: queue.id, added: songsOf(3)),
      ],
    );
    await pumpCard(tester, done);
    expect(find.text('Mở hàng đợi'), findsOneWidget);
    expectButtonAtEnd(tester, 'Mở hàng đợi');
  });
}
