import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

const _row = 48.0;
const _gap = 2.0;
const _box = 8 * _row + 7 * _gap;

Widget _list(
  int count, {
  List<int>? built,
  ScrollController? outer,
  bool withNeighbours = false,
}) {
  final list = KCappedList(
    itemCount: count,
    rowExtent: _row,
    gap: _gap,
    itemBuilder: (context, i) {
      built?.add(i);
      return Text('row $i', key: ValueKey('row$i'));
    },
  );
  if (!withNeighbours) return SingleChildScrollView(child: list);
  return ListView(
    controller: outer,
    children: [
      const SizedBox(height: 100, child: Text('before')),
      list,
      const SizedBox(height: 1500, child: Text('after')),
    ],
  );
}

void main() {
  testWidgets('8 rows or fewer: full height, no box, no fade', (tester) async {
    useWindow(tester, const Size(500, 1200));
    await tester.pumpWidget(host(_list(8)));
    expect(find.byType(Scrollbar), findsNothing);
    expect(find.byType(ListView), findsNothing);
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(ValueKey('row$i')), findsOneWidget);
    }
    expect(tester.getSize(find.byType(KCappedList)).height, _box);
    expect(cappedTopFade, findsNothing);
    expect(cappedBottomFade, findsNothing);
  });

  testWidgets('3 rows take 3 rows of height', (tester) async {
    await tester.pumpWidget(host(_list(3)));
    expect(
      tester.getSize(find.byType(KCappedList)).height,
      3 * _row + 2 * _gap,
    );
  });

  testWidgets('more than 8: box is exactly 8 rows tall', (tester) async {
    useWindow(tester, const Size(500, 1200));
    await tester.pumpWidget(host(_list(20)));
    expect(tester.getSize(find.byType(KCappedList)).height, _box);
    // The 8th row ends at the bottom edge; the 9th is outside the box.
    final box = tester.getRect(find.byType(KCappedList));
    expect(
      tester.getRect(find.byKey(const ValueKey('row7'))).bottom,
      box.bottom,
    );
  });

  testWidgets('builds only the rows in view, not all 1000', (tester) async {
    useWindow(tester, const Size(500, 1200));
    final built = <int>[];
    await tester.pumpWidget(host(_list(1000, built: built)));
    expect(built.toSet().length, lessThan(14));
    expect(built.toSet(), containsAll([0, 7]));
    built.clear();
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(built.toSet().length, lessThan(40));
    expect(find.byKey(const ValueKey('row0')), findsNothing);
  });

  testWidgets('fades: bottom at start, both in the middle, top at the end', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 1200));
    await tester.pumpWidget(host(_list(20)));
    expect(cappedTopFade, findsNothing);
    expect(cappedBottomFade, findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(cappedTopFade, findsOneWidget);
    expect(cappedBottomFade, findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(cappedTopFade, findsOneWidget);
    expect(cappedBottomFade, findsNothing);
    expect(find.byKey(const ValueKey('row19')), findsOneWidget);
  });

  testWidgets('scrolls on its own: offset follows the drag', (tester) async {
    useWindow(tester, const Size(500, 1200));
    await tester.pumpWidget(host(_list(20)));
    final state = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(state.position.pixels, 100);
  });

  testWidgets('at the end of the box a drag moves the outer list', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 700));
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester.pumpWidget(
      host(_list(12, outer: outer, withNeighbours: true)),
    );
    final inner = find.byType(KCappedList);
    // Reach the end of the box (12 rows: 4 rows of travel).
    await tester.drag(
      find.descendant(of: inner, matching: find.byType(ListView)),
      const Offset(0, -4 * (_row + _gap)),
    );
    await tester.pumpAndSettle();
    expect(outer.offset, 0);
    // Still dragging up at the end: the page scrolls.
    await tester.drag(
      find.descendant(of: inner, matching: find.byType(ListView)),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    expect(outer.offset, greaterThan(100));
    // And back down at the start of the box: the page scrolls back.
    outer.jumpTo(300);
    final innerList = find.descendant(
      of: inner,
      matching: find.byType(ListView),
    );
    await tester.drag(innerList, const Offset(0, 4 * (_row + _gap) + 100));
    await tester.pumpAndSettle();
    expect(outer.offset, lessThan(300));
  });

  testWidgets('scrollbar only on the desktop shell', (tester) async {
    useWindow(tester, const Size(500, 1200));
    await tester.pumpWidget(host(_list(20)));
    expect(find.byType(Scrollbar), findsNothing);
    useWindow(tester, const Size(1400, 1200));
    await tester.pumpWidget(host(_list(20)));
    await tester.pump();
    expect(find.byType(Scrollbar), findsOneWidget);
  });

  testWidgets('animations off: fades switch at once', (tester) async {
    useWindow(tester, const Size(500, 1200));
    await tester.pumpWidget(host(_list(20), reduceMotion: true));
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    expect(cappedTopFade, findsOneWidget);
  });

  testWidgets('semantic label names the list', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        KCappedList(
          itemCount: 20,
          rowExtent: _row,
          semanticLabel: '20 bài',
          itemBuilder: (_, i) => Text('$i'),
        ),
      ),
    );
    expect(find.bySemanticsLabel('20 bài'), findsOneWidget);
    handle.dispose();
  });
}
