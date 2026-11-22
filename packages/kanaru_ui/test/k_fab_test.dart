import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  testWidgets('is a 56 dp button named by its tooltip that fires once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        Center(
          child: KFab(
            icon: KIcons.add,
            tooltip: 'Add',
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(KFab)), const Size(56, 56));
    expect(find.bySemanticsLabel('Add'), findsOneWidget);
    await tester.tap(find.byType(KFab));
    expect(taps, 1);
    handle.dispose();
  });
}
