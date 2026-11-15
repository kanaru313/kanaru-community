import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/src/widgets/collections/k_end_hit_extension.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget probe(
    TextDirection direction,
    List<Offset> taps, {
    double width = 40,
  }) => Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: KEndHitExtension(
        extent: 16,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => taps.add(d.localPosition),
          child: SizedBox(width: width, height: 40),
        ),
      ),
    ),
  );

  for (final direction in TextDirection.values) {
    testWidgets('the strip after the child reaches it ($direction)', (
      tester,
    ) async {
      final taps = <Offset>[];
      await tester.pumpWidget(probe(direction, taps));
      final box = tester.getRect(find.byType(KEndHitExtension));
      final child = tester.getRect(find.byType(SizedBox).last);
      expect(box.width, 56);
      final rtl = direction == TextDirection.rtl;
      // The strip is on the end side: right in LTR, left in RTL.
      expect(rtl ? child.left - box.left : box.right - child.right, 16);
      expect(rtl ? box.right - child.right : child.left - box.left, 0);

      final strip = rtl ? box.left + 8 : box.right - 8;
      await tester.tapAt(Offset(strip, 20));
      // The position the child sees is local to the child, wherever it sits:
      // 8 dp past its end edge (LTR), 8 dp before its start edge (RTL).
      expect(taps.single, Offset(rtl ? -8 : 48, 20));

      taps.clear();
      await tester.tapAt(child.center);
      expect(taps.single, const Offset(20, 20));
    });
  }

  testWidgets('a child without width does not throw on a tap in the strip', (
    tester,
  ) async {
    final taps = <Offset>[];
    await tester.pumpWidget(probe(TextDirection.ltr, taps, width: 0));
    await tester.tapAt(const Offset(8, 20));
    expect(tester.takeException(), isNull);
  });
}
