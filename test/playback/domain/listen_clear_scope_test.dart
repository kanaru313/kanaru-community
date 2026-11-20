import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/listen_clear_scope.dart';

void main() {
  group('boundsCover', () {
    test('from is inclusive, to is exclusive', () {
      const b = (from: 10, to: 20);
      expect(boundsCover(b, 9), isFalse);
      expect(boundsCover(b, 10), isTrue);
      expect(boundsCover(b, 19), isTrue);
      expect(boundsCover(b, 20), isFalse);
    });

    test('an open side covers everything on that side', () {
      expect(boundsCover((from: null, to: 20), -5), isTrue);
      expect(boundsCover((from: null, to: 20), 20), isFalse);
      expect(boundsCover((from: 10, to: null), 1 << 40), isTrue);
      expect(boundsCover((from: 10, to: null), 9), isFalse);
      expect(boundsCover((from: null, to: null), 0), isTrue);
    });
  });

  group('clearTouches', () {
    test('a listen that never played is always touched', () {
      expect(clearTouches((from: 10, to: 20), null), isTrue);
      expect(clearTouches((from: null, to: null), null), isTrue);
    });

    test('otherwise it follows the range', () {
      expect(clearTouches((from: 10, to: 20), 15), isTrue);
      expect(clearTouches((from: 10, to: 20), 25), isFalse);
    });
  });
}
