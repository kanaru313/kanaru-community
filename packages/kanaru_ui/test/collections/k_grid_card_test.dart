import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _grid({
  required double scale,
  bool circle = false,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) {
  return Builder(
    builder: (context) => CustomScrollView(
      slivers: [
        KCollectionGrid(
          itemCount: 4,
          mobileMinTileWidth: 150,
          desktopMinTileWidth: 160,
          footerExtent: KGridCard.footerExtent(
            MediaQuery.textScalerOf(context),
          ),
          itemBuilder: (context, i) => KGridCard(
            circle: circle,
            title: 'Title $i',
            subtitle: 'Sub $i',
            onTap: onTap,
            onLongPress: onLongPress,
            coverBuilder: (context, side) =>
                SizedBox.square(key: ValueKey('cover$i'), dimension: side),
          ),
        ),
      ],
    ),
  );
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('the cover is as wide as the tile, no overflow ($name)', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          _grid(scale: scale),
          brightness: brightness,
          textScale: scale,
        ),
      );
      final cover = tester.getSize(find.byKey(const ValueKey('cover0')));
      final tile = tester.getSize(find.byType(KGridCard).first);
      expect(cover.width, cover.height);
      expect(cover.width, tile.width);
      expect(find.text('Title 0'), findsOneWidget);
      expect(find.text('Sub 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('footerExtent pins the laid-out height under the cover', (
    tester,
  ) async {
    for (final scale in [1.0, 1.5]) {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_grid(scale: scale), textScale: scale));
      final cover = tester.getSize(find.byKey(const ValueKey('cover0')));
      final column = tester.getSize(
        find.descendant(
          of: find.byType(KGridCard).first,
          matching: find.byType(Column),
        ),
      );
      expect(
        column.height - cover.height,
        closeTo(KGridCard.footerExtent(TextScaler.linear(scale)), 0.5),
      );
    }
  });

  testWidgets('tap and long press reach the callbacks', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    var longs = 0;
    await tester.pumpWidget(
      host(_grid(scale: 1, onTap: () => taps++, onLongPress: () => longs++)),
    );
    await tester.tap(find.text('Title 0'));
    await tester.longPress(find.text('Title 0'));
    expect([taps, longs], [1, 1]);
  });

  testWidgets('a round card centres its texts', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_grid(scale: 1, circle: true)));
    expect(
      tester.widget<Text>(find.text('Title 0')).textAlign,
      TextAlign.center,
    );
  });
}
