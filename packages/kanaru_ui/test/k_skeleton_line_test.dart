import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('one text line high, bar at its width share ($name)', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 200));
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: KSkeletonLine(fontSize: 14, widthFactor: 0.6),
            ),
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      final box = tester.getSize(find.byType(KSkeletonLine));
      expect(box.height, closeTo(14 * scale * 1.35, 0.001));
      expect(
        box.height,
        closeTo(KSkeletonLine.extentOf(TextScaler.linear(scale), 14), 0.001),
      );
      final bar = tester.getSize(
        find.descendant(
          of: find.byType(KSkeletonLine),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(bar.width, closeTo(120, 0.001));
      expect(bar.height, closeTo(14 * scale * 0.8, 0.001));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a given line height sets the box', (tester) async {
    await tester.pumpWidget(
      host(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            child: KSkeletonLine(fontSize: 12, widthFactor: 1, lineHeight: 2),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(KSkeletonLine)).height, 24);
  });

  testWidgets('carries no semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const KSkeletonLine(fontSize: 14, widthFactor: 0.5)),
    );
    expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
    semantics.dispose();
  });
}
