import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

Widget _block({
  bool collapsed = false,
  VoidCallback? onToggle,
  VoidCallback? onSeeAll,
  void Function(int)? onItem,
  int count = 12,
}) => Align(
  alignment: Alignment.topCenter,
  child: KShelfBlock(
    title: 'Albums',
    icon: KIcons.album,
    count: 40,
    collapsed: collapsed,
    onToggle: onToggle ?? () {},
    onSeeAll: onSeeAll,
    seeAllLabel: 'See all',
    itemCount: count,
    itemWidth: 128,
    height: 160,
    itemBuilder: (context, i) => GestureDetector(
      onTap: () => onItem?.call(i),
      child: ColoredBox(
        color: const Color(0xFF999999),
        child: Center(child: Text('item $i')),
      ),
    ),
  ),
);

Color _cardFill(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(KShelfBlock),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders head and items ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_block(), brightness: brightness, textScale: scale),
      );
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('item 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('card fill is the row fill', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_block(), brightness: Brightness.dark));
    expect(_cardFill(tester), KRowColors.fill(Brightness.dark));
  });

  for (final collapsed in [false, true]) {
    testWidgets('head reports expanded=${!collapsed}', (tester) async {
      useWindow(tester, const Size(400, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_block(collapsed: collapsed)));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Albums, 40')),
        isSemantics(
          label: 'Albums, 40',
          isButton: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: !collapsed,
        ),
      );
      handle.dispose();
    });
  }

  testWidgets('tapping the head toggles, see-all does not', (tester) async {
    useWindow(tester, const Size(400, 800));
    var toggled = 0;
    var seeAll = 0;
    await tester.pumpWidget(
      host(_block(onToggle: () => toggled++, onSeeAll: () => seeAll++)),
    );
    await tester.tap(find.text('Albums'));
    expect(toggled, 1);
    expect(seeAll, 0);
    await tester.tap(byIconButton('See all'));
    expect(seeAll, 1);
    expect(toggled, 1);
  });

  testWidgets('Enter and Space on the focused head toggle', (tester) async {
    useWindow(tester, const Size(400, 800));
    var toggled = 0;
    await tester.pumpWidget(host(_block(onToggle: () => toggled++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(toggled, 2);
  });

  testWidgets('no see-all button without onSeeAll', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_block()));
    expect(find.bySemanticsLabel('See all'), findsNothing);
    await tester.pumpWidget(host(_block(onSeeAll: () {})));
    expect(find.bySemanticsLabel('See all'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('collapsing shrinks the body to zero and hides items', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(host(_block(onItem: (_) => taps++)));
    final open = tester.getSize(find.byKey(KShelfBlock.bodyKey)).height;
    expect(open, 172);
    await tester.pumpWidget(
      host(_block(collapsed: true, onItem: (_) => taps++)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(KShelfBlock.bodyKey)).height, 0);
    await tester.tapAt(
      tester.getCenter(find.text('item 0'), warnIfMissed: false),
    );
    expect(taps, 0);
  });

  testWidgets('reduced motion collapses in one frame', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_block(), reduceMotion: true));
    await tester.pumpWidget(host(_block(collapsed: true), reduceMotion: true));
    await tester.pump();
    expect(tester.getSize(find.byKey(KShelfBlock.bodyKey)).height, 0);
  });

  testWidgets('mouse drag scrolls the row without tapping an item', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final taps = <int>[];
    await tester.pumpWidget(host(_block(onItem: taps.add)));
    expect(find.text('item 11'), findsNothing);
    await tester.drag(
      find.text('item 1'),
      const Offset(-3000, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('item 11'), findsOneWidget);
    expect(taps, isEmpty);
  });

  testWidgets('hovering the head does not change the card fill', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_block()));
    final before = _cardFill(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Albums')));
    await tester.pump();
    expect(_cardFill(tester), before);
    expect(find.byType(InkWell), findsNothing);
  });
}
