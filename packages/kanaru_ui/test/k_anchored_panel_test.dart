import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final key = GlobalKey();

  Widget app({KAnchorAlign align = KAnchorAlign.start}) => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: TextButton(
            key: key,
            onPressed: () => showKAnchoredPanel<void>(
              context,
              anchor: kAnchorRectOf(key)!,
              align: align,
              builder: (_) => const SizedBox(
                key: ValueKey('panel'),
                width: 200,
                height: 100,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('opens under the anchor, right edges aligned for end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(align: KAnchorAlign.end));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    final anchor = tester.getRect(find.byKey(key));
    final panel = tester.getRect(find.byKey(const ValueKey('panel')));
    expect(panel.right, closeTo(anchor.right, 0.5));
    expect(panel.top, greaterThan(anchor.bottom));
  });

  testWidgets('Esc closes it', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('panel')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('panel')), findsNothing);
  });

  testWidgets('kAnchorRectOf is null for a key that is not on screen', (
    tester,
  ) async {
    expect(kAnchorRectOf(GlobalKey()), isNull);
    expect(kAnchorRectOf(null), isNull);
  });
}
