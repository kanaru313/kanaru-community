import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fit.dart';

Widget _box(double height) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      key: const Key('box'),
      width: 200,
      height: height,
      child: const Text(
        'A\nB',
        style: TextStyle(fontSize: 20, fontFamily: 'Ahem'),
      ),
    ),
  ),
);

void main() {
  testWidgets('passes when the text fits its box', (tester) async {
    await tester.pumpWidget(_box(100));
    expectTextsFit(tester, find.byKey(const Key('box')));
  });

  testWidgets('fails when the box is shorter than the text', (tester) async {
    // 2 lines of 20 dp = 40 dp of text in a 20 dp box.
    await tester.pumpWidget(_box(20));
    expect(
      () => expectTextsFit(tester, find.byKey(const Key('box'))),
      throwsA(isA<TestFailure>()),
    );
  });
}
