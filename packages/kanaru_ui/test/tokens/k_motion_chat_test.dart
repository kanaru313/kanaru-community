import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

void main() {
  test('chat motion tokens', () {
    expect(KMotion.chatPageSlide, const Duration(milliseconds: 420));
    expect(KMotion.streamingDots, const Duration(milliseconds: 1200));
    expect(KMotion.countdownTick, const Duration(seconds: 1));
  });
}
