import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/capped_output.dart';

import '../fixtures/zip_builders.dart';

void main() {
  test(
    '64 MiB behind a 1 KiB cap stops with the buffer never above the cap',
    () {
      final bomb = rawDeflate(Uint8List(64 * 1024 * 1024));
      final out = CappedOutput(1024);
      expect(() => inflateRawCapped(bomb, out), throwsA(isA<OutputOverrun>()));
      expect(out.overran, isTrue);
      expect(out.peakLength, lessThanOrEqualTo(1024));
      expect(out.capacity, lessThanOrEqualTo(1024));
    },
  );

  test('data that fits is returned in full', () {
    final text = Uint8List.fromList(List.generate(5000, (i) => i % 251));
    final out = CappedOutput(5000);
    expect(inflateRawCapped(rawDeflate(text), out), text);
    expect(out.overran, isFalse);
    expect(out.peakLength, 5000);
  });

  test('one byte over the cap is refused, exactly the cap is not', () {
    final text = Uint8List(2048);
    expect(
      () => inflateRawCapped(rawDeflate(text), CappedOutput(2047)),
      throwsA(isA<OutputOverrun>()),
    );
    expect(inflateRawCapped(rawDeflate(text), CappedOutput(2048)), text);
  });

  test('a damaged stream is a format error, not an overrun', () {
    final bad = Uint8List.fromList(List.filled(64, 0xff));
    expect(
      () => inflateRawCapped(bad, CappedOutput(1024)),
      throwsA(isA<FormatException>()),
    );
  });

  test('reserving more than the cap does not grow the buffer', () {
    final out = CappedOutput(100)..reserve(10 * 1024 * 1024);
    expect(out.capacity, lessThanOrEqualTo(100));
  });
}
