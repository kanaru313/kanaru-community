import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

Future<void> _pump(WidgetTester tester, double width, String text) =>
    tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: width,
            child: KOverflowTooltip(
              text: text,
              message: 'at 3',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
    );

String? _message(WidgetTester tester) =>
    tester.widget<Tooltip>(find.byType(Tooltip)).message;

void main() {
  testWidgets('a line that fits shows only the message', (tester) async {
    await _pump(tester, 300, '12 tracks');
    expect(_message(tester), 'at 3');
  });

  testWidgets('a cut line puts the full text before the message', (
    tester,
  ) async {
    await _pump(tester, 40, '20000 tracks · 1388 h 53 min left');
    expect(_message(tester), '20000 tracks · 1388 h 53 min left\nat 3');
  });
}
