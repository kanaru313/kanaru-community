import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/lyrics_screen.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/ui_host.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('widening past 1200 hands over to the desktop panel once', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(800, 900),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    expect(host.container.read(nowPlayingPanelProvider).open, isFalse);

    // A resize drag back and forth across the limit.
    for (final width in [1300.0, 800.0, 1300.0, 800.0, 1300.0]) {
      await _resize(tester, width);
    }
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(host.container.read(nowPlayingPanelProvider).open, isTrue);
    expect(host.router!.canPop(), isFalse);
    expect(find.text('home'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the panel opens after the window turns wide', (tester) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(800, 900),
    );
    host.container.read(nowPlayingPanelProvider.notifier).open();
    host.container.read(nowPlayingPanelProvider.notifier).close();
    host.router!.push('/now-playing');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _resize(tester, 1300);
    expect(host.container.read(nowPlayingPanelProvider).open, isTrue);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('opened directly at desktop width it leaves at once', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(1300, 900),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(host.container.read(nowPlayingPanelProvider).open, isTrue);
    expect(host.router!.canPop(), isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('widening with the lyrics screen open removes it with the page', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(800, 900),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await host.letStreamsArrive(tester);
    await tester.scrollUntilVisible(
      find.byType(LyricsCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(LyricsCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LyricsScreen), findsOneWidget);

    await _resize(tester, 1300);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(host.container.read(nowPlayingPanelProvider).open, isTrue);
    // The pop took `/now-playing`, not the lyrics route: back on the page
    // under it, nothing blank left behind.
    expect(host.router!.canPop(), isFalse);
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
  });
}
