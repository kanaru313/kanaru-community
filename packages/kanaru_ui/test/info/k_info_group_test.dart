import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _group(KOverlayKind? kind, {int rows = 3}) {
  final group = KInfoGroup(
    title: 'Tags',
    icon: KIcons.edit,
    children: [
      for (var i = 0; i < rows; i++) KInfoRow(label: 'L$i', value: 'V$i'),
    ],
  );
  return SingleChildScrollView(
    child: kind == null ? group : KOverlayPageScope(kind: kind, child: group),
  );
}

Color? _card(WidgetTester tester) => tester
    .widget<Material>(
      find.descendant(
        of: find.byType(KInfoGroup),
        matching: find.byType(Material),
      ),
    )
    .color;

void main() {
  testWidgets('the title is a semantics header', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_group(null)));
    expect(
      tester.getSemantics(find.text('Tags')),
      isSemantics(label: 'Tags', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('a hairline sits between rows, none above or below', (
    tester,
  ) async {
    await tester.pumpWidget(host(_group(null)));
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('card is surfaceContainerLow on a page, surface in a box', (
    tester,
  ) async {
    await tester.pumpWidget(host(_group(KOverlayKind.page)));
    final scheme = Theme.of(tester.element(find.text('Tags'))).colorScheme;
    expect(_card(tester), scheme.surfaceContainerLow);
    await tester.pumpWidget(host(_group(KOverlayKind.box)));
    expect(_card(tester), scheme.surface);
  });

  testWidgets('no rows draws nothing', (tester) async {
    await tester.pumpWidget(host(_group(null, rows: 0)));
    expect(find.text('Tags'), findsNothing);
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders in $name', (tester) async {
      await tester.pumpWidget(
        host(
          _group(KOverlayKind.box),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('V2'), findsOneWidget);
    });
  }
}
