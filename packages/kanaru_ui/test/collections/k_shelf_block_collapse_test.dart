import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

/// Block whose cards are focusable and count their taps.
Widget _block({
  bool collapsed = false,
  String title = 'Albums',
  List<FocusNode>? nodes,
  void Function(int)? onItem,
}) => Align(
  alignment: Alignment.topCenter,
  child: KShelfBlock(
    title: title,
    icon: KIcons.album,
    count: 40,
    collapsed: collapsed,
    onToggle: () {},
    itemCount: 4,
    itemWidth: 128,
    height: 160,
    itemBuilder: (context, i) => Focus(
      focusNode: nodes?[i],
      child: GestureDetector(
        onTap: () => onItem?.call(i),
        child: ColoredBox(
          color: const Color(0xFF999999),
          child: Center(child: Text('item $i')),
        ),
      ),
    ),
  ),
);

Icon _chevron(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(KIcons.collapse));

void main() {
  group('collapsed body is excluded', () {
    testWidgets('Tab skips the cards only when collapsed', (tester) async {
      useWindow(tester, const Size(400, 800));
      final nodes = List.generate(4, (_) => FocusNode());
      addTearDown(() {
        for (final n in nodes) {
          n.dispose();
        }
      });
      for (final collapsed in [false, true]) {
        await tester.pumpWidget(
          host(_block(collapsed: collapsed, nodes: nodes)),
        );
        await tester.pumpAndSettle();
        var reached = false;
        for (var i = 0; i < 8; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          reached |= nodes.any((n) => n.hasFocus);
        }
        expect(reached, !collapsed, reason: 'collapsed=$collapsed');
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });

    testWidgets('card semantics are absent only when collapsed', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_block()));
      expect(find.bySemanticsLabel('item 0'), findsOneWidget);
      await tester.pumpWidget(host(_block(collapsed: true)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('item 0'), findsNothing);
      handle.dispose();
    });

    testWidgets('a tap where a card was never reaches it while collapsing', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final taps = <int>[];
      await tester.pumpWidget(host(_block(onItem: taps.add)));
      final point = tester.getTopLeft(find.text('item 0')) + const Offset(2, 2);
      await tester.tapAt(point);
      expect(taps, [0], reason: 'tap works while expanded');
      taps.clear();
      await tester.pumpWidget(host(_block(collapsed: true, onItem: taps.add)));
      await tester.pump(const Duration(milliseconds: 20));
      // Body is still partly open here, so only the exclusion can stop it.
      expect(
        tester.getSize(find.byKey(KShelfBlock.bodyKey)).height,
        greaterThan(20),
      );
      await tester.tapAt(point);
      expect(taps, isEmpty);
    });
  });

  group('head title and count', () {
    Future<void> pumpTitle(WidgetTester tester, String title) async {
      useWindow(tester, const Size(300, 800));
      await tester.pumpWidget(host(_block(title: title)));
    }

    testWidgets('count follows the title directly', (tester) async {
      await pumpTitle(tester, 'Albums');
      final title = tester.getRect(find.text('Albums'));
      final count = tester.getRect(find.text('40'));
      expect(count.left - title.right, KSpace.x2);
    });

    testWidgets('long title gets more than half the row, then ellipsizes', (
      tester,
    ) async {
      await pumpTitle(tester, 'A very long shelf title that cannot fit at all');
      final row = tester.getRect(find.byType(KShelfBlock));
      final title = tester.getRect(
        find.text('A very long shelf title that cannot fit at all'),
      );
      final count = tester.getRect(find.text('40'));
      expect(title.width, greaterThan(row.width / 2));
      expect(count.left - title.right, KSpace.x2);
      expect(tester.takeException(), isNull);
    });
  });

  group('cursors', () {
    testWidgets('head is click, card row is grab then grabbing on drag', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_block()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      MouseCursor cursor() =>
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1)!;
      await mouse.moveTo(tester.getCenter(find.text('Albums')));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.click);
      final onRow = tester.getCenter(find.text('item 1'));
      await mouse.moveTo(onRow);
      await tester.pump();
      expect(cursor(), SystemMouseCursors.grab);
      await mouse.down(onRow);
      await tester.pump();
      expect(cursor(), SystemMouseCursors.grabbing);
      await mouse.up();
      await tester.pump();
      expect(cursor(), SystemMouseCursors.grab);
    });
  });

  group('chevron feedback', () {
    testWidgets('hover darkens the chevron to onSurface', (tester) async {
      // Hover highlights only show in the desktop (pointer) highlight mode.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_block()));
      final scheme = Theme.of(tester.element(find.byType(KShelfBlock)))
          .colorScheme;
      expect(_chevron(tester).color, scheme.onSurfaceVariant);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Albums')));
      await tester.pump();
      expect(_chevron(tester).color, scheme.onSurface);
      await mouse.moveTo(tester.getCenter(find.text('item 1')));
      await tester.pump();
      expect(_chevron(tester).color, scheme.onSurfaceVariant);
    });

    testWidgets('pressing the head halves the chevron opacity', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_block()));
      double opacity() => tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byIcon(KIcons.collapse),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      expect(opacity(), 1);
      final touch = await tester.startGesture(
        tester.getCenter(find.text('Albums')),
      );
      await tester.pump();
      expect(opacity(), 0.5);
      await touch.up();
      await tester.pump();
      expect(opacity(), 1);
    });
  });
}
