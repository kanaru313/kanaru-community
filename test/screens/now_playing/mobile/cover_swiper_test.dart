import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/cover_swiper.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A 400 dp wide swiper, so the cover is 336 dp: 25 % is 84 dp.
Widget _swiper({
  required int entry,
  bool hasPrevious = true,
  bool hasNext = true,
  required List<String> events,
}) => MaterialApp(
  theme: buildKanaruTheme(brightness: Brightness.light),
  home: Scaffold(
    body: CoverSwiper(
      entryId: entry,
      hasPrevious: hasPrevious,
      hasNext: hasNext,
      onPrevious: () => events.add('previous'),
      onNext: () => events.add('next'),
      child: NowPlayingCoverBox(
        builder: (context, side) => ColoredBox(
          key: const ValueKey('cover'),
          color: Colors.teal,
          child: Text('$entry'),
        ),
      ),
    ),
  ),
);

Future<void> _pumpApp(WidgetTester tester, Widget app) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

double _x(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const ValueKey('cover'))).dx;

void main() {
  const resting = 32.0; // (400 - 336) / 2

  testWidgets('a slow drag past 25 % changes to the next track', (
    tester,
  ) async {
    final events = <String>[];
    await _pumpApp(tester, _swiper(entry: 1, events: events));
    await tester.timedDrag(
      find.byKey(const ValueKey('cover')),
      const Offset(-90, 0),
      const Duration(seconds: 1),
    );
    await tester.pump();
    expect(events, ['next']);
  });

  testWidgets('a slow drag short of 25 % springs back', (tester) async {
    final events = <String>[];
    await _pumpApp(tester, _swiper(entry: 1, events: events));
    await tester.timedDrag(
      find.byKey(const ValueKey('cover')),
      const Offset(80, 0),
      const Duration(seconds: 1),
    );
    await tester.pump();
    expect(events, isEmpty);
    await _settle(tester);
    expect(_x(tester), closeTo(resting, 0.5));
  });

  testWidgets('a fast fling changes track even over a short distance', (
    tester,
  ) async {
    final events = <String>[];
    await _pumpApp(tester, _swiper(entry: 1, events: events));
    // 40 dp in 40 ms: 1000 dp/s, well over the fling limit.
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('cover'))),
    );
    for (var i = 1; i <= 4; i++) {
      await g.moveBy(
        const Offset(10, 0),
        timeStamp: Duration(milliseconds: 10 * i),
      );
    }
    await g.up(timeStamp: const Duration(milliseconds: 40));
    await tester.pump();
    expect(events, ['previous']);
  });

  testWidgets('the cover follows the finger', (tester) async {
    await _pumpApp(tester, _swiper(entry: 1, events: []));
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('cover'))),
    );
    await g.moveBy(const Offset(-50, 0));
    await tester.pump();
    expect(_x(tester), closeTo(resting - 50, 0.5));
    await g.cancel();
  });

  testWidgets('at the last entry it moves at most 30 % and bounces back', (
    tester,
  ) async {
    final events = <String>[];
    await _pumpApp(tester, _swiper(entry: 6, hasNext: false, events: events));
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('cover'))),
    );
    await g.moveBy(const Offset(-200, 0));
    await tester.pump();
    expect(_x(tester), closeTo(resting - 0.3 * 336, 0.5));
    await g.up();
    await _settle(tester);
    expect(events, isEmpty);
    expect(_x(tester), closeTo(resting, 0.5));
  });

  testWidgets('at the first entry a right swipe is limited the same way', (
    tester,
  ) async {
    final events = <String>[];
    await _pumpApp(
      tester,
      _swiper(entry: 1, hasPrevious: false, events: events),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('cover'))),
    );
    await g.moveBy(const Offset(250, 0));
    await tester.pump();
    expect(_x(tester), closeTo(resting + 0.3 * 336, 0.5));
    await g.up();
    await _settle(tester);
    expect(events, isEmpty);
  });

  testWidgets('a vertical drag is left to the page', (tester) async {
    final events = <String>[];
    await _pumpApp(tester, _swiper(entry: 1, events: events));
    await tester.drag(
      find.byKey(const ValueKey('cover')),
      const Offset(0, 150),
    );
    await tester.pump();
    expect(events, isEmpty);
    expect(_x(tester), resting);
  });

  testWidgets('the new cover slides in once the track has changed', (
    tester,
  ) async {
    final events = <String>[];
    await _pumpApp(tester, _swiper(entry: 1, events: events));
    await tester.timedDrag(
      find.byKey(const ValueKey('cover')),
      const Offset(-120, 0),
      const Duration(seconds: 1),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // Out of the way, the controller moves on.
    expect(_x(tester), lessThan(0));
    await tester.pumpWidget(_swiper(entry: 2, events: events));
    await tester.pump();
    expect(_x(tester), greaterThan(resting));
    await _settle(tester);
    expect(_x(tester), closeTo(resting, 0.5));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('it comes back when the track never changes', (tester) async {
    final events = <String>[];
    await _pumpApp(tester, _swiper(entry: 1, events: events));
    await tester.timedDrag(
      find.byKey(const ValueKey('cover')),
      const Offset(-120, 0),
      const Duration(seconds: 1),
    );
    await tester.pump(const Duration(seconds: 2));
    await _settle(tester);
    expect(_x(tester), closeTo(resting, 0.5));
  });
}
