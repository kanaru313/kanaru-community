import 'package:flutter_test/flutter_test.dart';

/// Lets a menu finish loading (the database answers in real time) and its
/// route animate in. Call after the tap that opens it.
Future<void> pumpMenu(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
