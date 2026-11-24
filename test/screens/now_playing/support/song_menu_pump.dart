import 'package:flutter_test/flutter_test.dart';

/// Lets the Now Playing song menu load its data (database reads run in real
/// time) and finish opening: pumps, giving real time between pumps, until
/// [until] (default: the "Sleep timer" row) is on screen, at most about two
/// seconds, then lets the open animation end. A menu that never shows is left
/// for the test's own expectations to report.
Future<void> menuLoads(WidgetTester tester, {Finder? until}) async {
  final target = until ?? find.text('Sleep timer');
  await tester.pump();
  for (var i = 0; i < 100 && target.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pump(const Duration(milliseconds: 400));
}
