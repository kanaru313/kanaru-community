import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _grid({double mobileMin = 150, double desktopMin = 160, int n = 20}) =>
    CustomScrollView(
      slivers: [
        KCollectionGrid(
          itemCount: n,
          mobileMinTileWidth: mobileMin,
          desktopMinTileWidth: desktopMin,
          footerExtent: 40,
          itemBuilder: (context, i) => Text('tile $i', key: ValueKey(i)),
        ),
      ],
    );

int _columns(WidgetTester tester) {
  final firstY = tester.getTopLeft(find.byKey(const ValueKey(0))).dy;
  var count = 0;
  for (var i = 0; i < 20; i++) {
    final f = find.byKey(ValueKey(i));
    if (f.evaluate().isEmpty) break;
    if (tester.getTopLeft(f).dy == firstY) count++;
  }
  return count;
}

void main() {
  test('columnsFor fits as many tiles as the width allows', () {
    expect(KCollectionGrid.columnsFor(368, 150, 12), 2);
    expect(KCollectionGrid.columnsFor(100, 150, 12), 1);
    expect(KCollectionGrid.columnsFor(0, 150, 12), 1);
    expect(KCollectionGrid.columnsFor(1268, 160, 12), 7);
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('lays out tiles ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_grid(), brightness: brightness, textScale: scale),
      );
      expect(find.text('tile 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile uses the mobile minimum', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_grid()));
    expect(_columns(tester), 2);
  });

  testWidgets('a smaller minimum gives more columns (artists)', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_grid(mobileMin: 100)));
    expect(_columns(tester), 3);
  });

  testWidgets('desktop uses the desktop minimum', (tester) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_grid()));
    expect(_columns(tester), 7);
    await tester.pumpWidget(host(_grid(desktopMin: 220)));
    expect(_columns(tester), 5);
  });

  testWidgets('tile height is cover plus footer', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_grid()));
    final y0 = tester.getTopLeft(find.byKey(const ValueKey(0))).dy;
    final y2 = tester.getTopLeft(find.byKey(const ValueKey(2))).dy;
    // inner 368, 2 columns, tile width 178: 178 + 40 + 12 spacing.
    expect(y2 - y0, closeTo(178 + 40 + 12, 0.01));
  });
}
