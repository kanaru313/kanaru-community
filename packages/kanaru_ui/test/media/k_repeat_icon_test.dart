import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    KRepeatGlyph glyph, {
    int count = 0,
    bool menu = false,
  }) => tester.pumpWidget(
    host(KRepeatIcon(glyph: glyph, count: count, menu: menu, size: 24)),
  );

  testWidgets('one drawing per glyph', (tester) async {
    await pump(tester, KRepeatGlyph.one);
    expect(find.byIcon(KIcons.repeatOne), findsOneWidget);
    await pump(tester, KRepeatGlyph.all);
    expect(find.byIcon(KIcons.repeat), findsOneWidget);
    expect(find.byIcon(KIcons.shuffle), findsNothing);
  });

  testWidgets('off is the plain arrows on a button and a list in a menu', (
    tester,
  ) async {
    await pump(tester, KRepeatGlyph.off);
    expect(find.byIcon(KIcons.repeat), findsOneWidget);
    await pump(tester, KRepeatGlyph.off, menu: true);
    expect(find.byIcon(KIcons.flatList), findsOneWidget);
    expect(find.byIcon(KIcons.repeat), findsNothing);
  });

  testWidgets('reshuffled adds the shuffle badge to the arrows', (
    tester,
  ) async {
    await pump(tester, KRepeatGlyph.allShuffled);
    expect(find.byIcon(KIcons.repeat), findsOneWidget);
    expect(find.byIcon(KIcons.shuffle), findsOneWidget);
    expect(tester.getSize(find.byIcon(KIcons.shuffle)).width, 12);
  });

  testWidgets('counted shows the number in a circle, hidden from semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, KRepeatGlyph.counted, count: 42);
    expect(find.text('42'), findsOneWidget);
    expect(find.bySemanticsLabel('42'), findsNothing);
    final box = tester.getSize(find.byType(KRepeatIcon));
    expect(box, const Size(24, 24));
    handle.dispose();
  });

  testWidgets('takes the surrounding icon colour', (tester) async {
    await tester.pumpWidget(
      host(
        const IconTheme(
          data: IconThemeData(color: Color(0xFF123456), size: 20),
          child: KRepeatIcon(glyph: KRepeatGlyph.counted, count: 7),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('7')).style?.color,
        const Color(0xFF123456));
    expect(tester.getSize(find.byType(KRepeatIcon)), const Size(20, 20));
  });
}
