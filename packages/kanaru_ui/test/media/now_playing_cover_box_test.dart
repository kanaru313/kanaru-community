import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  test('the side is min(420, width - 64)', () {
    expect(NowPlayingCoverBox.sideFor(360), 296);
    expect(NowPlayingCoverBox.sideFor(390), 326);
    expect(NowPlayingCoverBox.sideFor(484), 420);
    expect(NowPlayingCoverBox.sideFor(800), 420);
    expect(NowPlayingCoverBox.sideFor(40), 0);
  });

  for (final width in [360.0, 390.0, 800.0]) {
    testWidgets('a ${width.toInt()} dp column gets a square cover', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          NowPlayingCoverBox(
            builder: (context, side) => ColoredBox(
              key: const ValueKey('cover'),
              color: Colors.red,
              child: Text('$side'),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byKey(const ValueKey('cover')));
      expect(size.width, NowPlayingCoverBox.sideFor(width));
      expect(size.height, size.width);
      final rect = tester.getRect(find.byKey(const ValueKey('cover')));
      expect(rect.center.dx, closeTo(width / 2, 0.5));
    });
  }

  testWidgets('the cover has radius 20 and a shadow', (tester) async {
    await tester.pumpWidget(
      host(NowPlayingCoverBox(builder: (c, side) => const SizedBox())),
    );
    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clip.borderRadius, KRadius.lg);
    final decoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(NowPlayingCoverBox),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((decoration.decoration as BoxDecoration).boxShadow, isNotEmpty);
  });
}
