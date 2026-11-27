import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/router/state/app_flush.dart';

void main() {
  test(
    'the flush starts at the earliest state before the app can be killed',
    () {
      expect(flushesOnLifecycle(AppLifecycleState.inactive), isTrue);
      expect(flushesOnLifecycle(AppLifecycleState.hidden), isTrue);
      expect(flushesOnLifecycle(AppLifecycleState.paused), isTrue);
    },
  );

  test('no flush when the app comes back or is running', () {
    expect(flushesOnLifecycle(AppLifecycleState.resumed), isFalse);
    expect(flushesOnLifecycle(AppLifecycleState.detached), isFalse);
  });
}
