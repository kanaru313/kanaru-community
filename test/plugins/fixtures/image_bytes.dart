import 'dart:convert';
import 'dart:typed_data';

/// Bytes shaped like the start of a PNG: signature, IHDR, an optional `acTL`
/// chunk (animated), then an empty IDAT. Never decodable, only parseable.
Uint8List pngBytes(int width, int height, {bool animated = false}) {
  final out = BytesBuilder();
  out.add([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  void chunk(String type, List<int> data) {
    out.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
    out.add(ascii.encode(type));
    out.add(data);
    out.add(const [0, 0, 0, 0]);
  }

  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  chunk('IHDR', ihdr.buffer.asUint8List());
  if (animated) chunk('acTL', List.filled(8, 0));
  chunk('IDAT', const []);
  return out.toBytes();
}

Uint8List _riff(String fourcc, List<int> payload) {
  final body = BytesBuilder()
    ..add(ascii.encode('WEBP'))
    ..add(ascii.encode(fourcc))
    ..add(
      (ByteData(
        4,
      )..setUint32(0, payload.length, Endian.little)).buffer.asUint8List(),
    )
    ..add(payload);
  final data = body.toBytes();
  return Uint8List.fromList([
    ...ascii.encode('RIFF'),
    ...(ByteData(
      4,
    )..setUint32(0, data.length, Endian.little)).buffer.asUint8List(),
    ...data,
  ]);
}

/// Lossy WebP header (`VP8 `) with a [width] x [height] frame.
Uint8List webpLossy(int width, int height) {
  final p = ByteData(10)
    ..setUint16(6, width, Endian.little)
    ..setUint16(8, height, Endian.little);
  final bytes = p.buffer.asUint8List();
  bytes.setAll(3, const [0x9d, 0x01, 0x2a]);
  return _riff('VP8 ', bytes);
}

/// Lossless WebP header (`VP8L`).
Uint8List webpLossless(int width, int height) {
  final p = ByteData(5)
    ..setUint8(0, 0x2f)
    ..setUint32(1, (width - 1) | ((height - 1) << 14), Endian.little);
  return _riff('VP8L', p.buffer.asUint8List());
}

/// Extended WebP header (`VP8X`); [animated] sets the animation flag.
Uint8List webpExtended(int width, int height, {bool animated = false}) {
  final p = Uint8List(10);
  p[0] = animated ? 0x02 : 0;
  for (var i = 0; i < 3; i++) {
    p[4 + i] = ((width - 1) >> (8 * i)) & 0xff;
    p[7 + i] = ((height - 1) >> (8 * i)) & 0xff;
  }
  return _riff('VP8X', p);
}

/// A RIFF/WEBP container whose first chunk is [fourcc] (unknown to the reader).
Uint8List webpChunk(String fourcc) => _riff(fourcc, Uint8List(12));
