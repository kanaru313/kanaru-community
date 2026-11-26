import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/state/ai_chat_stats_provider.dart';
import 'package:kanaru/src/screens/settings/ui/ai/ai_history_section.dart';
import 'package:kanaru_ui/kanaru_ui.dart' show buildKanaruTheme;
import 'package:kanaru/src/ai/data/conversation_rows.dart' show AiChatStats;
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:material_ui/material_ui.dart';

import 'ai_settings_host.dart';

/// A session that only counts the delete.
class _FakeSession extends ChatSessionController {
  _FakeSession(this._turn);

  final TurnState _turn;
  int deleted = 0;

  @override
  ChatSessionState build() => ChatSessionState(turnState: _turn);

  @override
  Future<void> deleteAll() async => deleted++;
}

Future<_FakeSession> _open(
  WidgetTester tester, {
  TurnState turn = TurnState.idle,
  Future<AiChatStats> Function()? stats,
}) async {
  final session = _FakeSession(turn);
  await openAiSettings(
    tester,
    stats: stats,
    overrides: [chatSessionProvider.overrideWith(() => session)],
  );
  return session;
}

Finder get _clearButton => find.widgetWithText(TextButton, 'Delete');

void main() {
  testWidgets('shows the count and size', (tester) async {
    await _open(tester);
    expect(find.text('3 conversations · 1.8 MB'), findsOneWidget);
    expect(find.text('Stored on this device'), findsOneWidget);
  });

  testWidgets('clear-all dialog text mentions logs, not images', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(_clearButton);
    await tester.pumpAndSettle();
    expect(find.text('Delete all conversations?'), findsOneWidget);
    expect(
      find.text(
        '3 AI conversations will be deleted from this device. The run logs of the AI services are deleted too. Prompt templates and settings stay.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cannot be undone.'), findsOneWidget);
    expect(find.textContaining('image', findRichText: true), findsNothing);
    expect(find.textContaining('in progress'), findsNothing);
  });

  testWidgets('active turn adds the stop sentence', (tester) async {
    await _open(tester, turn: TurnState.streaming);
    await tester.tap(_clearButton);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('The answer in progress will stop.'),
      findsOneWidget,
    );
  });

  testWidgets('confirm calls deleteAll', (tester) async {
    final session = await _open(tester);
    await tester.tap(_clearButton);
    await tester.pumpAndSettle();
    expect(session.deleted, 0);
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(session.deleted, 1);
    expect(find.text('All conversations deleted'), findsOneWidget);
  });

  testWidgets('cancel deletes nothing', (tester) async {
    final session = await _open(tester);
    await tester.tap(_clearButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(session.deleted, 0);
    expect(find.text('Delete all conversations?'), findsNothing);
  });

  testWidgets('disabled at zero', (tester) async {
    await _open(
      tester,
      stats: () async => const AiChatStats(conversations: 0, bytes: 0),
    );
    expect(find.text('No conversations yet'), findsOneWidget);
    expect(tester.widget<TextButton>(_clearButton).onPressed, isNull);
  });

  testWidgets('loading state: reading line, clear disabled', (tester) async {
    // The spinner never settles, so this one pumps the block alone.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatStatsProvider.overrideWith(
            (ref) => Completer<AiChatStats>().future,
          ),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: AiHistorySection()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Reading chat history…'), findsOneWidget);
    expect(tester.widget<TextButton>(_clearButton).onPressed, isNull);
  });

  testWidgets('error state: retry reads again, clear stays usable', (
    tester,
  ) async {
    var reads = 0;
    final session = await _open(
      tester,
      stats: () async {
        reads++;
        throw StateError('no store');
      },
    );
    expect(find.text('Could not read chat history'), findsOneWidget);
    expect(
      find.text(
        'The count and size are not available. Delete all still works.',
      ),
      findsOneWidget,
    );
    final first = reads;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(reads, greaterThan(first));

    await tester.tap(_clearButton);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Every AI conversation will be deleted'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(session.deleted, 1);
  });
}
