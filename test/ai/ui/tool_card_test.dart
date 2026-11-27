import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/ui/tool_card.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart'
    show trackRowLoaderProvider;
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/chat_ui_support.dart';
import '../../support/kanaru_ui_finders.dart';

Future<void> _pump(
  WidgetTester tester,
  AiMessage message, {
  bool disableAnimations = false,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [trackRowLoaderProvider.overrideWithValue((ids) async => [])],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: ToolCard(message: message)),
      ),
    ),
  ),
);

AiMessage _tool({
  required AiMessageState state,
  bool result = true,
}) => chatMessage(
  1,
  role: AiMessageRole.tool,
  state: state,
  parts: [
    ToolCallPart.parsed(
      id: 'c1',
      name: 'search_library',
      args: const {'genre': 'V-Pop', 'limit': 50},
    ),
    if (result)
      const ToolResultPart(
        id: 'c1',
        name: 'search_library',
        content: [
          TextPart(
            '{"total":1284,"items":["215|Noi nay co anh|Son Tung","216|B|C"]}',
          ),
        ],
      ),
  ],
);

void main() {
  testWidgets('folded by default, opens to the arguments and the result', (
    tester,
  ) async {
    await _pump(tester, _tool(state: AiMessageState.done));
    expect(find.text('Search the library'), findsOneWidget);
    expect(
      find.text('2 / 1,284 songs · the AI can look further'),
      findsOneWidget,
    );
    expect(find.text('Parameters'), findsNothing);
    expect(find.text('Result'), findsNothing);

    await tester.tap(find.text('Search the library'));
    await tester.pumpAndSettle();
    expect(find.text('Parameters'), findsOneWidget);
    expect(find.textContaining('"genre": "V-Pop"'), findsOneWidget);
    // A compact song row each: title and artist, no id and no pipe table.
    expect(find.text('Noi nay co anh'), findsOneWidget);
    expect(find.text('Son Tung'), findsOneWidget);
    expect(find.textContaining('215'), findsNothing);
    expect(find.textContaining(' | '), findsNothing);
    expect(cappedBottomFade, findsNothing);

    await tester.tap(find.text('Search the library'));
    await tester.pumpAndSettle();
    expect(find.text('Parameters'), findsNothing);
  });

  testWidgets('running state shows the running title instead of the name', (
    tester,
  ) async {
    await _pump(tester, _tool(state: AiMessageState.running, result: false));
    expect(find.text('Running: Search the library'), findsOneWidget);
    expect(find.text('Search the library'), findsNothing);
  });

  testWidgets('with animations off a running card holds still', (tester) async {
    await _pump(
      tester,
      _tool(state: AiMessageState.running, result: false),
      disableAnimations: true,
    );
    // A spinner that keeps animating would never settle.
    await tester.pumpAndSettle();
    expect(find.text('Running: Search the library'), findsOneWidget);
  });

  group('long results', () {
    AiMessage tool(String name, String json) => chatMessage(
      1,
      role: AiMessageRole.tool,
      state: AiMessageState.done,
      parts: [
        ToolCallPart.parsed(id: 'c1', name: name, args: const {}),
        ToolResultPart(id: 'c1', name: name, content: [TextPart(json)]),
      ],
    );

    String songs(int n) =>
        '{"total":$n,"items":[${[for (var i = 1; i <= n; i++) '"$i|Song $i|Artist $i|Album|2020"'].join(',')}]}';

    Future<void> open(WidgetTester tester, AiMessage m, String name) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, m);
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    testWidgets('1000 songs: all rows, 8 built at a time, own scroll', (
      tester,
    ) async {
      await open(
        tester,
        tool('search_library', songs(1000)),
        'Search the library',
      );
      expect(find.textContaining('Song '), findsAtLeast(8));
      expect(
        tester.widgetList(find.textContaining('Song ')).length,
        lessThan(15),
      );
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 100'), findsNothing);
      expect(cappedBottomFade, findsOneWidget);
      expect(cappedTopFade, findsNothing);
      // No cap of 30: scrolling reaches the last row.
      final list = find.descendant(
        of: find.byType(KCappedList),
        matching: find.byType(ListView),
      );
      await tester.drag(list, const Offset(0, -100000));
      await tester.pumpAndSettle();
      expect(cappedTopFade, findsOneWidget);
    });

    testWidgets('8 songs show whole, no box', (tester) async {
      await open(
        tester,
        tool('search_library', songs(8)),
        'Search the library',
      );
      expect(find.byType(ListView), findsNothing);
      expect(find.text('Song 8'), findsOneWidget);
      expect(cappedBottomFade, findsNothing);
    });

    testWidgets('queue rows read the song from the id / title cells', (
      tester,
    ) async {
      await open(
        tester,
        tool(
          'get_queue',
          '{"total":2,"items":["7|42|Title A|Band|Alb|2019","8||(unavailable)"]}',
        ),
        'Queue',
      );
      expect(find.text('Title A'), findsOneWidget);
      expect(find.text('(unavailable)'), findsOneWidget);
      expect(find.textContaining('|'), findsNothing);
    });

    testWidgets('a list that is not songs stays text lines, same cap', (
      tester,
    ) async {
      final rows = [for (var i = 1; i <= 20; i++) '"$i|Playlist $i|3"'];
      await open(
        tester,
        tool('list_playlists', '{"total":20,"items":[${rows.join(',')}]}'),
        'List playlists',
      );
      expect(find.text('1 | Playlist 1 | 3'), findsOneWidget);
      expect(find.text('20 | Playlist 20 | 3'), findsNothing);
      expect(cappedBottomFade, findsOneWidget);
    });
  });
}
