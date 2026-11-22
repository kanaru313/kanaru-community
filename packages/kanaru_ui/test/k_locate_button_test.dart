import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(KLocateSide side, {bool reduce = false, VoidCallback? tap}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: Center(
            child: KLocateButton(
              side: side,
              tooltip: 'Go',
              onPressed: tap ?? () {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('none shows nothing', (tester) async {
    await tester.pumpWidget(_host(KLocateSide.none));
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('48 dp, labelled, taps, arrow follows the side', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(KLocateSide.below, tap: () => taps++));
    expect(tester.getSize(find.byType(IconButton)), const Size.square(48));
    expect(find.byTooltip('Go'), findsOneWidget);
    expect(find.byIcon(KIcons.arrowDown), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(taps, 1);
    await tester.pumpWidget(_host(KLocateSide.above));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(KIcons.arrowUp), findsOneWidget);
    expect(find.byIcon(KIcons.arrowDown), findsNothing);
  });

  testWidgets('animations off: the flip is instant', (tester) async {
    await tester.pumpWidget(_host(KLocateSide.below, reduce: true));
    await tester.pumpWidget(_host(KLocateSide.above, reduce: true));
    await tester.pump();
    expect(find.byIcon(KIcons.arrowDown), findsNothing);
    expect(find.byIcon(KIcons.arrowUp), findsOneWidget);
  });
}
