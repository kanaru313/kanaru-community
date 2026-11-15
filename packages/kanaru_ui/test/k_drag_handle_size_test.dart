import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  Widget handle({double? dimension, double? iconSize}) => host(
    ReorderableListView(
      onReorderItem: (_, _) {},
      buildDefaultDragHandles: false,
      children: [
        SizedBox(
          key: const ValueKey(0),
          height: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: KDragHandle(
              index: 0,
              dimension: dimension,
              iconSize: iconSize,
              semanticLabel: 'Reorder',
            ),
          ),
        ),
      ],
    ),
  );

  // The handle's own box (the list gives its row the full width).
  Size box(WidgetTester tester) => tester.getSize(
    find
        .ancestor(
          of: find.byIcon(KIcons.dragHandle),
          matching: find.byType(SizedBox),
        )
        .first,
  );

  Icon glyph(WidgetTester tester) =>
      tester.widget<Icon>(find.byIcon(KIcons.dragHandle));

  testWidgets('dimension and iconSize set the box and the glyph', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 400));
    await tester.pumpWidget(
      handle(dimension: KIconSize.sm + 16, iconSize: KIconSize.sm),
    );
    expect(box(tester), const Size.square(KIconSize.sm + 16));
    expect(glyph(tester).size, KIconSize.sm);
  });

  testWidgets('without them the handle keeps the target size and icon', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 400));
    await tester.pumpWidget(handle());
    expect(box(tester), const Size.square(KLayout.minTarget));
    expect(glyph(tester).size, isNull);
  });
}
