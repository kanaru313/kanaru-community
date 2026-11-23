import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_controller.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_format.dart';

import 'picker_harness.dart';

void main() {
  group('formatTrackLength', () {
    test('minutes and padded seconds', () {
      expect(
        formatTrackLength(const Duration(minutes: 4, seconds: 12)),
        '4:12',
      );
      expect(formatTrackLength(const Duration(seconds: 5)), '0:05');
      expect(formatTrackLength(const Duration(minutes: 75)), '75:00');
    });
  });

  group('resultDelta', () {
    const song = Duration(minutes: 4, seconds: 12);
    ResultDelta? delta(int seconds) =>
        resultDelta(Duration(seconds: 252 + seconds), song);

    test('within 3 s either way is a match', () {
      for (final d in [0, 1, 3, -3]) {
        expect(
          delta(d),
          const ResultDelta(ResultDeltaKind.match, 0),
          reason: '$d',
        );
      }
    });

    test('beyond 3 s it is signed seconds', () {
      expect(delta(4), const ResultDelta(ResultDeltaKind.longer, 4));
      expect(delta(-5), const ResultDelta(ResultDeltaKind.shorter, 5));
      expect(delta(-4), const ResultDelta(ResultDeltaKind.shorter, 4));
    });

    test('a gap just over 3 s rounds up, never to a "+3 s"', () {
      expect(
        resultDelta(const Duration(milliseconds: 255400), song),
        const ResultDelta(ResultDeltaKind.longer, 4),
      );
    });

    test('unknown on either side: no difference', () {
      expect(resultDelta(null, song), isNull);
      expect(resultDelta(song, null), isNull);
    });
  });

  group('defaultQueryText', () {
    test('title and artist', () {
      expect(defaultQueryText(songFacts()), 'Song Singer');
    });

    test('nothing known', () {
      expect(defaultQueryText(null), '');
    });
  });
}
