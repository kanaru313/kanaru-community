import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/media/seek_feedback.dart';

const _frame = 1 / 60;

/// Runs [springs] at 60 fps until they rest; returns the seconds it took, or
/// null when they did not settle within [limit] seconds.
double? _settleTime(
  JellySprings springs, {
  double limit = 3,
  double? Function()? press,
}) {
  var t = 0.0;
  while (t < limit) {
    springs.advance(_frame, pressIndex: press?.call());
    t += _frame;
    if (springs.atRest) return t;
  }
  return null;
}

void main() {
  group('JellySprings', () {
    test('start at rest with every factor 1', () {
      final s = JellySprings(8);
      expect(s.atRest, isTrue);
      for (var i = 0; i < 8; i++) {
        expect(s.factorAt(i), 1);
      }
    });

    test('a poke wobbles and settles in under 1.5 s', () {
      final s = JellySprings(40)..poke(20, 1);
      expect(s.atRest, isFalse);
      s.advance(_frame);
      expect(s.factorAt(20), isNot(1));
      final time = _settleTime(s);
      expect(time, isNotNull);
      expect(time!, lessThan(1.5));
      for (var i = 0; i < 40; i++) {
        expect(s.factorAt(i), 1);
      }
    });

    test('a key poke (half strength) also settles under 1.5 s', () {
      final s = JellySprings(40)..poke(3, 0.5);
      expect(_settleTime(s)!, lessThan(1.5));
    });

    test('a press dents the bars under the finger and never rests', () {
      final s = JellySprings(30);
      for (var i = 0; i < 120; i++) {
        s.advance(_frame, pressIndex: 15);
      }
      expect(s.atRest, isFalse);
      expect(s.factorAt(15), inExclusiveRange(0.35, 0.7));
      expect(s.factorAt(15), lessThan(s.factorAt(13)));
      expect(s.factorAt(0), closeTo(1, 0.01));
      // The finger goes up: the bars come back.
      expect(_settleTime(s)!, lessThan(1.5));
    });

    test('factors stay within 0.35..2.2 under any kick', () {
      final s = JellySprings(30);
      for (var k = 0; k < 20; k++) {
        s.poke(15, 5);
        s.advance(_frame, pressIndex: 14.5);
        for (var i = 0; i < 30; i++) {
          expect(s.factorAt(i), inInclusiveRange(0.35, 2.2));
        }
      }
    });

    test('a slow frame covers at most 0.05 s and does not snowball', () {
      final slow = JellySprings(20)..poke(10, 1);
      final capped = JellySprings(20)..poke(10, 1);
      slow.advance(5); // a five-second frame
      capped.advance(JellySprings.maxFrameTime);
      expect(JellySprings.maxSubsteps, 12);
      for (var i = 0; i < 20; i++) {
        expect(slow.factorAt(i), closeTo(capped.factorAt(i), 1e-9));
      }
    });

    test('zero bars: nothing to move, no NaN', () {
      final s = JellySprings(0)..poke(0, 1);
      s.advance(_frame, pressIndex: 0);
      expect(s.atRest, isTrue);
    });

    test('a non-finite index or step is ignored', () {
      final s = JellySprings(10)..poke(double.nan, 1);
      expect(s.atRest, isTrue);
      s.poke(5, 1);
      s.advance(double.nan);
      s.advance(_frame, pressIndex: double.infinity);
      for (var i = 0; i < 10; i++) {
        expect(s.factorAt(i).isFinite, isTrue);
      }
    });
  });

  group('LensEnvelope', () {
    test('eases in about 120 ms while down and out when up', () {
      final l = LensEnvelope();
      expect(l.atRest, isTrue);
      for (var i = 0; i < 15; i++) {
        l.advance(_frame, down: true);
      }
      expect(l.level, greaterThan(0.95));
      for (var i = 0; i < 60; i++) {
        l.advance(_frame, down: false);
      }
      expect(l.atRest, isTrue);
    });

    test('grows the bar under the finger by 70 % and fades with distance', () {
      final l = LensEnvelope();
      for (var i = 0; i < 60; i++) {
        l.advance(_frame, down: true);
      }
      expect(l.factorAt(0), closeTo(1.7, 1e-6));
      expect(l.factorAt(3.5), closeTo(1 + 0.7 * 0.3679, 1e-3));
      expect(l.factorAt(12), closeTo(1, 0.001));
      expect(l.factorAt(-3.5), l.factorAt(3.5));
    });
  });

  group('SeekFeedback', () {
    test('off: never active, no factors', () {
      final f = SeekFeedback()..configure(kind: KSeekFeedback.off, count: 10);
      f.press(3);
      f.poke(3, 1);
      expect(f.active, isFalse);
      expect(f.factors, isEmpty);
    });

    test('jelly: active while pressed and while it wobbles, then idle', () {
      final f = SeekFeedback()..configure(kind: KSeekFeedback.jelly, count: 20);
      expect(f.active, isFalse);
      f.press(10);
      expect(f.active, isTrue);
      f.advance(_frame);
      expect(f.revision, 1);
      f.press(null);
      expect(f.active, isTrue);
      for (var i = 0; i < 120 && f.active; i++) {
        f.advance(_frame);
      }
      expect(f.active, isFalse);
      expect(f.factors, everyElement(1));
    });

    test('jelly poke without a press starts a wobble', () {
      final f = SeekFeedback()..configure(kind: KSeekFeedback.jelly, count: 20);
      f.poke(5, 1);
      expect(f.active, isTrue);
    });

    test('lens: active while pressed, factors peak at the finger', () {
      final f = SeekFeedback()..configure(kind: KSeekFeedback.lens, count: 21);
      f.press(10);
      for (var i = 0; i < 30; i++) {
        f.advance(_frame);
      }
      expect(f.factors[10], closeTo(1.7, 0.01));
      expect(f.factors[0], closeTo(1, 0.01));
      f.press(null);
      for (var i = 0; i < 60 && f.active; i++) {
        f.advance(_frame);
      }
      expect(f.active, isFalse);
    });

    test('a finger resting on the same bar stops the frames once settled', () {
      for (final kind in [KSeekFeedback.jelly, KSeekFeedback.lens]) {
        final f = SeekFeedback()..configure(kind: kind, count: 20);
        f.press(10);
        for (var i = 0; i < 240; i++) {
          f.advance(_frame);
        }
        expect(f.active, isFalse, reason: kind.name);
        expect(f.showing, isTrue, reason: kind.name);
        final revision = f.revision;
        f.advance(_frame);
        expect(f.revision, revision, reason: kind.name);
        // The same index again changes nothing; a moved finger wakes it.
        f.press(10);
        expect(f.active, isFalse);
        f.press(11);
        expect(f.active, isTrue);
        // A seek poke wakes a jelly.
        f.press(11);
        for (var i = 0; i < 240; i++) {
          f.advance(_frame);
        }
        f.poke(5, 1);
        expect(f.active, kind == KSeekFeedback.jelly, reason: kind.name);
        // Finger up: the bars still settle back and then stop.
        f.press(null);
        for (var i = 0; i < 240 && f.showing; i++) {
          f.advance(_frame);
        }
        expect(f.showing, isFalse);
        expect(f.active, isFalse);
      }
    });

    test('a different kind or count starts from rest', () {
      final f = SeekFeedback()..configure(kind: KSeekFeedback.jelly, count: 20);
      f.poke(5, 1);
      f.configure(kind: KSeekFeedback.jelly, count: 21);
      expect(f.active, isFalse);
      expect(f.factors.length, 21);
    });
  });
}
