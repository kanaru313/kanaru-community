import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/src/ai/state/chat_view/chat_view_state.dart';
import 'package:kanaru/src/ai/ui/history_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../test/ai/ui/support/chat_ui_support.dart';
import '../test/support/icon_button_finders.dart';
import 'support/ai_chat_harness.dart';

/// AI chat screens (PR #116, polish #118, #119) in Vietnamese, on both shells:
/// the phone (412 x 915, MobileShell, the `/chat` page) and the desktop
/// (1400 x 1000, DesktopShell, chat in the right panel). The real shell,
/// router and chat widgets run over the fake engine of `test/ai/ui/support`
/// (no plugin, no network, no native library), so the same file runs as a
/// plain widget test and on the Linux device.
///
/// It asserts state (finders, semantics), never pixels. Screenshots
/// `NN-<state>-<shell>.png` go to `$KANARU_IT_SHOTS` (default
/// `/tmp/kanaru-it/shots-ai-chat`) for comparing with `mockups/*/08-ai-chat`.
///
/// This file: the History page (P3, P4).

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('history', () {
    final conversations = [
      historyConversation(
        1,
        'Gợi ý nhạc buồn',
        at: DateTime(2026, 11, 27, 9, 5),
      ),
      historyConversation(
        2,
        'Dịch lời Lạc trôi',
        at: DateTime(2026, 11, 25, 20),
      ),
      historyConversation(3, 'Playlist chạy bộ', at: DateTime(2026, 11, 3, 8)),
    ];

    perShell('list grouped; the new-conversation button is in the header', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      c.container.read(fakeHistoryProvider.notifier).set(conversations);
      await c.openHistory();
      expect(find.byKey(chatHistoryPageKey), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('7 ngày qua'), findsOneWidget);
      expect(find.text('Cũ hơn'), findsOneWidget);
      expect(find.byType(KListActionButton), findsNothing);
      // Desktop names the shortcut in the tooltip, the phone does not.
      final compose = byIconButton(
        c.isPhone
            ? 'Cuộc trò chuyện mới'
            : 'Cuộc trò chuyện mới (Ctrl+Shift+O)',
      );
      expect(compose, findsOneWidget);
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final composeRect = tester.getRect(compose);
      expect(composeRect.left, greaterThanOrEqualTo(0));
      expect(composeRect.right, lessThanOrEqualTo(screenWidth));
      if (!c.isPhone) {
        final close = find.byWidgetPredicate(
          (w) => w is KIconButton && w.icon == KIcons.close,
        );
        expect(close, findsOneWidget);
        final closeRect = tester.getRect(close);
        expect(composeRect.right, lessThanOrEqualTo(closeRect.left));
        expect(closeRect.right, lessThanOrEqualTo(screenWidth));
      }
      await c.shot('20-history');
    });

    perShell('rename turns the row title into an input', (tester, shell) async {
      final c = await openChat(tester, shell);
      c.container.read(fakeHistoryProvider.notifier).set(conversations);
      await c.openHistory();
      await tester.tap(byIconButton('Tuỳ chọn cho Dịch lời Lạc trôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi tên').last);
      await tester.pumpAndSettle();
      final field = find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.hintText == 'Tên cuộc trò chuyện',
      );
      expect(field, findsOneWidget);
      await c.shot('21-history-rename');
      await tester.enterText(field, 'Tên mới');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await c.pump();
      expect(c.session.calls, contains('rename 2 Tên mới'));
    });

    perShell('P4: the button takes Tab focus and Enter opens a new chat', (
      tester,
      shell,
    ) async {
      final c = await openChat(tester, shell);
      c.container.read(fakeHistoryProvider.notifier).set(conversations);
      await c.openHistory();
      bool onButton() {
        final button = FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<KIconButton>();
        return button != null && button.icon == KIcons.compose;
      }

      for (var i = 0; i < 8 && !onButton(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(onButton(), isTrue);
      await c.shot('22-history-button-focused');
      c.session.used.add(1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await c.pump();
      expect(c.session.calls, contains('new'));
      expect(c.container.read(chatViewProvider).historyOpen, isFalse);
    });

    perShell('P4: the header buttons and title do not overflow at 200 % text', (
      tester,
      shell,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      final c = await openChat(tester, shell);
      c.container.read(fakeHistoryProvider.notifier).set(conversations);
      await c.openHistory();
      final compose = byIconButton(
        c.isPhone
            ? 'Cuộc trò chuyện mới'
            : 'Cuộc trò chuyện mới (Ctrl+Shift+O)',
      );
      expect(compose, findsOneWidget);
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final composeRect = tester.getRect(compose);
      expect(composeRect.left, greaterThanOrEqualTo(0));
      expect(composeRect.right, lessThanOrEqualTo(screenWidth));
      if (!c.isPhone) {
        final close = find.byWidgetPredicate(
          (w) => w is KIconButton && w.icon == KIcons.close,
        );
        expect(close, findsOneWidget);
        final closeRect = tester.getRect(close);
        expect(composeRect.right, lessThanOrEqualTo(closeRect.left));
        expect(closeRect.right, lessThanOrEqualTo(screenWidth));
      }
      expect(find.text('Lịch sử trò chuyện'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await c.shot('23-history-text-200');
    });
  });
}
