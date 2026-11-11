import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/flight_source.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/shared_flight.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

class _Value extends ValueNotifier<double> {
  _Value(super.value);
}

void main() {
  group('flight progress', () {
    test('is the route value while nothing is pulled', () {
      final route = _Value(0.4);
      final drag = _Value(0);
      final p = QueueFlightProgress(route: route, drag: drag);
      addTearDown(p.dispose);
      expect(p.value, 0.4);
      route.value = 1;
      expect(p.value, 1);
    });

    test('follows the drag: progress = drag offset', () {
      final route = _Value(1);
      final drag = _Value(0);
      final p = QueueFlightProgress(route: route, drag: drag);
      addTearDown(p.dispose);
      drag.value = QueueFlightProgress.dragRange / 2;
      expect(p.value, closeTo(0.5, 1e-9));
      drag.value = QueueFlightProgress.dragRange * 3;
      expect(p.value, 0);
    });

    test('closing carries on from where the finger left it', () {
      final route = _Value(1);
      final drag = _Value(100);
      final p = QueueFlightProgress(route: route, drag: drag);
      addTearDown(p.dispose);
      final atRelease = p.value;
      route.value = 0.99;
      expect(p.value, lessThan(atRelease));
      route.value = 0;
      expect(p.value, 0);
    });

    test('notifies when either side moves', () {
      final route = _Value(0);
      final drag = _Value(0);
      final p = QueueFlightProgress(route: route, drag: drag);
      addTearDown(p.dispose);
      var calls = 0;
      p.addListener(() => calls++);
      route.value = 0.5;
      drag.value = 10;
      expect(calls, 2);
    });
  });

  group('flight layers', () {
    const strip = KQueueStripGeometry(width: 390, topInset: 20);

    test('one layer per piece, each ending in the strip', () {
      final source = FlightSource();
      addTearDown(source.dispose);
      final layers = queueFlightLayers(source, strip);
      expect(layers.map((l) => l.to), [
        strip.cover,
        strip.text,
        strip.play,
        strip.next,
      ]);
    });

    test('a source that is not mounted has no start rect', () {
      final source = FlightSource();
      addTearDown(source.dispose);
      final layers = queueFlightLayers(source, strip);
      expect(layers.every((l) => l.from == null), isTrue);
    });

    testWidgets('a mounted source gives the rect of its piece', (tester) async {
      final source = FlightSource();
      addTearDown(source.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: FlightPieceHost(
                source: source,
                piece: FlightPiece.cover,
                child: const SizedBox(width: 120, height: 120),
              ),
            ),
          ),
        ),
      );
      expect(
        source.rectOf(FlightPiece.cover),
        const Rect.fromLTWH(30, 30, 120, 120),
      );
      expect(source.rectOf(FlightPiece.next), isNull);
    });

    testWidgets('hiding keeps the piece laid out but invisible', (
      tester,
    ) async {
      final source = FlightSource();
      addTearDown(source.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: FlightPieceHost(
            source: source,
            piece: FlightPiece.play,
            child: const SizedBox(width: 56, height: 56),
          ),
        ),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
      source.setHidden(true);
      await tester.pump();
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
      expect(source.rectOf(FlightPiece.play), isNotNull);
    });
  });
}
