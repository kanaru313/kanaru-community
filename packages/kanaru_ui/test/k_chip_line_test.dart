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
}
