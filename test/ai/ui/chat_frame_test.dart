import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/chat_view/chat_view_state.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_draft.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_view.dart';
import 'package:kanaru/src/ai/ui/chat_header_title.dart';
import 'package:kanaru/src/ai/ui/chat_history_slot.dart';
import 'package:kanaru/src/ai/ui/chat_host.dart';
import 'package:kanaru/src/ai/ui/chat_menu.dart';
import 'package:kanaru/src/ai/ui/chat_page_mobile.dart';
import 'package:kanaru/src/ai/ui/chat_surface.dart';
import 'package:kanaru/src/ai/ui/composer_draft_binding.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';
import 'support/chat_ui_support.dart';

const _greeting = 'What do you want to ask about your music?';

class _Setup {
  _Setup(this.container, this.session, this.host);

  final ProviderContainer container;
  final FakeChatSession session;
  final RecordingChatHost host;

  ChatViewState get view => container.read(chatViewProvider);
}

/// The chat frame the desktop panel builds (title, menu, surface with its
/// composer). [mounted] false removes the chat, as a swap to the queue does.
class _Frame extends StatelessWidget {
  const _Frame({this.mounted = true});

  final bool mounted;

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox();
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: ChatHeaderTitle(style: const TextStyle())),
            const ChatMenu(),
          ],
        ),
        const Expanded(child: ChatSurface()),
      ],
    );
  }
}

Future<_Setup> _pump(
  WidgetTester tester, {
  Widget home = const _Frame(),
  Size size = const Size(1280, 800),
  bool withPlugin = true,
  FakeChatSession? session,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final fake = session ?? FakeChatSession();
  final host = RecordingChatHost();
  final container = ProviderContainer(
    overrides: [
      ...chatUiOverrides(session: fake, withPlugin: withPlugin),
      chatHostProvider.overrideWithValue(host),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _Setup(container, fake, host);
}

Future<void> _menuRow(WidgetTester tester, String title) async {
  await tester.tap(byIconButton('Chat options'));
  await tester.pumpAndSettle();
  // The header may show the same words (the new conversation's name).
  await tester.tap(find.text(title).last);
  await tester.pumpAndSettle();
}

void main() {
  group('frame', () {
    testWidgets('a new conversation shows its name and the greeting', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('New conversation'), findsOneWidget);
      expect(find.text(_greeting), findsOneWidget);
    });

    testWidgets('nothing is open at launch: the surface opens one', (
      tester,
    ) async {
      final setup = await _pump(tester, session: FakeChatSession(open: null));
      expect(setup.session.calls, ['new']);
      expect(setup.container.read(chatSessionProvider).conversationId, 1);
    });

    testWidgets('no chat plugin installed: the guide replaces the greeting', (
      tester,
    ) async {
      final setup = await _pump(tester, withPlugin: false);
      expect(find.text('Choose an AI service'), findsOneWidget);
      expect(find.text(_greeting), findsNothing);
      await tester.tap(find.text('Open the AI plugin store'));
      await tester.pump();
      expect(setup.host.calls, ['openSettings /settings/plugins?kind=aiChat']);
    });
  });

  group('state outlives the chat', () {
    testWidgets('draft survives queue swap and Ctrl+J', (tester) async {
      final setup = await _pump(tester);
      await tester.enterText(find.byType(TextField), 'hello there');
      await tester.pump();
      // The panel swapping to the queue, or closing on Ctrl+J, removes the
      // chat; opening it builds a new one.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: setup.container,
          child: const MaterialApp(home: _Frame(mounted: false)),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: setup.container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: _Frame()),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'hello there',
      );
      expect(setup.container.read(composerDraftProvider).text, 'hello there');
    });

    testWidgets('ask during swap focuses one field', (tester) async {
      final setup = await _pump(
        tester,
        home: Column(
          children: [
            for (var i = 0; i < 2; i++)
              ComposerDraftBinding(
                builder: (context, controller, focus) =>
                    TextField(key: ValueKey('field $i'), focusNode: focus),
              ),
          ],
        ),
      );
      setup.container.read(composerFocusRequestProvider.notifier).request();
      await tester.pump();
      await tester.pump();
      final focused = [
        for (var i = 0; i < 2; i++)
          if (tester
              .widget<TextField>(find.byKey(ValueKey('field $i')))
              .focusNode!
              .hasFocus)
            i,
      ];
      expect(focused, hasLength(1));
      expect(setup.container.read(composerFocusRequestProvider), isFalse);
    });

    testWidgets('a request made before the chat exists is kept for it', (
      tester,
    ) async {
      final setup = await _pump(tester, home: const _Frame(mounted: false));
      setup.container.read(composerFocusRequestProvider.notifier).request();
      await tester.pump();
      expect(setup.container.read(composerFocusRequestProvider), isTrue);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: setup.container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: _Frame()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      expect(setup.container.read(composerFocusRequestProvider), isFalse);
    });
  });

  group('rename', () {
    testWidgets('tap title edits, Enter saves, Esc cancels', (tester) async {
      final setup = await _pump(tester);
      await tester.tap(find.text('New conversation'));
      await tester.pump();
      expect(setup.view.renaming, isTrue);
      // Esc cancels and leaves the name alone.
      await tester.enterText(find.byType(TextField).first, 'Roadtrip');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(setup.view.renaming, isFalse);
      expect(setup.session.calls, isNot(contains('rename 1 Roadtrip')));
      expect(find.text('New conversation'), findsOneWidget);

      // Tap again, type, Enter saves.
      await tester.tap(find.text('New conversation'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'Roadtrip');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();
      expect(setup.session.calls, contains('rename 1 Roadtrip'));
      expect(setup.view.renaming, isFalse);
      expect(find.text('Roadtrip'), findsOneWidget);
    });

    testWidgets('the check button saves the typed name', (tester) async {
      final setup = await _pump(tester);
      await tester.tap(find.text('New conversation'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'Gym');
      await tester.tap(byIconButton('Save name'));
      await tester.pump();
      await tester.pump();
      expect(setup.session.calls, contains('rename 1 Gym'));
      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('Enter on an untouched placeholder saves nothing', (
      tester,
    ) async {
      final setup = await _pump(tester);
      await tester.tap(find.text('New conversation'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();
      expect(setup.session.calls.where((c) => c.startsWith('rename')), isEmpty);
      expect(setup.view.renaming, isFalse);
    });

    testWidgets('a blank name keeps the old one', (tester) async {
      final setup = await _pump(tester);
      await tester.tap(find.text('New conversation'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.tap(byIconButton('Save name'));
      await tester.pump();
      expect(setup.session.calls.where((c) => c.startsWith('rename')), isEmpty);
      expect(setup.view.renaming, isFalse);
    });

    testWidgets('another conversation ends a rename', (tester) async {
      final setup = await _pump(tester);
      await tester.tap(find.text('New conversation'));
      await tester.pump();
      await setup.container.read(chatSessionProvider.notifier).open(7);
      await tester.pump();
      expect(setup.view.renaming, isFalse);
    });
  });

  group('conversation change', () {
    testWidgets('the note of a refused send ends with its conversation', (
      tester,
    ) async {
      final setup = await _pump(tester);
      setup.container
          .read(composerSendNoticeProvider.notifier)
          .set(const NoticeSendFailed());
      await tester.pump();
      expect(find.textContaining('could not be saved'), findsOneWidget);
      await setup.container.read(chatSessionProvider.notifier).open(7);
      await tester.pump();
      await tester.pump();
      expect(setup.container.read(composerSendNoticeProvider), isNull);
      expect(find.textContaining('could not be saved'), findsNothing);
    });

    testWidgets('the scroll place of the old conversation is dropped', (
      tester,
    ) async {
      final setup = await _pump(tester);
      setup.container.read(chatScrollAnchorProvider.notifier).set(42);
      await setup.container.read(chatSessionProvider.notifier).open(7);
      await tester.pump();
      expect(setup.container.read(chatScrollAnchorProvider), isNull);
    });
  });

  group('menu', () {
    testWidgets('Cài đặt AI calls host.openSettings with the AI location', (
      tester,
    ) async {
      final setup = await _pump(tester);
      await _menuRow(tester, 'AI settings');
      expect(setup.host.calls, ['openSettings /settings/ai']);
    });

    testWidgets('New conversation opens one and asks for the cursor', (
      tester,
    ) async {
      final setup = await _pump(tester);
      setup.session.used.add(1);
      await _menuRow(tester, 'New conversation');
      expect(setup.session.calls, contains('new'));
      expect(setup.container.read(chatSessionProvider).conversationId, 2);
      // The composer took the one-shot request. Whether the field still holds
      // the focus afterwards depends on the closing menu route's own focus
      // restore, which is the framework's business, so it is not asserted.
      expect(setup.container.read(composerFocusRequestProvider), isFalse);
    });

    testWidgets('Rename on an unnamed chat starts with an empty name', (
      tester,
    ) async {
      final setup = await _pump(tester);
      await _menuRow(tester, 'Rename');
      expect(setup.view.renaming, isTrue);
      // The placeholder is only a hint: it must not become the saved name.
      expect(setup.view.renameText, isEmpty);
    });

    testWidgets('Rename starts on the current name of a named chat', (
      tester,
    ) async {
      final setup = await _pump(tester);
      setup.container.read(fakeChatTitlesProvider.notifier).set(1, 'Roadtrip');
      await tester.pump();
      await _menuRow(tester, 'Rename');
      expect(setup.view.renameText, 'Roadtrip');
    });

    testWidgets('Delete asks first; Cancel keeps it, Delete removes it', (
      tester,
    ) async {
      final setup = await _pump(tester);
      await _menuRow(tester, 'Delete this conversation');
      expect(find.text('Delete this conversation?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(setup.session.calls, isNot(contains('delete 1')));

      await _menuRow(tester, 'Delete this conversation');
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('delete 1'));
      expect(setup.container.read(chatSessionProvider).conversationId, 2);
    });

    testWidgets('Back in History returns to the conversation', (tester) async {
      final setup = await _pump(
        tester,
        size: const Size(400, 800),
        home: const ChatPageMobile(),
      );
      await _menuRow(tester, 'Chat history');
      expect(setup.view.historyOpen, isTrue);
      expect(find.byKey(chatHistorySlotKey), findsOneWidget);
      expect(find.text(_greeting), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump();
      expect(setup.view.historyOpen, isFalse);
      expect(find.byKey(chatHistorySlotKey), findsNothing);
      expect(find.text(_greeting), findsOneWidget);
    });
  });

  group('phone page', () {
    testWidgets('header: close, name, menu; close asks the host', (
      tester,
    ) async {
      final setup = await _pump(
        tester,
        size: const Size(400, 800),
        home: const ChatPageMobile(),
      );
      expect(byIconButton('Close chat'), findsOneWidget);
      expect(byIconButton('Chat options'), findsOneWidget);
      await tester.tap(byIconButton('Close chat'));
      expect(setup.host.calls, ['close']);
    });

    testWidgets('while renaming the check replaces the menu, Back cancels', (
      tester,
    ) async {
      final setup = await _pump(
        tester,
        size: const Size(400, 800),
        home: const ChatPageMobile(),
      );
      await tester.tap(find.text('New conversation'));
      await tester.pump();
      expect(byIconButton('Save name'), findsOneWidget);
      expect(byIconButton('Chat options'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(setup.view.renaming, isFalse);
      expect(byIconButton('Chat options'), findsOneWidget);
    });
  });
}
