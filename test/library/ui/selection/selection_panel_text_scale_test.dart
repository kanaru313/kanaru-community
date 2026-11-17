import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/ui_harness.dart';
import 'selection_support.dart';

void main() {
  testWidgets('the open panel head fits at 200% text (count and duration)', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = await pumpSelection(tester);
    h.selection.addRange((await allIds(h)).take(2));
    h.selection.setExpanded(true);
    await pumpSummary(tester, h);
    expect(find.byType(KSelectionPanel), findsOneWidget);
    // Both lines are drawn, and neither overflows the head.
    expect(find.textContaining(' min'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });
}
