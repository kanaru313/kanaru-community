import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/shell/ui/player_bar.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/desktop_now_playing_host.dart';

NowPlayingPanel _panel(DesktopHost host) =>
    host.container.read(nowPlayingPanelProvider.notifier);

NowPlayingPanelState _state(DesktopHost host) =>
    host.container.read(nowPlayingPanelProvider);

void main() {
  testWidgets('opening builds the screen and slides it up', (tester) async {
    final host = await pumpDesktopShell(tester);
    expect(find.byType(DesktopNowPlaying), findsNothing);
    _panel(host).open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(DesktopNowPlaying), findsOneWidget);
    expect(_state(host).covered, isFalse);
    // Mid-slide the region is still there, drawn.
    expect(find.byType(PlayerBar), findsOneWidget);
    final midTop = tester.getTopLeft(find.byType(DesktopNowPlaying)).dy;
    await settleSlide(tester);
    final endTop = tester.getTopLeft(find.byType(DesktopNowPlaying)).dy;
    // Still coming up half way, then in place under the top bar.
    expect(midTop, greaterThan(endTop));
    expect(endTop, greaterThan(0));
    expect(endTop, lessThan(100));
  });

  testWidgets('after the slide the player bar, sidebar and page are offstage', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    expect(_state(host).covered, isTrue);
    expect(find.byType(PlayerBar), findsNothing);
    expect(find.byKey(const ValueKey('sidebar')), findsNothing);
    expect(find.text('row 0'), findsNothing);
    // The state is kept, not rebuilt.
    expect(find.byType(PlayerBar, skipOffstage: false), findsOneWidget);
    // The top bar stays.
    expect(find.text('Kanaru'), findsOneWidget);
  });

  testWidgets('a page scroll offset survives open and close', (tester) async {
    final host = await pumpDesktopShell(tester);
    await tester.drag(find.text('row 3'), const Offset(0, -400));
    await tester.pump();
    double offset() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('page list'), skipOffstage: false),
            matching: find.byType(Scrollable),
            skipOffstage: false,
          ),
        )
        .position
        .pixels;
    final before = offset();
    expect(before, greaterThan(100));
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    _panel(host).close();
    await tester.pump();
    await settleSlide(tester);
    expect(offset(), before);
  });

  testWidgets('closing starts: the region is drawn in the same frame', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    expect(find.byType(PlayerBar), findsNothing);
    _panel(host).close();
    await tester.pump();
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.byType(DesktopNowPlaying), findsOneWidget);
    await settleSlide(tester);
    expect(find.byType(DesktopNowPlaying), findsNothing);
  });

  testWidgets('dismissed: the screen is gone and focus goes back', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    final button = find.byType(IconButton).first;
    Focus.of(tester.element(button)).requestFocus();
    await tester.pump();
    final before = FocusManager.instance.primaryFocus;
    expect(before, isNotNull);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    expect(FocusManager.instance.primaryFocus, isNot(before));
    _panel(host).close();
    await tester.pump();
    await settleSlide(tester);
    expect(find.byType(DesktopNowPlaying), findsNothing);
    expect(FocusManager.instance.primaryFocus, before);
  });

  testWidgets('reduced motion: open and close are instant', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final host = await pumpDesktopShell(tester);
    _panel(host).open();
    await tester.pump();
    await tester.pump();
    expect(find.byType(DesktopNowPlaying), findsOneWidget);
    expect(_state(host).covered, isTrue);
    expect(find.byType(PlayerBar), findsNothing);
    _panel(host).close();
    await tester.pump();
    expect(find.byType(DesktopNowPlaying), findsNothing);
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(_state(host).covered, isFalse);
  });

  testWidgets('a tap on the screen never reaches the region under it', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    _panel(host).open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The first page row is at the top left; the sliding screen is lower but
    // covers the lower rows.
    final y = tester.getTopLeft(find.byType(DesktopNowPlaying)).dy + 100;
    await tester.tapAt(Offset(600, y));
    expect(host.pageTaps, 0);
    await settleSlide(tester);
  });

  testWidgets('no ticker is left when it is closed', (tester) async {
    final host = await pumpDesktopShell(tester);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    _panel(host).close();
    await tester.pump();
    await settleSlide(tester);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('the chat panel stays painted and tappable while it is open', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester, withChat: true);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    expect(_state(host).covered, isTrue);
    expect(find.byType(DesktopNowPlaying), findsOneWidget);
    expect(find.text('chat panel'), findsOneWidget);
    expect(find.text('chat panel').hitTestable(), findsOneWidget);
    await tester.tap(find.text('chat panel'));
    expect(host.chatTaps, 1);
    // Mid-slide too.
    _panel(host).close();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('chat panel'));
    expect(host.chatTaps, 2);
    await settleSlide(tester);
  });

  testWidgets('the screen covers the left region only', (tester) async {
    final host = await pumpDesktopShell(tester, withChat: true);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    final screen = tester.getRect(find.byType(DesktopNowPlaying));
    final chat = tester.getRect(find.text('chat panel'));
    expect(screen.right, lessThanOrEqualTo(1280 - 420 + 0.5));
    expect(chat.left, greaterThanOrEqualTo(screen.right - 0.5));
    // From under the top bar to the bottom: the player bar's place included.
    expect(screen.bottom, 800);
    expect(screen.top, greaterThan(0));
  });

  testWidgets('Esc closes the screen and does not go back in history', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    host.router!.go('/other');
    await tester.pump();
    await tester.pump();
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(_state(host).open, isFalse);
    await settleSlide(tester);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('the mouse Back button closes it before walking history', (
    tester,
  ) async {
    final host = await pumpDesktopShell(tester);
    host.router!.go('/other');
    await tester.pump();
    await tester.pump();
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    final g = await tester.startGesture(
      const Offset(500, 400),
      kind: PointerDeviceKind.mouse,
      buttons: kBackMouseButton,
    );
    await g.up();
    await tester.pump();
    expect(_state(host).open, isFalse);
    await settleSlide(tester);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('going to another page closes it', (tester) async {
    final host = await pumpDesktopShell(tester);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    host.router!.go('/other');
    await tester.pump();
    await tester.pump();
    expect(_state(host).open, isFalse);
    await settleSlide(tester);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('a snack bar shows on top of the screen', (tester) async {
    final host = await pumpDesktopShell(tester);
    _panel(host).open();
    await tester.pump();
    await settleSlide(tester);
    showAppSnackBar(tester.element(find.byType(DesktopNowPlaying)), 'hello');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('hello').hitTestable(), findsOneWidget);
    expect(host, isNotNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
