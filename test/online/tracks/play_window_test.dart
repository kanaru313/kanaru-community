import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/domain/tracks/play_window.dart';

void main() {
  List<int> list(int n) => List.generate(n, (i) => i);

  test('a short list is returned whole', () {
    final w = playWindow(list(50), 7);
    expect(w.items, list(50));
    expect(w.index, 7);
  });

  test('the tap at the start, middle and end of 500', () {
    final first = playWindow(list(500), 0);
    expect(first.items, list(200));
    expect(first.index, 0);

    final middle = playWindow(list(500), 250);
    expect(middle.items, hasLength(200));
    expect(middle.items.first, 150);
    expect(middle.index, 100);
    expect(middle.items[middle.index], 250);

    final last = playWindow(list(500), 499);
    expect(last.items.first, 300);
    expect(last.items.last, 499);
    expect(last.items[last.index], 499);
  });

  test('the tapped item is always inside and max is respected', () {
    for (final tap in [0, 1, 99, 100, 101, 399, 400, 499]) {
      final w = playWindow(list(500), tap, max: 40);
      expect(w.items, hasLength(40));
      expect(w.items[w.index], tap);
    }
  });

  test('a bad index throws', () {
    expect(() => playWindow(list(3), -1), throwsRangeError);
    expect(() => playWindow(list(3), 3), throwsRangeError);
    expect(() => playWindow(<int>[], 0), throwsRangeError);
  });
}
