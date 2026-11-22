import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  testWidgets('semanticLabel is the only spoken label; tooltip is visual', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Center(
          child: Tooltip(
            message: 'Thêm 10 phút',
            excludeFromSemantics: true,
            child: KChip(
              dense: true,
              semanticLabel: 'Thêm 10 phút',
              label: const Text('+10 ph'),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Thêm 10 phút'), findsOneWidget);
    expect(find.bySemanticsLabel('+10 ph'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Thêm 10 phút')),
      isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('without semanticLabel the visible label is spoken', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Center(
          child: KChip(label: const Text('15 ph'), onTap: () {}),
        ),
      ),
    );
    expect(find.bySemanticsLabel('15 ph'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('onRaised lifts only the unselected chip', (tester) async {
    Color fill(Finder chip) => tester
        .widget<Material>(
          find.descendant(of: chip, matching: find.byType(Material)).first,
        )
        .color!;
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            KChip(label: Text('a'), onRaised: true, dense: true),
            KChip(label: Text('b'), onRaised: true, selected: true),
            KChip(label: Text('c')),
          ],
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.text('a'))).colorScheme;
    expect(
      fill(find.widgetWithText(KChip, 'a')),
      scheme.surfaceContainerHighest,
    );
    expect(fill(find.widgetWithText(KChip, 'b')), scheme.secondaryContainer);
    expect(fill(find.widgetWithText(KChip, 'c')), scheme.surfaceContainerHigh);
  });
}
