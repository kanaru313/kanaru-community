import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

/// The selected row's tint inside a real picker: full width with square
/// corners in a mobile bottom sheet, rounded and inset in a desktop anchored
/// panel.
Future<String?> _noRemove() async => null;

void main() {
  final anchor = GlobalKey();

  Widget opener(SelectionPickerPresentation presentation) => Align(
    alignment: Alignment.topLeft,
    child: Builder(
      builder: (context) => TextButton(
        key: anchor,
        onPressed: () => showSelectionPicker<int>(
          context,
          options: const [
            SelectionOption<int>(
              value: 1,
              title: Text('One'),
              removeTooltip: 'Remove one',
              onRemove: _noRemove,
            ),
            SelectionOption<int>(value: 2, title: Text('Two')),
          ],
          selected: 1,
          title: const Text('Pick'),
          anchor: anchor,
          presentation: presentation,
        ),
        child: const Text('open'),
      ),
    ),
  );

  ({Rect row, Rect tint, BorderRadius radius}) measure(WidgetTester tester) {
    final row = find.widgetWithText(SelectionRow, 'One');
    final tint = find.descendant(
      of: row,
      matching: find.byType(AnimatedContainer),
    );
    final shape =
        (tester.widget<AnimatedContainer>(tint).decoration! as ShapeDecoration)
                .shape
            as RoundedRectangleBorder;
    return (
      row: tester.getRect(row),
      tint: tester.getRect(tint),
      radius: shape.borderRadius as BorderRadius,
    );
  }

  testWidgets('mobile sheet: tint touches both edges, square corners', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(opener(SelectionPickerPresentation.auto)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final m = measure(tester);
    expect(m.tint.left, 0);
    expect(m.tint.right, 400);
    expect(m.radius, BorderRadius.zero);
  });

  testWidgets('desktop panel: tint rounded with at least 8 dp to both edges', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(opener(SelectionPickerPresentation.anchored)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final m = measure(tester);
    expect(m.tint.left - m.row.left, greaterThanOrEqualTo(KSpace.x2));
    expect(m.row.right - m.tint.right, greaterThanOrEqualTo(KSpace.x2));
    expect(m.radius.topLeft.x, greaterThan(0));
  });

  for (final (name, size, presentation) in [
    ('mobile', const Size(400, 800), SelectionPickerPresentation.auto),
    ('desktop', const Size(1400, 900), SelectionPickerPresentation.anchored),
  ]) {
    testWidgets('$name: the tint of a removable row covers its ✕', (
      tester,
    ) async {
      useWindow(tester, size);
      await tester.pumpWidget(host(opener(presentation)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final m = measure(tester);
      final x = tester.getRect(byIconButton('Remove one'));
      expect(m.tint.right, greaterThanOrEqualTo(x.right));
      expect(m.tint.left, lessThanOrEqualTo(x.left));
    });
  }
}
