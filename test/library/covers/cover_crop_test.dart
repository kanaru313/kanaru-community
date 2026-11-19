import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/domain/covers/cover_crop.dart';

void main() {
  test('a square image has no crop', () {
    expect(cropFor(0.5, 800, 800), isNull);
  });

  test('landscape moves along x, centred by default', () {
    expect(
      cropFor(0.5, 4000, 3000),
      const CoverCrop(left: 500, top: 0, side: 3000),
    );
    expect(
      cropFor(0, 4000, 3000),
      const CoverCrop(left: 0, top: 0, side: 3000),
    );
    expect(
      cropFor(1, 4000, 3000),
      const CoverCrop(left: 1000, top: 0, side: 3000),
    );
  });

  test('portrait moves along y', () {
    expect(
      cropFor(0.5, 3024, 4032),
      const CoverCrop(left: 0, top: 504, side: 3024),
    );
    expect(
      cropFor(1, 3024, 4032),
      const CoverCrop(left: 0, top: 1008, side: 3024),
    );
  });

  test('out of range offsets clamp, NaN means centre', () {
    expect(cropFor(-3, 4000, 3000)!.left, 0);
    expect(cropFor(7, 4000, 3000)!.left, 1000);
    expect(cropFor(double.nan, 4000, 3000)!.left, 500);
  });

  test('an unusable size has no crop', () {
    expect(cropFor(0.5, 0, 100), isNull);
    expect(cropFor(0.5, 100, -1), isNull);
  });
}
