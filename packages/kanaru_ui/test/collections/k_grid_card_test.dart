import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _grid({
  required double scale,
  bool circle = false,
  bool filled = false,
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
            filled: filled,
          ),
          itemBuilder: (context, i) => KGridCard(
            circle: circle,
            filled: filled,
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

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('a filled card insets its cover, no overflow ($name)', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          _grid(scale: scale, filled: true),
          brightness: brightness,
          textScale: scale,
        ),
      );
      final cover = tester.getRect(find.byKey(const ValueKey('cover0')));
      final tile = tester.getRect(find.byType(KGridCard).first);
      expect(cover.width, cover.height);
      expect(cover.width, tile.width - 2 * KGridCard.filledInset);
      expect(cover.top - tile.top, KGridCard.filledInset);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('footerExtent of a filled card pins the tile height', (
    tester,
  ) async {
    for (final scale in [1.0, 1.5]) {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_grid(scale: scale, filled: true), textScale: scale),
      );
      final tile = tester.getRect(find.byType(KGridCard).first);
      final card = tester.getRect(
        find
            .descendant(
              of: find.byType(KGridCard).first,
              matching: find.byType(Padding),
            )
            .first,
      );
      final scaler = TextScaler.linear(scale);
      expect(
        card.height - tile.width,
        closeTo(KGridCard.footerExtent(scaler, filled: true), 0.5),
      );
    }
  });

  testWidgets('a third line and the badge fit the extent, no overflow', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              final scaler = MediaQuery.textScalerOf(context);
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 180,
                  height:
                      180 +
                      KGridCard.footerExtent(
                        scaler,
                        filled: true,
                        detail: true,
                      ),
                  child: KGridCard(
                    filled: true,
                    title: 'T',
                    subtitle: 'S',
                    detail: 'D',
                    coverBadge: const SizedBox.square(
                      key: ValueKey('badge'),
                      dimension: 32,
                    ),
                    coverBuilder: (context, side) =>
                        SizedBox.square(dimension: side),
                  ),
                ),
              );
            },
          ),
          textScale: scale,
        ),
      );
      expect(find.text('D'), findsOneWidget);
      expect(find.byKey(const ValueKey('badge')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('selected and playing states reach screen readers', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    Widget card({required bool selected, required bool current}) => host(
      SizedBox(
        width: 180,
        child: KGridCard(
          filled: true,
          title: 'T',
          selected: selected,
          selecting: true,
          current: current,
          currentLabel: 'Now playing',
          coverBuilder: (context, side) => SizedBox.square(dimension: side),
          onTap: () {},
        ),
      ),
    );
    await tester.pumpWidget(card(selected: true, current: false));
    expect(
      tester.getSemantics(find.byType(KGridCard)),
      isSemantics(isSelected: true),
    );
    await tester.pumpWidget(card(selected: false, current: true));
    expect(
      tester.getSemantics(find.byType(KGridCard)),
      isSemantics(isSelected: false, value: 'Now playing'),
    );
    handle.dispose();
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

  testWidgets('no more button; the menu is a screen-reader action', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var menus = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 180,
          child: KGridCard(
            title: 'T',
            coverBuilder: (context, side) => SizedBox.square(dimension: side),
            onMenu: () => menus++,
            menuLabel: 'More options',
          ),
        ),
      ),
    );
    expect(find.byType(IconButton), findsNothing);
    final node = tester.getSemantics(find.byType(KGridCard));
    final data = node.getSemanticsData();
    final id = data.customSemanticsActionIds!.single;
    expect(CustomSemanticsAction.getAction(id)!.label, 'More options');
    tester.semantics.performAction(
      find.semantics.byLabel(RegExp('^T')),
      SemanticsAction.customAction,
      args: id,
    );
    expect(menus, 1);
    handle.dispose();
  });

  testWidgets('without onMenu the card has no custom action', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 180,
          child: KGridCard(
            title: 'T',
            coverBuilder: (context, side) => SizedBox.square(dimension: side),
          ),
        ),
      ),
    );
    final data = tester.getSemantics(find.byType(KGridCard)).getSemanticsData();
    expect(data.customSemanticsActionIds, anyOf(isNull, isEmpty));
    handle.dispose();
  });

  for (final filled in [false, true]) {
    testWidgets('every text line has a forced height (filled: $filled)', (
      tester,
    ) async {
      // A fallback font (CJK on Android) is taller than the theme font; only
      // a forced strut keeps the card at its footerExtent.
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 180,
            child: KGridCard(
              filled: filled,
              title: 'ありがとう',
              subtitle: 'Artist',
              detail: filled ? 'Album • 3:00' : null,
              coverBuilder: (context, side) => SizedBox.square(dimension: side),
            ),
          ),
        ),
      );
      final lines = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(lines, hasLength(filled ? 3 : 2));
      for (final line in lines) {
        expect(line.strutStyle?.forceStrutHeight, isTrue, reason: line.data);
      }
    });
  }
}
