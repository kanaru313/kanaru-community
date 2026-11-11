import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Takes the app off the screen and lets the reload timers of the lists run
/// out (the longest wait is 5 s), so none is pending when the test ends.
///
/// Needed because `throttledQuery` (every list's id, count and row-revision
/// provider) starts a cooldown timer after each load, and the autoDispose
/// providers are released only after the tree is gone. Do not copy it to a
/// test of a page that reads no list.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}
