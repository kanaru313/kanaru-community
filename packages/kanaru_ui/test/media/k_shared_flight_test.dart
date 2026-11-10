import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

const _from = Rect.fromLTWH(10, 100, 200, 200);
const _to = Rect.fromLTWH(20, 20, 72, 72);

KFlightLayer _layer({Rect? from = _from, List<double>? seen}) => KFlightLayer(
  from: from,
  to: _to,
  builder: (context, rect, t) {
    seen?.add(t);
    return ColoredBox(key: const ValueKey('piece'), color: Colors.red);
  },
);

void main() {
  stripGeometryTests();

  test('rects at t = 0, 0.5 and 1', () {
    final layer = _layer();
    expect(KSharedFlight.rectAt(layer, 0), _from);
    expect(
      KSharedFlight.rectAt(layer, 0.5),
      const Rect.fromLTWH(15, 60, 136, 136),
    );
    expect(KSharedFlight.rectAt(layer, 1), _to);
  });

  test('progress outside 0..1 is clamped', () {
    final layer = _layer();
    expect(KSharedFlight.rectAt(layer, -1), _from);
    expect(KSharedFlight.rectAt(layer, 2), _to);
  });

  test('a layer without a source stays at its target and fades in', () {
    final layer = _layer(from: null);
    expect(KSharedFlight.rectAt(layer, 0.3), _to);
    expect(KSharedFlight.opacityAt(layer, 0.3), 0.3);
    expect(KSharedFlight.opacityAt(_layer(), 0.3), 1);
  });

  test('reduced motion jumps to the target and fades', () {
    final layer = _layer();
    expect(KSharedFlight.rectAt(layer, 0.3, fade: true), _to);
    expect(KSharedFlight.opacityAt(layer, 0.3, fade: true), 0.3);
  });

  testWidgets('the piece moves with the progress value', (tester) async {
    final progress = ValueNotifier<double>(0);
    addTearDown(progress.dispose);
    final seen = <double>[];
    await tester.pumpWidget(
      host(
        SizedBox.expand(
          child: KSharedFlight(
            progress: progress,
            layers: [_layer(seen: seen)],
          ),
        ),
      ),
    );
    Rect rect() => tester.getRect(find.byKey(const ValueKey('piece')));
    final origin = tester.getTopLeft(find.byType(KSharedFlight));
    expect(rect(), _from.shift(origin));
    progress.value = 0.5;
    await tester.pump();
    expect(rect().width, 136);
    progress.value = 1;
    await tester.pump();
    expect(rect(), _to.shift(origin));
    expect(seen, containsAll([0.0, 0.5, 1.0]));
  });

  testWidgets('with reduced motion the piece is at the target at once', (
    tester,
  ) async {
    final progress = ValueNotifier<double>(0.5);
    addTearDown(progress.dispose);
    await tester.pumpWidget(
      host(
        SizedBox.expand(
          child: KSharedFlight(progress: progress, layers: [_layer()]),
        ),
        reduceMotion: true,
      ),
    );
    final origin = tester.getTopLeft(find.byType(KSharedFlight));
    expect(
      tester.getRect(find.byKey(const ValueKey('piece'))),
      _to.shift(origin),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
  });

  testWidgets('each layer repaints on its own', (tester) async {
    final progress = ValueNotifier<double>(0);
    addTearDown(progress.dispose);
    await tester.pumpWidget(
      host(
        SizedBox.expand(
          child: KSharedFlight(
            progress: progress,
            layers: [_layer(), _layer()],
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(KSharedFlight),
        matching: find.byType(RepaintBoundary),
      ),
      findsNWidgets(2),
    );
  });
}

void stripGeometryTests() {
  group('queue strip geometry', () {
    const g = KQueueStripGeometry(width: 400, topInset: 24);

    test('is as tall as its cover plus padding and the inset', () {
      expect(g.height, 24 + 8 + 72 + 8);
    });

    test('cover is 72 at the left, play 56 and next 48 at the right', () {
      expect(g.cover, const Rect.fromLTWH(16, 32, 72, 72));
      expect(g.next.size, const Size(48, 48));
      expect(g.next.right, 400 - 16);
      expect(g.play.size, const Size(56, 56));
      expect(g.play.right, g.next.left);
      expect(g.play.center.dy, g.cover.center.dy);
      expect(g.next.center.dy, g.cover.center.dy);
    });

    test('the text sits between the cover and the play button', () {
      expect(g.text.left, g.cover.right + 12);
      expect(g.text.right, lessThan(g.play.left));
      expect(g.text.height, 72);
    });

    testWidgets('the stage reports its size and the top inset', (tester) async {
      KQueueStripGeometry? seen;
      Size? size;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          KFlightStage(
            builder: (context, strip, s) {
              seen = strip;
              size = s;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen!.width, 360);
      expect(size!.width, 360);
    });
  });
}
