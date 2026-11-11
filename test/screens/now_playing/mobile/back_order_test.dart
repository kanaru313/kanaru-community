import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/playback/ui/flight_source.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/queue_sheet.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/ui_host.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Back: sheet, then Now Playing, then the screen under them', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(390, 844),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await host.letStreamsArrive(tester);
    await tester.tap(find.byTooltip('Queue'));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(QueueSheetPage), findsOneWidget);

    await _back(tester);
    expect(find.byType(QueueSheetPage), findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);

    await _back(tester);
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(find.text('home'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('from the mini player Back returns to the screen at once', (
    tester,
  ) async {
    final source = FlightSource();
    addTearDown(source.dispose);
    final host = await pumpWithPlayer(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showQueueSheet(context, from: source),
          child: const Text('open'),
        ),
      ),
      routes: _routes,
      size: const Size(390, 844),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(QueueSheetPage), findsOneWidget);
    expect(find.byType(MobileNowPlaying), findsNothing);
    await _back(tester);
    expect(find.byType(QueueSheetPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(host, isNotNull);
    await tester.pump(const Duration(seconds: 1));
  });
}
