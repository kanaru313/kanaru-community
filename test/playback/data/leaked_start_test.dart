import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/leaked_start.dart';

void main() {
  const offset = Duration(milliseconds: 2400);

  test('a position near the resume offset is a leak: seek back', () {
    for (final at in [2.4, 2.1, 3.1]) {
      expect(
        isLeakedStart(
          resumeStart: offset,
          positionSeconds: at,
          seekedSinceAdvance: false,
        ),
        isTrue,
        reason: '$at',
      );
    }
  });

  test('a legitimate position far from the offset is left alone', () {
    for (final at in [0.0, 0.3, 1.0, 5.0]) {
      expect(
        isLeakedStart(
          resumeStart: offset,
          positionSeconds: at,
          seekedSinceAdvance: false,
        ),
        isFalse,
        reason: '$at',
      );
    }
  });

  test('a user seek since the advance is never undone', () {
    expect(
      isLeakedStart(
        resumeStart: offset,
        positionSeconds: 2.4,
        seekedSinceAdvance: true,
      ),
      isFalse,
    );
  });

  test('no resume offset, nothing to undo', () {
    expect(
      isLeakedStart(
        resumeStart: Duration.zero,
        positionSeconds: 0.2,
        seekedSinceAdvance: false,
      ),
      isFalse,
    );
  });
}
