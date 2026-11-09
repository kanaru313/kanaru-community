import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

void main() {
  test('width threshold is the desktop breakpoint', () {
    expect(FormFactor.fromWidth(1199), FormFactor.mobile);
    expect(FormFactor.fromWidth(1200), FormFactor.desktop);
  });

  testWidgets('of() reads the window width', (tester) async {
    FormFactor? seen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (width, expected) in [(1199.0, FormFactor.mobile), (1200.0, FormFactor.desktop)]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(Builder(builder: (context) {
        seen = FormFactor.of(context);
        return const SizedBox();
      }));
      expect(seen, expected);
    }
  });
}
