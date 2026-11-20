import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/ui_host.dart';
import '../../../playback/ui/sleep_timer/sleep_timer_modal_host.dart';
import '../../../support/icon_button_finders.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

Future<UiHost> _open(WidgetTester tester, {double textScale = 1}) async {
  final host = await pumpWithPlayer(
    tester,
    const Center(child: Text('home page')),
    overrides: [
      sleepTimerProvider.overrideWith(FakeSleepTimer.new),
      ...sleepEstimates(),
    ],
    routes: _routes,
    size: const Size(390, 844),
    textScale: textScale,
  );
  host.router!.push('/now-playing');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await host.letStreamsArrive(tester);
  return host;
}

FakeSleepTimer _timer(UiHost host) =>
    host.container.read(sleepTimerProvider.notifier) as FakeSleepTimer;

Finder get _ring => find.byType(KProgressRingIcon);

void main() {
  testWidgets('the ring shows only while a timer runs; the title stays put', (
    tester,
  ) async {
    final host = await _open(tester);
    final handle = tester.ensureSemantics();
    final title = find.text('1/6');
    final before = tester.getRect(title);
    final semanticsBefore = tester.getSemantics(title).rect;
    expect(_ring, findsNothing);

    _timer(host).set(runningMinutes());
    await tester.pump();
    expect(_ring, findsOneWidget);
    expect(tester.getRect(title), before);
    expect(tester.getSemantics(title).rect, semanticsBefore);
    // Left of ⋮.
    expect(
      tester.getCenter(_ring).dx,
      lessThan(tester.getCenter(byIconButton('More')).dx),
    );

    _timer(host).set(const SleepTimerState.off());
    await tester.pump();
    expect(_ring, findsNothing);
    expect(tester.getRect(title), before);
    handle.dispose();
  });

  testWidgets('the title is centred on the screen, with or without the ring', (
    tester,
  ) async {
    final host = await _open(tester);
    expect(tester.getCenter(find.text('1/6')).dx, closeTo(195, 0.5));
    _timer(host).set(runningTracks());
    await tester.pump();
    expect(tester.getCenter(find.text('1/6')).dx, closeTo(195, 0.5));
  });

  testWidgets('a pull that starts at 25 % width, with no album, closes', (
    tester,
  ) async {
    final host = await _open(tester);
    final top = tester.getTopLeft(find.byType(NowPlayingHeader));
    final start = Offset(390 * 0.25, top.dy + nowPlayingHeaderHeight / 2);
    await tester.dragFrom(start, const Offset(0, 130));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(
      host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
      '/',
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('at 200 % text the header grows and nothing overflows', (
    tester,
  ) async {
    final host = await _open(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(NowPlayingHeader)).height,
      nowPlayingHeaderTallHeight,
    );
    _timer(host).set(runningMinutes());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap on the ring opens the timer on its running screen', (
    tester,
  ) async {
    final host = await _open(tester);
    _timer(host).set(runningMinutes());
    await tester.pump();
    await tester.tap(_ring);
    await tester.pumpAndSettle();
    expect(find.text('Turn off timer'), findsOneWidget);
  });

  testWidgets('Tắt removes the ring and focus lands on ⋮', (tester) async {
    final host = await _open(tester);
    _timer(host).set(runningMinutes());
    await tester.pump();
    await tester.tap(_ring);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Turn off timer'));
    expect(_timer(host).state.active, isFalse);
    expect(_ring, findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<KIconButton>(byIconButton('More'))
          .focusNode!
          .hasPrimaryFocus,
      isTrue,
    );
  });
}
