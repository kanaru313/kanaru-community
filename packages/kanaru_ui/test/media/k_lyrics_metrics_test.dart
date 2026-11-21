import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

KLyricsMetrics _resolve(
  KLyricsSurface surface,
  double width, {
  double height = 800,
  bool cover = true,
}) => KLyricsMetrics.resolve(
  surface: surface,
  width: width,
  height: height,
  coverColumnShown: cover,
);

void main() {
  group('screen', () {
    test('phone width: 25 with 24 padding', () {
      final m = _resolve(KLyricsSurface.screen, 599);
      expect((m.lineSize, m.sidePadding), (25, 24));
    });

    test('tablet width from 600: 34 with 56 padding', () {
      final m = _resolve(KLyricsSurface.screen, 600);
      expect((m.lineSize, m.sidePadding), (34, 56));
    });
  });

  group('tab', () {
    test('pane below 900: 22 with 24 padding, cover column or not', () {
      for (final cover in [true, false]) {
        final m = _resolve(KLyricsSurface.tab, 899, cover: cover);
        expect((m.lineSize, m.sidePadding), (22, 24));
      }
    });

    test('pane of 900 or more with the cover column: 28 with 40', () {
      final m = _resolve(KLyricsSurface.tab, 900);
      expect((m.lineSize, m.sidePadding), (28, 40));
    });

    test('cover column hidden: 36 with 12 % of the pane width', () {
      final m = _resolve(KLyricsSurface.tab, 1000, cover: false);
      expect(m.lineSize, 36);
      expect(m.sidePadding, closeTo(120, 1e-9));
    });
  });

  test('card: 18 with no padding of its own', () {
    final m = _resolve(KLyricsSurface.card, 380);
    expect((m.lineSize, m.sidePadding), (18, 0));
    expect(KLyricsMetrics.cardPlainLineSize, 15);
  });

  test('the viewport height is passed through', () {
    expect(
      _resolve(KLyricsSurface.screen, 400, height: 531).viewportHeight,
      531,
    );
  });

  testWidgets('the builder measures its own box, not the window', (
    tester,
  ) async {
    KLyricsMetrics? seen;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 700,
            height: 500,
            child: KLyricsMetricsBuilder(
              surface: KLyricsSurface.tab,
              builder: (context, m) {
                seen = m;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(seen?.lineSize, 22);
    expect(seen?.viewportHeight, 500);
  });

  testWidgets('an unbounded height gives a zero viewport height', (
    tester,
  ) async {
    KLyricsMetrics? seen;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: KLyricsMetricsBuilder(
            surface: KLyricsSurface.screen,
            builder: (context, m) {
              seen = m;
              return const SizedBox(height: 10);
            },
          ),
        ),
      ),
    );
    expect(seen?.viewportHeight, 0);
  });
}
