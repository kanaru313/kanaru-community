import 'dart:typed_data';

import 'package_limits.dart';

const _signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

/// Why [bytes] is not an acceptable `icon.png`, or null when it is. Reads
/// only the signature and the IHDR chunk; the image is never decoded here.
/// The reason is for logs; a bad icon is dropped and the install goes on.
String? iconProblem(Uint8List bytes) {
  if (bytes.length > maxIconBytes) return 'over $maxIconBytes B';
  // Signature (8) + chunk length (4) + type (4) + width (4) + height (4).
  if (bytes.length < 24) return 'truncated';
  for (var i = 0; i < _signature.length; i++) {
    if (bytes[i] != _signature[i]) return 'not a PNG';
  }
  final header = ByteData.sublistView(bytes);
  final isIhdr =
      header.getUint32(8) == 13 && header.getUint32(12) == 0x49484452;
  if (!isIhdr) return 'IHDR chunk missing';
  final width = header.getUint32(16);
  final height = header.getUint32(20);
  if (width < 1 || height < 1) return 'empty image';
  if (width > maxIconSide || height > maxIconSide) {
    return 'over ${maxIconSide}x$maxIconSide';
  }
  return null;
}
