import 'dart:typed_data';

import '../domain/waveform.dart';

/// Cache file layout (little endian), 11 bytes plus the levels:
/// `KWF1` | kind u8 (0 ready, 1 negative, 2 negative from timeouts) | duration ms u32 | count u16 | levels.
const _magic = [0x4B, 0x57, 0x46, 0x31];
const _headerBytes = 11;
const _kindReady = 0;
const _kindNegative = 1;

/// A negative from timeouts; its duration field holds the write time in
/// seconds since the epoch.
const _kindTimedOut = 2;

/// The cache file bytes of [result]; null for a result that is not cached.
Uint8List? encodeWaveform(WaveformResult result) {
  switch (result) {
    case Ready(:final levels, :final durationMs):
      final out = Uint8List(_headerBytes + levels.length);
      _writeHeader(out, _kindReady, durationMs, levels.length);
      out.setRange(_headerBytes, out.length, levels);
      return out;
    case NoWaveform(:final timedOutAt):
      final out = Uint8List(_headerBytes);
      _writeHeader(
        out,
        timedOutAt == null ? _kindNegative : _kindTimedOut,
        timedOutAt == null ? 0 : timedOutAt.millisecondsSinceEpoch ~/ 1000,
        0,
      );
      return out;
    case RetryLater():
      return null;
  }
}

void _writeHeader(Uint8List out, int kind, int durationMs, int count) {
  out.setRange(0, 4, _magic);
  out[4] = kind;
  final data = ByteData.sublistView(out);
  data.setUint32(5, durationMs, Endian.little);
  data.setUint16(9, count, Endian.little);
}

/// The result stored in [bytes], or null when they are not a valid cache file
/// (wrong magic, unknown kind, a count that does not match the length).
WaveformResult? decodeWaveform(Uint8List bytes) {
  if (bytes.length < _headerBytes) return null;
  for (var i = 0; i < 4; i++) {
    if (bytes[i] != _magic[i]) return null;
  }
  final data = ByteData.sublistView(bytes);
  final durationMs = data.getUint32(5, Endian.little);
  final count = data.getUint16(9, Endian.little);
  if (bytes.length != _headerBytes + count) return null;
  switch (bytes[4]) {
    case _kindNegative:
      return count == 0 ? const NoWaveform() : null;
    case _kindTimedOut:
      return count == 0
          ? NoWaveform(
              timedOutAt: DateTime.fromMillisecondsSinceEpoch(
                durationMs * 1000,
              ),
            )
          : null;
    case _kindReady:
      return count == 0
          ? null
          : Ready(Uint8List.fromList(bytes.sublist(_headerBytes)), durationMs);
  }
  return null;
}
