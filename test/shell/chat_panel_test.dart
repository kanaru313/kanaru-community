import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/ai/ai_extension.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/chat_view/chat_view_state.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_draft.dart';
import 'package:kanaru/src/ai/ui/history_page.dart';
import 'package:kanaru/src/ai/ui/chat_page_mobile.dart';
import 'package:kanaru/src/ai/ui/chat_surface.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:kanaru/src/shell/ui/right_panel/right_panel_host.dart'
    show rightPanelFrameKey;
import 'package:kanaru/src/shell/ui/chat_host_shell.dart';
import 'package:material_ui/material_ui.dart';

import '../ai/ui/support/chat_ui_support.dart';
import '../support/app_harness.dart';
import '../support/icon_button_finders.dart';
import '../support/memory_settings_store.dart';
import '../support/nav_fixture.dart';
import 'support/desktop_now_playing_host.dart';

const _chatTip = 'AI chat (Ctrl+J)';
const _greeting = 'What do you want to ask about your music?';

RightPanelKind _kind(DesktopHost host) =>
    host.container.read(rightPanelProvider);

Future<void> _settle(WidgetTester tester, DesktopHost host) async {
  await tester.pump();
  await settleSlide(tester);
  await host.letStreamsArrive(tester);
}

Future<void> _ctrl(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

/// The whole app (router, AppShell) with the AI extension and a stand-in chat
/// session, at [width].
Future<(ProviderContainer, FakeChatSession)> _pumpApp(
  WidgetTester tester, {
  required double width,
  MemorySettingsStore? settings,
}) async {
  final session = FakeChatSession();
  final container = await pumpKanaruApp(
    tester,
    extensions: [const NavFixture(), const AiExtension()],
    width: width,
    settings: settings,
    overrides: [
      ...chatUiOverrides(session: session),
      chatHostOverride,
    ],
  );
  return (container, session);
}

/// Locations of the router's stack, top last.
List<String> _stack(ProviderContainer c) => [
  for (final m
      in c.read(routerProvider).routerDelegate.currentConfiguration.matches)
    m.matchedLocation,
];

Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('desktop', () {
    testWidgets('desktop AI button toggles the chat panel', (tester) async {
      final host = await pumpDesktopShell(tester);
      expect(_kind(host), RightPanelKind.closed);
      await tester.tap(byAnyIconButton(_chatTip));
      await _settle(tester, host);
      expect(_kind(host), RightPanelKind.chat);
      expect(find.byType(ChatSurface), findsOneWidget);
      expect(find.text(_greeting), findsOneWidget);
      await tester.tap(byAnyIconButton(_chatTip));
      await _settle(tester, host);
      expect(_kind(host), RightPanelKind.closed);
      expect(find.byType(ChatSurface), findsNothing);
    });

    testWidgets('the panel closes with its own close button', (tester) async {
      final host = await pumpDesktopShell(tester, withChat: true);
      await tester.tap(byIconButton('Close panel (Ctrl+J)'));
      await _settle(tester, host);
      expect(_kind(host), RightPanelKind.closed);
    });

    testWidgets('AI button shown when an extension adds a top-bar action', (
      tester,
    ) async {
      final registry = ExtensionRegistry()
        ..addTopBarAction(
          TopBarAction(
            id: 'extra',
            order: 1,
            builder: (_) => const Text('extra action'),
          ),
        );
      final host = await pumpDesktopShell(tester, registry: registry);
      expect(find.text('extra action'), findsOneWidget);
      expect(byAnyIconButton(_chatTip), findsOneWidget);
      await tester.tap(byAnyIconButton(_chatTip));
      await _settle(tester, host);
      expect(_kind(host), RightPanelKind.chat);
    });

    testWidgets('Ctrl+J toggles, Ctrl+Shift+O opens the panel with a new '
        'conversation', (tester) async {
      final host = await pumpDesktopShell(tester);
      await _ctrl(tester, LogicalKeyboardKey.keyJ);
      expect(_kind(host), RightPanelKind.chat);
      await _ctrl(tester, LogicalKeyboardKey.keyJ);
      expect(_kind(host), RightPanelKind.closed);
      await _settle(tester, host);

      // The open conversation already has messages: Ctrl+Shift+O starts
      // another one, opens the panel and asks for the cursor.
      host.chat.used.add(1);
      await _ctrl(tester, LogicalKeyboardKey.keyO, shift: true);
      await _settle(tester, host);
      expect(_kind(host), RightPanelKind.chat);
      expect(host.chat.calls, contains('new'));
      expect(host.container.read(chatSessionProvider).conversationId, 2);
      expect(host.container.read(composerFocusRequestProvider), isTrue);
      // Without Shift it is not the shortcut.
      await _ctrl(tester, LogicalKeyboardKey.keyO);
      expect(host.chat.calls.where((c) => c == 'new'), hasLength(1));
    });

    testWidgets('the chat keeps its draft and view state across Ctrl+J', (
      tester,
    ) async {
      final host = await pumpDesktopShell(tester, withChat: true);
      host.container
          .read(composerDraftProvider.notifier)
          .set(const TextEditingValue(text: 'half a question'));
      host.container.read(chatViewProvider.notifier).openHistory();
      await _settle(tester, host);
      await _ctrl(tester, LogicalKeyboardKey.keyJ);
      await _settle(tester, host);
      expect(_kind(host), RightPanelKind.closed);
      await _ctrl(tester, LogicalKeyboardKey.keyJ);
      await _settle(tester, host);
      expect(
        host.container.read(composerDraftProvider).text,
        'half a question',
      );
      expect(host.container.read(chatViewProvider).historyOpen, isTrue);
    });

    testWidgets('queue and chat swap, the chat state is kept', (tester) async {
      final host = await pumpDesktopShell(tester, withChat: true);
      host.container.read(chatViewProvider.notifier).openHistory();
      await _settle(tester, host);
      host.container
          .read(rightPanelProvider.notifier)
          .show(RightPanelKind.queue);
      await _settle(tester, host);
      expect(find.byType(ChatSurface), findsNothing);
      host.container
          .read(rightPanelProvider.notifier)
          .show(RightPanelKind.chat);
      await _settle(tester, host);
      expect(find.byKey(chatHistoryPageKey), findsOneWidget);
    });

    testWidgets('restored chat panel does not create the player during the '
        'first build', (tester) async {
      final host = await pumpDesktopShell(
        tester,
        play: false,
        playerPhase: PlayerPhase.notCreated,
        savedSettings: {'shell.right_panel': 'chat'},
      );
      expect(_kind(host), RightPanelKind.chat);
      // The state may have changed after the last frame: draw it first.
      await tester.pump();
      // The panel's room is kept, its content waits for the player.
      expect(find.byType(ChatSurface), findsNothing);
      expect(
        tester.getSize(find.byKey(rightPanelFrameKey)).width,
        greaterThan(0),
      );
      await tester.runAsync(
        () =>
            host.container.read(playerPhaseProvider.notifier).attach(host.h.c),
      );
      await _settle(tester, host);
      expect(find.byType(ChatSurface), findsOneWidget);
    });

    testWidgets('Esc on History with nothing focused returns to the '
        'conversation', (tester) async {
      final host = await pumpDesktopShell(tester, withChat: true);
      host.container.read(chatViewProvider.notifier).openHistory();
      await _settle(tester, host);
      expect(find.byKey(chatHistoryPageKey), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester, host);
      expect(host.container.read(chatViewProvider).historyOpen, isFalse);
      expect(find.byKey(chatHistoryPageKey), findsNothing);
      expect(_kind(host), RightPanelKind.chat);
    });

    testWidgets('Esc cancels a rename before anything else', (tester) async {
      final host = await pumpDesktopShell(tester, withChat: true);
      host.container.read(chatViewProvider.notifier).startRename('x');
      await _settle(tester, host);
      // Nothing inside the text field has focus: the shell takes the key.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester, host);
      expect(host.container.read(chatViewProvider).renaming, isFalse);
      expect(_kind(host), RightPanelKind.chat);
    });
  });

  group('phone', () {
    testWidgets('mobile ✦ pushes /chat once, a second ask does not push', (
      tester,
    ) async {
      final (container, _) = await _pumpApp(tester, width: 400);
      expect(find.byType(ChatPageMobile), findsNothing);
      await tester.tap(byIconButton('AI chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatPageMobile), findsOneWidget);
      expect(_stack(container).where((l) => l == '/chat'), hasLength(1));
      expect(_stack(container).last, '/chat');

      // A second ask, with the page already open, changes nothing.
      openChatPage(container.read(routerProvider));
      await tester.pumpAndSettle();
      expect(_stack(container).where((l) => l == '/chat'), hasLength(1));
    });

    testWidgets('an ask with the chat below another page pops back to it', (
      tester,
    ) async {
      final (container, _) = await _pumpApp(tester, width: 400);
      final router = container.read(routerProvider);
      openChatPage(router);
      await tester.pumpAndSettle();
      unawaited(router.push('/gear'));
      await tester.pumpAndSettle();
      expect(_stack(container).last, '/gear');
      openChatPage(router);
      await tester.pumpAndSettle();
      expect(_stack(container).last, '/chat');
      expect(_stack(container).where((l) => l == '/chat'), hasLength(1));
    });

    testWidgets('the close button pops the page', (tester) async {
      final (container, _) = await _pumpApp(tester, width: 400);
      await tester.tap(byIconButton('AI chat'));
      await tester.pumpAndSettle();
      await tester.tap(byIconButton('Close chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatPageMobile), findsNothing);
      expect(_stack(container), isNot(contains('/chat')));
    });

    testWidgets('the phone does not open the chat saved open on desktop', (
      tester,
    ) async {
      final settings = MemorySettingsStore();
      await settings.write('shell.right_panel', 'chat');
      final (container, _) = await _pumpApp(
        tester,
        width: 400,
        settings: settings,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChatPageMobile), findsNothing);
      expect(container.read(rightPanelProvider), RightPanelKind.closed);
    });
  });

  group('hand-over', () {
    testWidgets('narrowing with chat panel pushes /chat', (tester) async {
      final (container, _) = await _pumpApp(tester, width: 1280);
      container.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
      await tester.pumpAndSettle();
      expect(find.byType(ChatSurface), findsOneWidget);
      await _resize(tester, 400);
      await tester.pumpAndSettle();
      expect(container.read(rightPanelProvider), RightPanelKind.closed);
      expect(_stack(container).last, '/chat');
      expect(find.byType(ChatPageMobile), findsOneWidget);
      expect(find.byType(ChatSurface), findsOneWidget);
    });

    testWidgets('widening with /chat on top pops it and opens the panel', (
      tester,
    ) async {
      final (container, _) = await _pumpApp(tester, width: 400);
      await tester.tap(byIconButton('AI chat'));
      await tester.pumpAndSettle();
      expect(_stack(container).last, '/chat');
      await _resize(tester, 1280);
      await tester.pumpAndSettle();
      expect(_stack(container), isNot(contains('/chat')));
      expect(container.read(rightPanelProvider), RightPanelKind.chat);
      expect(find.byType(ChatPageMobile), findsNothing);
      expect(find.byType(ChatSurface), findsOneWidget);
    });

    testWidgets('the draft and the open conversation cross the hand-over', (
      tester,
    ) async {
      final (container, session) = await _pumpApp(tester, width: 1280);
      container.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
      await tester.pumpAndSettle();
      container
          .read(composerDraftProvider.notifier)
          .set(const TextEditingValue(text: 'keep me'));
      await _resize(tester, 400);
      await tester.pumpAndSettle();
      expect(container.read(composerDraftProvider).text, 'keep me');
      expect(container.read(chatSessionProvider).conversationId, 1);
      expect(session.calls, isNot(contains('new')));
    });
  });
}
