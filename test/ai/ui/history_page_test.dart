import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_conversation.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/chat_view/chat_view_state.dart';
import 'package:kanaru/src/ai/state/chat_view/history_view.dart';
import 'package:kanaru/src/ai/ui/chat_host.dart';
import 'package:kanaru/src/ai/ui/history_page.dart';
import 'package:kanaru/src/ai/ui/history_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';
import 'support/chat_ui_support.dart';

/// A session whose delete waits for [deleteGate], and whose open stops a
/// running turn like the real controller does.
class _HistorySession extends FakeChatSession {
  Completer<void>? deleteGate;

  /// The store refuses the delete.
  bool failDelete = false;

  @override
  Future<void> delete(int id) async {
    await deleteGate?.future;
    if (failDelete) throw StateError('store refused');
    await super.delete(id);
  }

  @override
  Future<bool> open(int id) async {
    if (state.turnState == TurnState.streaming) calls.add('turn stopped');
    return super.open(id);
  }
}

class _Setup {
  _Setup(this.container, this.session);

  final ProviderContainer container;
  final _HistorySession session;

  ChatViewState get view => container.read(chatViewProvider);
}

DateTime _daysAgo(int days, {int hour = 9}) =>
    DateTime(2026, 11, 27 - days, hour, 5);

Future<_Setup> _pump(
  WidgetTester tester, {
  required List<AiConversation> conversations,
  _HistorySession? session,
  Size size = const Size(420, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final fake = session ?? _HistorySession();
  final container = ProviderContainer(
    overrides: [
      ...chatUiOverrides(session: fake),
      chatHostProvider.overrideWithValue(RecordingChatHost()),
    ],
  );
  addTearDown(container.dispose);
  container.read(fakeHistoryProvider.notifier).set(conversations);
  container.read(chatViewProvider.notifier).openHistory();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ChatHistoryPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Setup(container, fake);
}

/// The search and the rename boxes, told apart by their hint, so the finders
/// hold however many text fields the page shows.
Finder _byHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
  description: 'TextField with hint "$hint"',
);

Finder get _searchField => _byHint('Search conversations');
Finder get _renameField => _byHint('Conversation name');

SelectionRow _selection(WidgetTester tester, int id) => tester.widget(
  find.descendant(
    of: find.byKey(historyRowKey(id)),
    matching: find.byType(SelectionRow),
  ),
);

Future<void> _rowMenu(WidgetTester tester, String title, String entry) async {
  await tester.tap(byIconButton('Options for $title'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(entry).last);
  await tester.pumpAndSettle();
}

void main() {
  group('groups', () {
    // Day boundaries against "now" = 27 Nov 15:00: the whole calendar day is
    // today (even 00:05), the seven days before it are "Past 7 days", the
    // eighth day back is older.
    test('groups by day boundaries (fake clock)', () {
      final now = historyNow;
      final list = [
        historyConversation(1, 'late today', at: DateTime(2026, 11, 27, 23)),
        historyConversation(2, 'early today', at: DateTime(2026, 11, 27, 0, 5)),
        historyConversation(
          3,
          'last night',
          at: DateTime(2026, 11, 26, 23, 59),
        ),
        historyConversation(4, 'seven back', at: DateTime(2026, 11, 20, 0, 1)),
        historyConversation(
          5,
          'eight back',
          at: DateTime(2026, 11, 19, 23, 59),
        ),
        historyConversation(6, 'last year', at: DateTime(2025, 1, 2)),
      ];
      final sections = groupHistory(list, now);
      expect(
        [for (final s in sections) s.group],
        [HistoryGroup.today, HistoryGroup.week, HistoryGroup.older],
      );
      expect(
        [
          for (final s in sections) [for (final c in s.conversations) c.id],
        ],
        [
          [1, 2],
          [3, 4],
          [5, 6],
        ],
      );
    });

    testWidgets('resuming the app on a new day regroups', (tester) async {
      var now = historyNow;
      final container = ProviderContainer(
        overrides: [
          ...chatUiOverrides(
            session: FakeChatSession(),
            historyClock: () => now,
          ),
        ],
      );
      container.read(fakeHistoryProvider.notifier).set([
        historyConversation(1, 'a', at: DateTime(2026, 11, 27, 14)),
      ]);
      final sections = container.listen(chatHistorySectionsProvider, (_, _) {});
      try {
        await tester.pump();
        await tester.pump();
        expect(sections.read().value!.single.group, HistoryGroup.today);

        // The next day: the same conversation is no longer from today.
        now = DateTime(2026, 11, 28, 0, 0, 1);
        container.invalidate(chatHistorySectionsProvider);
        await tester.pump();
        expect(sections.read().value!.single.group, HistoryGroup.week);
      } finally {
        sections.close();
        container.dispose();
      }
    });

    test('empty groups are left out and the order is kept', () {
      final sections = groupHistory([
        historyConversation(7, 'a', at: DateTime(2026, 1, 1)),
        historyConversation(8, 'b', at: DateTime(2025, 1, 1)),
      ], historyNow);
      expect(sections, hasLength(1));
      expect(sections.single.group, HistoryGroup.older);
      expect([for (final c in sections.single.conversations) c.id], [7, 8]);
    });

    testWidgets('headings and the line of each row', (tester) async {
      await _pump(
        tester,
        conversations: [
          historyConversation(
            1,
            'Roadtrip',
            at: DateTime(2026, 11, 27, 9, 5),
            permission: AiPermission.auto,
          ),
          historyConversation(2, 'Week old', at: _daysAgo(3)),
          historyConversation(
            3,
            'Ancient',
            at: DateTime(2026, 1, 4),
            installId: 'gone-plugin',
          ),
        ],
      );
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Past 7 days'), findsOneWidget);
      expect(find.text('Older'), findsOneWidget);
      // Today shows the time, the others day and month; the plugin name and
      // the permission follow.
      expect(find.textContaining('09:05 · Claude'), findsOneWidget);
      expect(find.textContaining('Automatic'), findsOneWidget);
      expect(find.textContaining('24/11 · Claude'), findsOneWidget);
      expect(find.textContaining('04/01 · plugin removed'), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('search filters', (tester) async {
      final setup = await _pump(
        tester,
        conversations: [
          historyConversation(1, 'Roadtrip songs', at: _daysAgo(0)),
          historyConversation(2, 'Lyrics help', at: _daysAgo(1)),
        ],
      );
      expect(find.text('Roadtrip songs'), findsOneWidget);
      expect(find.text('Lyrics help'), findsOneWidget);

      await tester.enterText(_searchField, 'lyric');
      await tester.pumpAndSettle();
      expect(setup.container.read(chatHistoryQueryProvider), 'lyric');
      expect(find.text('Roadtrip songs'), findsNothing);
      expect(find.text('Lyrics help'), findsOneWidget);

      await tester.enterText(_searchField, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No conversation matches “zzz”.'), findsOneWidget);
    });
  });

  group('open and new', () {
    testWidgets('a tap opens the conversation and leaves the history', (
      tester,
    ) async {
      final setup = await _pump(
        tester,
        conversations: [
          historyConversation(1, 'Current', at: _daysAgo(0)),
          historyConversation(2, 'Other', at: _daysAgo(1)),
        ],
      );
      expect(_selection(tester, 1).selected, isTrue);
      expect(_selection(tester, 2).selected, isFalse);

      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('open 2'));
      expect(setup.container.read(chatSessionProvider).conversationId, 2);
      expect(setup.view.historyOpen, isFalse);
    });

    testWidgets('opening another conversation stops the streaming one', (
      tester,
    ) async {
      final setup = await _pump(
        tester,
        conversations: [
          historyConversation(1, 'Current', at: _daysAgo(0)),
          historyConversation(2, 'Other', at: _daysAgo(1)),
        ],
      );
      setup.session.setTurn(TurnState.streaming);
      await tester.pump();

      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();
      // The controller's open stops the turn; the page asks for nothing else.
      expect(
        setup.session.calls,
        containsAllInOrder(['turn stopped', 'open 2']),
      );
      expect(setup.session.calls, isNot(contains('stop')));
      expect(
        setup.container.read(chatSessionProvider),
        isA<ChatSessionState>()
            .having((s) => s.conversationId, 'conversationId', 2)
            .having((s) => s.turnState, 'turnState', TurnState.idle),
      );
      expect(setup.view.historyOpen, isFalse);
    });

    testWidgets('New conversation opens one and leaves the history', (
      tester,
    ) async {
      final setup = await _pump(
        tester,
        conversations: [historyConversation(1, 'Current', at: _daysAgo(0))],
      );
      setup.session.used.add(1);
      await tester.tap(find.text('New conversation'));
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('new'));
      expect(setup.container.read(chatSessionProvider).conversationId, 2);
      expect(setup.view.historyOpen, isFalse);
    });

    testWidgets('Esc steps back to the open conversation', (tester) async {
      final setup = await _pump(
        tester,
        conversations: [historyConversation(1, 'Current', at: _daysAgo(0))],
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(setup.view.historyOpen, isFalse);
    });
  });

  group('rename', () {
    testWidgets('rename is an input on the row; Enter saves', (tester) async {
      final setup = await _pump(
        tester,
        conversations: [historyConversation(2, 'Old name', at: _daysAgo(1))],
      );
      await _rowMenu(tester, 'Old name', 'Rename');
      await tester.enterText(_renameField, 'New name');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('rename 2 New name'));
      // The row is back to text and nothing was opened.
      expect(_renameField, findsNothing);
      expect(setup.session.calls, isNot(contains('open 2')));
    });
  });

  group('delete', () {
    testWidgets('delete asks, then controller delete', (tester) async {
      final setup = await _pump(
        tester,
        conversations: [
          historyConversation(1, 'Current', at: _daysAgo(0)),
          historyConversation(2, 'Doomed', at: _daysAgo(1)),
        ],
      );
      await _rowMenu(tester, 'Doomed', 'Delete');
      expect(find.text('Delete this conversation?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(setup.session.calls, isNot(contains('delete 2')));

      await _rowMenu(tester, 'Doomed', 'Delete');
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('delete 2'));
      // Another conversation was deleted: the open one stays.
      expect(setup.container.read(chatSessionProvider).conversationId, 1);
    });

    testWidgets('a deleted conversation is announced with a toast', (
      tester,
    ) async {
      await _pump(
        tester,
        conversations: [
          historyConversation(1, 'Current', at: _daysAgo(0)),
          historyConversation(2, 'Doomed', at: _daysAgo(1)),
        ],
      );
      await _rowMenu(tester, 'Doomed', 'Delete');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Conversation deleted'), findsNothing);

      await _rowMenu(tester, 'Doomed', 'Delete');
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Conversation deleted'), findsOneWidget);
      // Let the toast run out, so no timer outlives the test.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Conversation deleted'), findsNothing);
    });

    testWidgets('a delete that fails shows no toast', (tester) async {
      await _pump(
        tester,
        session: _HistorySession()..failDelete = true,
        conversations: [
          historyConversation(1, 'Current', at: _daysAgo(0)),
          historyConversation(2, 'Doomed', at: _daysAgo(1)),
        ],
      );
      await _rowMenu(tester, 'Doomed', 'Delete');
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Conversation deleted'), findsNothing);
    });

    testWidgets(
      'deleting the open conversation leaves the screen on a new conversation',
      (tester) async {
        final setup = await _pump(
          tester,
          conversations: [historyConversation(1, 'Current', at: _daysAgo(0))],
        );
        await _rowMenu(tester, 'Current', 'Delete');
        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();
        expect(setup.session.calls, contains('delete 1'));
        expect(setup.container.read(chatSessionProvider).conversationId, 2);
        // The history stays up; the user did not ask to leave it.
        expect(setup.view.historyOpen, isTrue);
      },
    );

    testWidgets('row busy during delete ignores taps', (tester) async {
      final gate = Completer<void>();
      final session = _HistorySession()..deleteGate = gate;
      final setup = await _pump(
        tester,
        session: session,
        conversations: [
          historyConversation(1, 'Current', at: _daysAgo(0)),
          historyConversation(2, 'Doomed', at: _daysAgo(1)),
        ],
      );
      await _rowMenu(tester, 'Doomed', 'Delete');
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      await tester.pump();

      expect(setup.container.read(chatHistoryActionsProvider), {2});
      expect(_selection(tester, 2).enabled, isFalse);
      await tester.tap(find.text('Doomed'), warnIfMissed: false);
      await tester.pump();
      expect(session.calls, isNot(contains('open 2')));
      expect(setup.view.historyOpen, isTrue);

      gate.complete();
      await tester.pumpAndSettle();
      expect(session.calls, contains('delete 2'));
      expect(setup.container.read(chatHistoryActionsProvider), isEmpty);
      expect(_selection(tester, 2).enabled, isTrue);
    });
  });
}
