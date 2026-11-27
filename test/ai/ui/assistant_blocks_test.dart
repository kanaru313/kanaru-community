import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/ui/assistant_blocks.dart';
import 'package:kanaru/src/ai/ui/chat_markdown.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';
import '../../support/kanaru_ui_finders.dart';
import 'support/chat_list_harness.dart';
import 'support/chat_ui_support.dart';

Future<ValueNotifier<String>> _pumpBlocks(
  WidgetTester tester,
  String text, {
  bool streaming = true,
}) async {
  final notifier = ValueNotifier(text);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<String>(
            valueListenable: notifier,
            builder: (_, text, _) =>
                AssistantBlocks(text: text, streaming: streaming),
          ),
        ),
      ),
    ),
  );
  return notifier;
}

AiMessage _toolResult(int id, String name, String json) => chatMessage(
  id,
  role: AiMessageRole.tool,
  state: AiMessageState.done,
  parts: [
    ToolCallPart.parsed(id: 'c$id', name: name, args: const {}),
    ToolResultPart(id: 'c$id', name: name, content: [TextPart(json)]),
  ],
);

AiMessage _answer(int id, String text) =>
    chatMessage(id, parts: [TextPart(text)], model: 'm');

void main() {
  group('blocks', () {
    testWidgets('finished paragraphs are not rebuilt on a delta', (
      tester,
    ) async {
      final text = await _pumpBlocks(tester, 'one\n\ntwo\n\nthree\n\npart');
      final before = chatBlockBuilds;
      text.value = 'one\n\ntwo\n\nthree\n\npart of the last';
      await tester.pump();
      // Only the open paragraph was built again.
      expect(chatBlockBuilds - before, 1);
      expect(find.text('part of the last', findRichText: true), findsOneWidget);

      // A block that just closed is built once more, then settles.
      text.value = 'one\n\ntwo\n\nthree\n\npart of the last\n\nnext';
      await tester.pump();
      final settled = chatBlockBuilds;
      text.value = 'one\n\ntwo\n\nthree\n\npart of the last\n\nnext one';
      await tester.pump();
      expect(chatBlockBuilds - settled, 1);
    });

    testWidgets('a 200 KB answer rebuilds only its open block per delta', (
      tester,
    ) async {
      final paragraph = 'A paragraph of the answer with **bold** and `code`.';
      final big = StringBuffer();
      while (big.length < 190 * 1024) {
        big.write('$paragraph\n\n');
      }
      final text = await _pumpBlocks(tester, big.toString());
      var live = big.toString();
      final before = chatBlockBuilds;
      const deltas = 60;
      for (var i = 0; i < deltas; i++) {
        live = '$live more words of the last paragraph';
        text.value = live;
        await tester.pump();
      }
      // Work per delta does not follow the answer's length: one block (the
      // open paragraph) is built per delta, not the ~3 700 closed ones.
      expect(chatBlockBuilds - before, lessThanOrEqualTo(deltas));
    });

    testWidgets('links, images and raw HTML render as plain text', (
      tester,
    ) async {
      const lines = [
        '[a link](http://example.com)',
        '![an image](http://example.com/x.png)',
        '<https://example.com>',
        '<b>raw</b> <script>x()</script>',
      ];
      await _pumpBlocks(tester, lines.join('\n'), streaming: false);
      for (final l in lines) {
        expect(find.textContaining(l, findRichText: true), findsOneWidget);
      }
      // Nothing in the text answers a tap.
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('italics render as plain text without the markers', (
      tester,
    ) async {
      await _pumpBlocks(
        tester,
        'a *slanted* word and snake_case',
        streaming: false,
      );
      expect(
        find.text('a slanted word and snake_case', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('track rows', () {
    testWidgets(
      '[[t:ID]] from tool results becomes a track row, unknown id stays text',
      (tester) async {
        final setup = await pumpChatList(
          tester,
          library: {7: fakeTrack(7, title: 'Lac troi')},
        );
        await setup.setMessages(tester, [
          _toolResult(
            1,
            'search_library',
            '{"total":1,"items":["7|Lac troi|Son Tung|x|2017"]}',
          ),
          _answer(2, '[[t:7]]\n\n[[t:9031]]'),
        ]);
        expect(find.text('Lac troi'), findsOneWidget);
        expect(find.text('Son Tung'), findsOneWidget);
        expect(find.text('[[t:9031]]', findRichText: true), findsOneWidget);
        expect(find.text('[[t:7]]', findRichText: true), findsNothing);
      },
    );

    testWidgets('track refs as list items become track rows, unknown stays', (
      tester,
    ) async {
      final setup = await pumpChatList(
        tester,
        library: {7: fakeTrack(7, title: 'Lac troi')},
      );
      await setup.setMessages(tester, [
        _toolResult(
          1,
          'search_library',
          '{"total":1,"items":["7|Lac troi|Son Tung|x|2017"]}',
        ),
        _answer(2, '- [[t:7]]\n- [[t:9031]]\n1. [[t:7]]'),
      ]);
      expect(find.text('Lac troi'), findsNWidgets(2));
      expect(find.text('[[t:9031]]', findRichText: true), findsOneWidget);
      expect(find.text('[[t:7]]', findRichText: true), findsNothing);
    });

    testWidgets('an id only a plugin or a playlist list mentions stays text', (
      tester,
    ) async {
      final setup = await pumpChatList(tester, library: {7: fakeTrack(7)});
      await setup.setMessages(tester, [
        _toolResult(1, 'list_playlists', '{"items":["7|Chill|3"]}'),
        _answer(2, '[[t:7]]'),
      ]);
      expect(find.text('[[t:7]]', findRichText: true), findsOneWidget);
    });

    testWidgets('more than eight song lines in a row sit in one scrolling box', (
      tester,
    ) async {
      final setup = await pumpChatList(
        tester,
        library: {for (var i = 1; i <= 40; i++) i: fakeTrack(i, title: 'T$i')},
      );
      await setup.setMessages(tester, [
        _toolResult(
          1,
          'search_library',
          '{"items":[${[for (var i = 1; i <= 40; i++) '"$i|T$i|A"'].join(',')}]}',
        ),
        _answer(
          2,
          '${[for (var i = 1; i <= 40; i++) '[[t:$i]]'].join('\n')}\n\nafter',
        ),
      ]);
      expect(find.byType(KCappedList), findsOneWidget);
      // Lazy: the first rows are built, the rest wait for the scroll.
      expect(find.text('T1'), findsOneWidget);
      expect(find.text('T8'), findsOneWidget);
      expect(find.text('T30'), findsNothing);
      expect(cappedBottomFade, findsOneWidget);
      expect(find.text('after', findRichText: true), findsOneWidget);
    });

    testWidgets('eight song lines show whole, no box', (tester) async {
      final setup = await pumpChatList(
        tester,
        library: {for (var i = 1; i <= 8; i++) i: fakeTrack(i, title: 'T$i')},
      );
      await setup.setMessages(tester, [
        _toolResult(
          1,
          'search_library',
          '{"items":[${[for (var i = 1; i <= 8; i++) '"$i|T$i|A"'].join(',')}]}',
        ),
        _answer(2, [for (var i = 1; i <= 8; i++) '[[t:$i]]'].join('\n')),
      ]);
      expect(find.byType(KCappedList), findsNothing);
      expect(find.text('T8'), findsOneWidget);
    });

    testWidgets('track row tap plays, ⋮ opens the song menu', (tester) async {
      final setup = await pumpChatList(tester, library: {7: fakeTrack(7)});
      await setup.setMessages(tester, [
        _toolResult(1, 'search_library', '{"items":["7|Lac troi|Son Tung"]}'),
        _answer(2, '[[t:7]]'),
      ]);
      await tester.tap(find.text('Lac troi'));
      await tester.pump();
      expect(setup.tracks.calls, ['play 7']);
      await tester.tap(byIconButton('Song menu'));
      await tester.pump();
      expect(setup.tracks.calls, ['play 7', 'menu 7']);
    });

    testWidgets('on the phone a long press opens the menu and there is no ⋮', (
      tester,
    ) async {
      final setup = await pumpChatList(
        tester,
        size: const Size(400, 800),
        library: {7: fakeTrack(7)},
      );
      await setup.setMessages(tester, [
        _toolResult(1, 'search_library', '{"items":["7|Lac troi|Son Tung"]}'),
        _answer(2, '[[t:7]]'),
      ]);
      expect(byIconButton('Song menu'), findsNothing);
      await tester.longPress(find.text('Lac troi'));
      await tester.pump();
      expect(setup.tracks.calls, ['menu 7']);
    });
  });

  group('jump to end', () {
    testWidgets('appears when scrolled up and returns to the end', (
      tester,
    ) async {
      final setup = await pumpChatList(tester);
      await setup.setMessages(tester, [
        for (var i = 0; i < 30; i++) _answer(i + 1, 'answer $i'),
      ]);
      Finder jump() => find.byTooltip('Jump to the end');
      bool shown() =>
          tester
              .widget<AnimatedOpacity>(
                find.ancestor(
                  of: jump(),
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .opacity ==
          1;
      expect(shown(), isFalse);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(shown(), isTrue);

      await tester.tap(jump());
      await tester.pumpAndSettle();
      final p = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(p.pixels, p.maxScrollExtent);
      expect(shown(), isFalse);
      // KMotion is the only clock: nothing is left running.
      expect(KMotion.normal, isNotNull);
    });
  });
}
