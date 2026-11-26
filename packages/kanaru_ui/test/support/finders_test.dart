import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';
import 'finders.dart';

void main() {
  testWidgets('bySemanticsSelected finds a selected icon row', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Column(
          children: [
            Semantics(
              container: true,
              selected: true,
              label: 'Chosen',
              child: const Row(children: [Icon(KIcons.folders), Text('Chosen')]),
            ),
            Semantics(
              container: true,
              selected: false,
              label: 'Other',
              child: const Text('Other'),
            ),
          ],
        ),
      ),
    );
    expect(bySemanticsSelected('Chosen'), findsOneWidget);
    expect(bySemanticsSelected('Other'), findsNothing);
    handle.dispose();
  });

  testWidgets('byToggledState finds a switch row by state', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Column(
          children: [
            KSwitchRow(
              title: const Text('A'),
              value: true,
              switchLabel: 'Turn on A',
              onChanged: (_) {},
            ),
            KSwitchRow(
              title: const Text('B'),
              value: false,
              switchLabel: 'Turn on B',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(byToggledState('Turn on A'), findsOneWidget);
    expect(byToggledState('Turn on A', on: false), findsNothing);
    expect(byToggledState('Turn on B', on: false), findsOneWidget);
    handle.dispose();
  });
}
