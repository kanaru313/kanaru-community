import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Thrown by [CappedOutput] when decoding produces more than its cap.
class OutputOverrun implements Exception {
  const OutputOverrun();

  @override
  String toString() => 'OutputOverrun';
}

/// In-memory output that refuses, before storing, any byte past [cap].
///
/// The buffer is allocated once at [cap] bytes and never grows, so a stream
/// that inflates far beyond what its zip header declared cannot use more
/// memory than the cap (plus the one decoder chunk in flight). [overran] is
/// set when it refused, whatever exception type the decoder turns it into.
class CappedOutput extends OutputMemoryStream {
  CappedOutput(this.cap) : super(size: max(1, cap));

  final int cap;

  /// True once a write past [cap] was refused.
  bool overran = false;

  /// The most bytes this output ever held; never above [cap].
  int get peakLength => length;

  /// Size of the underlying buffer; never above `max(1, cap)`.
  int get capacity => getBytes().buffer.lengthInBytes;

  void _room(int count) {
    if (length + count > cap) {
      overran = true;
      throw const OutputOverrun();
    }
  }

  @override
  void reserve(int total) {
    // The buffer already holds the cap; asking for more must not grow it.
    if (total <= cap) super.reserve(total);
  }

  @override
  void writeByte(int value) {
    _room(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _room(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _room(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _room(count);
    super.writeBackReference(distance, count);
  }
}

/// Inflates [rawDeflate] (a zip entry's data: raw deflate, no zlib header)
/// into [out]. Throws [OutputOverrun] as soon as the data passes [out]'s cap
/// and `FormatException` when the stream is damaged. Returns the bytes.
///
/// Never `Inflate(bytes)` without an `output:` here: it decodes eagerly into
/// a buffer that grows without a limit. This goes through `decodeStream`
/// into the capped output, so the decoder stops at the first block over.
Uint8List inflateRawCapped(Uint8List rawDeflate, CappedOutput out) {
  final bool finished;
  try {
    finished = ZLibDecoder().decodeStream(
      InputMemoryStream(rawDeflate),
      out,
      raw: true,
    );
  } on Object {
    // The decoder may wrap what the output threw; the flag is the truth.
    if (out.overran) throw const OutputOverrun();
    throw const FormatException('cannot inflate');
  }
  if (out.overran) throw const OutputOverrun();
  if (!finished) throw const FormatException('cannot inflate');
  return out.getBytes();
}
