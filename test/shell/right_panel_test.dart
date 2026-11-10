import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:kanaru/src/shell/ui/desktop_shell.dart';
import 'package:kanaru/src/shell/ui/desktop_sidebar.dart';
import 'package:kanaru/src/shell/ui/desktop_top_bar.dart';
import 'package:kanaru/src/shell/ui/player_bar.dart';
import 'package:kanaru/src/shell/ui/right_panel/right_panel_host.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/desktop_now_playing_host.dart';

const _queueTip = 'Queue (Ctrl+Shift+Q)';
const _chatTip = 'AI chat (Ctrl+J)';

RightPanelKind _kind(DesktopHost host) =>
    host.container.read(rightPanelProvider);

Future<void> _settle(WidgetTester tester, DesktopHost host) async {
  await tester.pump();
  await settleSlide(tester);
  await host.letStreamsArrive(tester);
}

/// Whether the top bar button is tonal (the player bar has its own Queue one).
bool _tonal(WidgetTester tester, String tooltip) => tester
    .widget<IconButton>(
      find.descendant(
        of: find.byType(DesktopTopBar),
        matching: find.widgetWithIcon(IconButton, _iconOf(tooltip)),
      ),
    )
    .isSelected!;

IconData _iconOf(String tooltip) =>
    tooltip == _queueTip ? KIcons.queueMusic : KIcons.ai;

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

void main() {
  testWidgets('closed by default: no panel, the buttons are not tonal', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    expect(_kind(host), RightPanelKind.closed);
    expect(find.byType(RightPanelHost), findsOneWidget);
    expect(find.byType(QueueRow), findsNothing);
    expect(_tonal(tester, _queueTip), isFalse);
  });

  testWidgets('the top bar Queue button opens and closes the queue panel', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    await tester.tap(find.byTooltip(_queueTip));
    await _settle(tester, host);
    expect(_kind(host), RightPanelKind.queue);
    expect(_tonal(tester, _queueTip), isTrue);
    expect(find.byType(QueueRow), findsWidgets);
    // Header: name and close; the queue has no menu button of its own there.
    expect(find.widgetWithText(Row, 'Queue'), findsWidgets);
    expect(find.byTooltip('Close panel'), findsOneWidget);
    expect(
      tester.getSize(find.byType(RightPanelHost).first).width,
      rightPanelWidth,
    );

    await tester.tap(find.byTooltip(_queueTip));
    await _settle(tester, host);
    expect(_kind(host), RightPanelKind.closed);
    expect(find.byType(QueueRow), findsNothing);
    expect(_tonal(tester, _queueTip), isFalse);
  });

  testWidgets('the close button and the player bar Queue button', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    expect(find.byType(PlayerBar), findsOneWidget);
    await tester.tap(find.byTooltip('Queue'));
    await _settle(tester, host);
    expect(_kind(host), RightPanelKind.queue);
    expect(host.container.read(nowPlayingPanelProvider).open, isFalse);
    await tester.tap(find.byTooltip('Close panel'));
    await _settle(tester, host);
    expect(_kind(host), RightPanelKind.closed);
    // The player bar button toggles too.
    await tester.tap(find.byTooltip('Queue'));
    await _settle(tester, host);
    await tester.tap(find.byTooltip('Queue'));
    await _settle(tester, host);
    expect(_kind(host), RightPanelKind.closed);
  });

  testWidgets('Ctrl+Shift+Q toggles the queue panel', (tester) async {
    final host = await pumpDesktopShell(tester);
    await _ctrl(tester, LogicalKeyboardKey.keyQ, shift: true);
    expect(_kind(host), RightPanelKind.queue);
    await _ctrl(tester, LogicalKeyboardKey.keyQ, shift: true);
    expect(_kind(host), RightPanelKind.closed);
    // Without Shift it is not the shortcut.
    await _ctrl(tester, LogicalKeyboardKey.keyQ);
    expect(_kind(host), RightPanelKind.closed);
    await _settle(tester, host);
  });

  testWidgets('without a chat the AI button is dimmed and Ctrl+J is free', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    final ai = find.widgetWithIcon(IconButton, KIcons.ai);
    expect(tester.widget<IconButton>(ai).onPressed, isNull);
    await _ctrl(tester, LogicalKeyboardKey.keyJ);
    expect(_kind(host), RightPanelKind.closed);
  });

  testWidgets('the AI button and Ctrl+J toggle the chat when there is one', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester, withChat: true);
    // withChat opens it; close with the button, open with the shortcut.
    expect(_kind(host), RightPanelKind.chat);
    expect(_tonal(tester, _chatTip), isTrue);
    expect(find.text('AI chat'), findsWidgets);
    expect(find.byKey(const ValueKey('chat menu')), findsOneWidget);
    await tester.tap(find.byTooltip(_chatTip));
    await _settle(tester, host);
    expect(_kind(host), RightPanelKind.closed);
    await _ctrl(tester, LogicalKeyboardKey.keyJ);
    await _settle(tester, host);
    expect(_kind(host), RightPanelKind.chat);
    expect(find.text('chat panel'), findsOneWidget);
  });

  group('switching slides in top bar order', () {
    testWidgets('Queue to Chat moves the content left', (tester) async {
      final host = await pumpDesktopShell(tester, withChat: true);
      host.container
          .read(rightPanelProvider.notifier)
          .show(RightPanelKind.queue);
      await _settle(tester, host);
      final queueRest = tester.getTopLeft(find.byTooltip('Close panel')).dx;
      expect(queueRest, greaterThan(1280 - rightPanelWidth));

      host.container
          .read(rightPanelProvider.notifier)
          .show(RightPanelKind.chat);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      // Mid-slide both are live: the queue leaves left, the chat comes from
      // the right.
      final queueNow = tester.getTopLeft(find.byType(QueueRow).first).dx;
      final chatNow = tester.getTopLeft(find.text('chat panel')).dx;
      expect(queueNow, lessThan(1280 - rightPanelWidth));
      expect(chatNow, greaterThan(1280 - rightPanelWidth / 2));
      await _settle(tester, host);
      expect(find.byType(QueueRow), findsNothing);
      expect(
        tester.getCenter(find.text('chat panel')).dx,
        closeTo(1280 - rightPanelWidth / 2, 1),
      );
    });

    testWidgets('Chat to Queue moves the content right', (tester) async {
      final host = await pumpDesktopShell(tester, withChat: true);
      await _settle(tester, host);
      final chatRest = tester.getCenter(find.text('chat panel')).dx;
      host.container
          .read(rightPanelProvider.notifier)
          .show(RightPanelKind.queue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.getCenter(find.text('chat panel')).dx,
        greaterThan(chatRest),
      );
      expect(
        tester.getTopLeft(find.byType(QueueRow).first).dx,
        lessThan(1280 - rightPanelWidth),
      );
      await _settle(tester, host);
      expect(find.text('chat panel'), findsNothing);
      expect(find.byType(QueueRow), findsWidgets);
    });

    testWidgets('opening from closed and closing do not slide', (tester) async {
      final host = await pumpDesktopShell(tester);
      host.container
          .read(rightPanelProvider.notifier)
          .show(RightPanelKind.queue);
      await tester.pump();
      // The very first frame already has the panel in place.
      expect(
        tester.getSize(find.byType(RightPanelHost).first).width,
        rightPanelWidth,
      );
      expect(
        tester.getTopLeft(find.byTooltip('Close panel')).dx,
        greaterThan(1280 - rightPanelWidth),
      );
      host.container.read(rightPanelProvider.notifier).close();
      await tester.pump();
      expect(find.byTooltip('Close panel'), findsNothing);
    });
  });

  group('the left part', () {
    for (final width in [1200.0, 1280.0]) {
      testWidgets(
        'shrinks by the panel and stays the desktop layout at $width',
        (tester) async {
          final host = await pumpDesktopShell(tester, size: Size(width, 800));
          host.container
              .read(rightPanelProvider.notifier)
              .show(RightPanelKind.queue);
          await _settle(tester, host);
          expect(
            FormFactor.of(tester.element(find.byType(DesktopShell))),
            FormFactor.desktop,
          );
          expect(find.byType(PlayerBar), findsOneWidget);
          expect(
            tester.getSize(find.byType(PlayerBar)).width,
            width - rightPanelWidth,
          );
          expect(
            tester.getTopLeft(find.byType(RightPanelHost)).dx,
            width - rightPanelWidth,
          );
        },
      );
    }
  });

  testWidgets(
    'Now Playing covers the left part; the open queue panel stays usable',
    (tester) async {
      final host = await pumpDesktopShell(tester);
      host.container
          .read(rightPanelProvider.notifier)
          .show(RightPanelKind.queue);
      await _settle(tester, host);
      host.container.read(nowPlayingPanelProvider.notifier).open();
      await _settle(tester, host);
      expect(host.container.read(nowPlayingPanelProvider).covered, isTrue);
      expect(find.byType(PlayerBar), findsNothing);
      // The panel is painted and takes taps while Now Playing is open.
      final rows = find.byType(QueueRow);
      expect(rows, findsWidgets);
      expect(rows.first.hitTestable(), findsOneWidget);
      final screen = tester.getRect(find.byTooltip('Minimise').first);
      expect(screen.right, lessThanOrEqualTo(1280 - rightPanelWidth));
      await tester.tap(find.byTooltip(_queueTip));
      await _settle(tester, host);
      expect(_kind(host), RightPanelKind.closed);
      expect(host.container.read(nowPlayingPanelProvider).open, isTrue);
    },
  );

  testWidgets('the panel is kept across pages', (tester) async {
    final host = await pumpDesktopShell(tester);
    host.container.read(rightPanelProvider.notifier).show(RightPanelKind.queue);
    await _settle(tester, host);
    host.routerRef.go('/other');
    await _settle(tester, host);
    expect(find.text('other'), findsOneWidget);
    expect(_kind(host), RightPanelKind.queue);
    expect(find.byType(QueueRow), findsWidgets);
  });

  group('the sidebar follows the left part', () {
    Future<double> sidebarWidth(
      WidgetTester tester, {
      required double window,
      required bool panel,
    }) async {
      final host = await pumpDesktopShell(tester, size: Size(window, 800));
      if (panel) {
        host.container
            .read(rightPanelProvider.notifier)
            .show(RightPanelKind.queue);
      }
      await _settle(tester, host);
      return tester.getSize(find.byKey(const ValueKey('sidebar'))).width;
    }

    testWidgets('1200 with the panel open: left part 780, rail', (
      tester,
    ) async {
      expect(
        await sidebarWidth(tester, window: 1200, panel: true),
        DesktopSidebar.railWidth,
      );
    });

    testWidgets('1440 with the panel closed: full sidebar', (tester) async {
      expect(
        await sidebarWidth(tester, window: 1440, panel: false),
        DesktopSidebar.fullWidth,
      );
    });

    testWidgets('1440 with the panel open: left part 1020, full sidebar', (
      tester,
    ) async {
      expect(
        await sidebarWidth(tester, window: 1440, panel: true),
        DesktopSidebar.fullWidth,
      );
    });
  });
}
