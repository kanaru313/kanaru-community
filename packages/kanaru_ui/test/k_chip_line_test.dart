import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _line(int n) => KChipLine(
  children: [
    for (var i = 0; i < n; i++)
      KChip(dense: true, label: Text('+${i + 1} ph'), onTap: () {}),
  ],
);

void main() {
  testWidgets('chips that fit are centred on one line, 8 dp apart', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 400));
    await tester.pumpWidget(host(_line(3)));
    final a = tester.getRect(find.byType(KChip).at(0));
    final b = tester.getRect(find.byType(KChip).at(1));
    final c = tester.getRect(find.byType(KChip).at(2));
    expect(b.left - a.right, 8);
    expect(a.top, c.top);
    expect((a.left + c.right) / 2, closeTo(200, 0.5));
  });

  testWidgets('too many chips scroll sideways, none wraps', (tester) async {
    useWindow(tester, const Size(200, 400));
    await tester.pumpWidget(host(_line(6)));
    expect(tester.takeException(), isNull);
    final tops = {
      for (var i = 0; i < 6; i++)
        tester.getTopLeft(find.byType(KChip).at(i)).dy,
    };
    expect(tops, hasLength(1));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('gap is 8 on touch and 6 on desktop', (tester) async {
    for (final (size, gap) in [
      (const Size(400, 400), 8.0),
      (const Size(1300, 800), 6.0),
    ]) {
      useWindow(tester, size);
      await tester.pumpWidget(host(_line(2)));
      await tester.pumpAndSettle();
      final a = tester.getRect(find.byType(KChip).at(0));
      final b = tester.getRect(find.byType(KChip).at(1));
      expect(b.left - a.right, gap);
    }
  });

  testWidgets('edges fade only while the chips overflow', (tester) async {
    useWindow(tester, const Size(320, 400));
    await tester.pumpWidget(host(SizedBox(width: 288, child: _line(6))));
    await tester.pumpAndSettle();
    expect(find.byType(ShaderMask), findsOneWidget);

    await tester.pumpWidget(host(SizedBox(width: 288, child: _line(2))));
    await tester.pumpAndSettle();
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('chips that fit in a 288 parent at 320 are centred in it', (
    tester,
  ) async {
    useWindow(tester, const Size(320, 400));
    await tester.pumpWidget(
      host(
        Center(
          child: SizedBox(key: const Key('p'), width: 288, child: _line(2)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final line = tester.getRect(find.byType(KChip).first);
    final last = tester.getRect(find.byType(KChip).last);
    final parent = tester.getRect(find.byKey(const Key('p')));
    expect((line.left + last.right) / 2, closeTo(parent.center.dx, 0.5));
  });

  testWidgets('overflow at 320 starts scrolled to the start, fade shown', (
    tester,
  ) async {
    useWindow(tester, const Size(320, 400));
    await tester.pumpWidget(
      host(Center(child: SizedBox(width: 288, child: _line(8)))),
    );
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('revealIndex scrolls an overflowing line to that chip', (
    tester,
  ) async {
    useWindow(tester, const Size(320, 400));
    Widget line(int? reveal) => host(
      Center(
        child: SizedBox(
          width: 288,
          child: KChipLine(
            revealIndex: reveal,
            children: [
              for (var i = 0; i < 8; i++)
                KChip(dense: true, label: Text('+${i + 1} ph'), onTap: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(line(7));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
  });
}
