import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/ui/tool_card.dart';
import 'package:material_ui/material_ui.dart';

import 'support/chat_ui_support.dart';

Future<void> _pump(
  WidgetTester tester,
  AiMessage message, {
  bool disableAnimations = false,
}) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: Scaffold(body: ToolCard(message: message)),
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
    // One row per song.
    expect(
      find.textContaining('215 | Noi nay co anh | Son Tung'),
      findsOneWidget,
    );

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
}
