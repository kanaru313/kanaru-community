import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/waveform_codec.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';

void main() {
  test('a ready waveform round trips', () {
    final levels = Uint8List.fromList(List.generate(1000, (i) => i % 256));
    final bytes = encodeWaveform(Ready(levels, 300000))!;
    expect(bytes.length, 11 + 1000);
    expect(bytes.sublist(0, 4), [0x4B, 0x57, 0x46, 0x31]);
    final back = decodeWaveform(bytes);
    expect(back, isA<Ready>());
    expect((back! as Ready).levels, levels);
    expect((back as Ready).durationMs, 300000);
  });

  test('a negative is 11 bytes and round trips', () {
    final bytes = encodeWaveform(const NoWaveform())!;
    expect(bytes.length, 11);
    expect(decodeWaveform(bytes), isA<NoWaveform>());
  });

  test('a retry is not stored', () {
    expect(encodeWaveform(const RetryLater()), isNull);
  });

  test('damaged files decode to null', () {
    final good = encodeWaveform(Ready(Uint8List.fromList([1, 2, 3]), 10))!;
    expect(decodeWaveform(Uint8List(0)), isNull);
    expect(decodeWaveform(good.sublist(0, 10)), isNull);
    expect(decodeWaveform(good.sublist(0, good.length - 1)), isNull);
    expect(decodeWaveform(Uint8List.fromList([...good, 9])), isNull);
    expect(decodeWaveform(Uint8List.fromList(good)..[0] = 0), isNull);
    expect(decodeWaveform(Uint8List.fromList(good)..[4] = 7), isNull);
  });

  test('a ready file without levels is damaged', () {
    final bytes = encodeWaveform(const NoWaveform())!..[4] = 0;
    expect(decodeWaveform(bytes), isNull);
  });
}
