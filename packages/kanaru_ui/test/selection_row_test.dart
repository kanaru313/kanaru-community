import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('selected row shows check and tint ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(
        const Column(children: [
          SelectionRow(title: Text('A'), selected: true),
          SelectionRow(title: Text('A much longer title that wraps'), subtitle: Text('sub'), selected: false),
        ]),
        brightness: brightness,
        textScale: scale,
      ));
      expect(tester.takeException(), isNull);
      final checks = tester.widgetList<Icon>(find.byIcon(KIcons.check)).toList();
      final scheme = Theme.of(tester.element(find.text('A'))).colorScheme;
      expect(checks[0].color, scheme.primary);
      // Unselected keeps the slot (same size) but is invisible.
      expect(checks[1].size, checks[0].size);
      expect(checks[1].color!.a, 0);
    });
  }

  testWidgets('titles line up and rows meet touch height', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(const Column(children: [
      SelectionRow(title: Text('One'), selected: true),
      SelectionRow(title: Text('Two'), selected: false),
    ])));
    expect(tester.getTopLeft(find.text('One')).dx, tester.getTopLeft(find.text('Two')).dx);
    expect(tester.getSize(find.byType(SelectionRow).first).height, greaterThanOrEqualTo(56));
  });

  testWidgets('disabled row ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(SelectionRow(
      title: const Text('X'),
      selected: false,
      enabled: false,
      onTap: () => taps++,
    )));
    await tester.tap(find.text('X'));
    expect(taps, 0);
  });
}
