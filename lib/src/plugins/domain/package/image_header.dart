import 'dart:typed_data';

import 'package_limits.dart';

/// Why an asset image is refused (`InvalidAsset.reason`).
abstract final class ImageProblem {
  /// Not a PNG or WebP, truncated, or a chunk the reader does not know.
  static const format = 'format';

  /// An animated PNG or WebP.
  static const animated = 'animated';

  /// The file extension does not match the data.
  static const extension = 'extension';

  /// A side is 0 or over [maxSeekbarImageSide].
  static const size = 'size';
}

/// What the header of an image says. [problem] is null when it is usable.
class ImageHeader {
  const ImageHeader.ok(this.width, this.height) : problem = null;
  const ImageHeader.refused(this.problem) : width = 0, height = 0;

  final int width;
  final int height;

  /// One of the [ImageProblem] values, or null.
  final String? problem;
}

const _pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

/// Reads the dimensions of the PNG or WebP [bytes] from its header only; the
/// image is never decoded. [fileName] (`t.png`) must end in the extension
/// that matches the data. Anything unknown is refused (fail closed).
ImageHeader readImageHeader(String fileName, Uint8List bytes) {
  final String type;
  final int width;
  final int height;
  if (_isPng(bytes)) {
    type = 'png';
    final dims = _pngDimensions(bytes);
    if (dims == null) return const ImageHeader.refused(ImageProblem.format);
    if (_pngIsAnimated(bytes)) {
      return const ImageHeader.refused(ImageProblem.animated);
    }
    (width, height) = dims;
  } else if (_isWebp(bytes)) {
    type = 'webp';
    final parsed = _webp(bytes);
    if (parsed is String) return ImageHeader.refused(parsed);
    (width, height) = parsed as (int, int);
  } else {
    return const ImageHeader.refused(ImageProblem.format);
  }
  if (!fileName.endsWith('.$type')) {
    return const ImageHeader.refused(ImageProblem.extension);
  }
  if (width < 1 ||
      height < 1 ||
      width > maxSeekbarImageSide ||
      height > maxSeekbarImageSide) {
    return const ImageHeader.refused(ImageProblem.size);
  }
  return ImageHeader.ok(width, height);
}

/// Why [bytes] is not an acceptable seekbar image, or null when it is.
String? imageHeaderProblem(String fileName, Uint8List bytes) =>
    readImageHeader(fileName, bytes).problem;

bool _isPng(Uint8List b) {
  if (b.length < 8) return false;
  for (var i = 0; i < 8; i++) {
    if (b[i] != _pngSignature[i]) return false;
  }
  return true;
}

bool _isWebp(Uint8List b) =>
    b.length >= 12 && _tag(b, 0) == 'RIFF' && _tag(b, 8) == 'WEBP';

String _tag(Uint8List b, int at) => String.fromCharCodes(b, at, at + 4);

/// IHDR must be the first chunk; null when it is not or the file is short.
(int, int)? _pngDimensions(Uint8List b) {
  if (b.length < 24 || _tag(b, 12) != 'IHDR') return null;
  final data = ByteData.sublistView(b);
  return (data.getUint32(16), data.getUint32(20));
}

/// An `acTL` chunk before the first `IDAT` marks an animated PNG.
bool _pngIsAnimated(Uint8List b) {
  final data = ByteData.sublistView(b);
  var pos = 8;
  while (pos + 8 <= b.length) {
    final length = data.getUint32(pos);
    final type = _tag(b, pos + 4);
    if (type == 'acTL') return true;
    if (type == 'IDAT') return false;
    pos += 12 + length;
  }
  return false;
}

/// `(width, height)` of a WebP, or an [ImageProblem] string.
Object _webp(Uint8List b) {
  const bad = ImageProblem.format;
  if (b.length < 20) return bad;
  final data = ByteData.sublistView(b);
  switch (_tag(b, 12)) {
    case 'VP8 ':
      if (b.length < 30) return bad;
      if (b[23] != 0x9d || b[24] != 0x01 || b[25] != 0x2a) return bad;
      return (
        data.getUint16(26, Endian.little) & 0x3fff,
        data.getUint16(28, Endian.little) & 0x3fff,
      );
    case 'VP8L':
      if (b.length < 25 || b[20] != 0x2f) return bad;
      final bits = data.getUint32(21, Endian.little);
      return ((bits & 0x3fff) + 1, ((bits >> 14) & 0x3fff) + 1);
    case 'VP8X':
      if (b.length < 30) return bad;
      if (b[20] & 0x02 != 0) return ImageProblem.animated;
      return (
        (b[24] | b[25] << 8 | b[26] << 16) + 1,
        (b[27] | b[28] << 8 | b[29] << 16) + 1,
      );
    default:
      return bad;
  }
}
