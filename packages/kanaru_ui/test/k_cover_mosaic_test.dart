import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

KCoverTileBuilder _tile(String name) =>
    (context, w, h) => SizedBox(key: Key(name), width: w, height: h);

Widget _mosaic(int n, {BorderRadius? radius}) => Center(
  child: KCoverMosaic(
    size: 100,
    radius: radius,
    tiles: [for (var i = 0; i < n; i++) _tile('t$i')],
  ),
);

Rect _rect(WidgetTester tester, String name) {
  final box = tester.renderObject<RenderBox>(find.byKey(Key(name)));
  return box.localToGlobal(Offset.zero) & box.size;
}

void main() {
  testWidgets('2 tiles are two vertical halves', (tester) async {
    await tester.pumpWidget(host(_mosaic(2)));
    final root = tester.getTopLeft(find.byType(KCoverMosaic));
    expect(_rect(tester, 't0'), root & const Size(50, 100));
    expect(
      _rect(tester, 't1'),
      (root + const Offset(50, 0)) & const Size(50, 100),
    );
  });

  testWidgets('3 tiles: tall half on the left, two squares on the right', (
    tester,
  ) async {
    await tester.pumpWidget(host(_mosaic(3)));
    final root = tester.getTopLeft(find.byType(KCoverMosaic));
    expect(_rect(tester, 't0'), root & const Size(50, 100));
    expect(
      _rect(tester, 't1'),
      (root + const Offset(50, 0)) & const Size(50, 50),
    );
    expect(
      _rect(tester, 't2'),
      (root + const Offset(50, 50)) & const Size(50, 50),
    );
  });

  testWidgets('4 tiles are a 2 x 2 grid of squares', (tester) async {
    await tester.pumpWidget(host(_mosaic(4)));
    final root = tester.getTopLeft(find.byType(KCoverMosaic));
    expect(_rect(tester, 't0'), root & const Size(50, 50));
    expect(
      _rect(tester, 't1'),
      (root + const Offset(50, 0)) & const Size(50, 50),
    );
    expect(
      _rect(tester, 't2'),
      (root + const Offset(0, 50)) & const Size(50, 50),
    );
    expect(
      _rect(tester, 't3'),
      (root + const Offset(50, 50)) & const Size(50, 50),
    );
  });

  testWidgets('the mosaic is square and clipped by the radius', (tester) async {
    const radius = BorderRadius.all(Radius.circular(12));
    await tester.pumpWidget(host(_mosaic(4, radius: radius)));
    expect(tester.getSize(find.byType(KCoverMosaic)), const Size(100, 100));
    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(KCoverMosaic),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, radius);
  });

  test('fewer than 2 or more than 4 tiles is refused', () {
    expect(
      () => KCoverMosaic(size: 100, tiles: [_tile('a')]),
      throwsAssertionError,
    );
    expect(
      () => KCoverMosaic(
        size: 100,
        tiles: [for (var i = 0; i < 5; i++) _tile('t$i')],
      ),
      throwsAssertionError,
    );
  });
}
