import 'dart:typed_data';

import 'font_label.dart';

/// What the header of a TrueType / OpenType file says.
class FontHeader {
  const FontHeader({required this.family, required this.isCff});

  /// Sanitised family name; null when the file has no readable one.
  final String? family;

  /// OpenType with CFF outlines (`.otf`), else TrueType (`.ttf`).
  final bool isCff;
}

/// Reads the header of [bytes] and checks it is a font Flutter can load:
/// magic `0x00010000`, `OTTO` or `true` (`ttcf` collections are refused), a
/// table directory inside the file, the `name`, `cmap` tables and outlines
/// (`glyf` + `loca`, or `CFF ` / `CFF2`), every one of them inside the file.
/// Returns null for anything else, including truncated files. Never throws.
FontHeader? parseFontHeader(Uint8List bytes) {
  try {
    return _parse(bytes);
  } on RangeError {
    return null;
  }
}

FontHeader? _parse(Uint8List bytes) {
  if (bytes.length < 12) return null;
  final data = ByteData.sublistView(bytes);
  final magic = data.getUint32(0);
  final cff = magic == 0x4F54544F; // OTTO
  if (magic != 0x00010000 && !cff && magic != 0x74727565 /* true */ ) {
    return null;
  }
  final numTables = data.getUint16(4);
  if (numTables == 0 || 12 + numTables * 16 > bytes.length) return null;
  final tables = <String, ({int offset, int length})>{};
  for (var i = 0; i < numTables; i++) {
    final entry = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(entry, entry + 4));
    final offset = data.getUint32(entry + 8);
    final length = data.getUint32(entry + 12);
    if (offset + length > bytes.length) return null;
    tables.putIfAbsent(tag, () => (offset: offset, length: length));
  }
  final hasOutlines =
      (tables.containsKey('glyf') && tables.containsKey('loca')) ||
      tables.containsKey('CFF ') ||
      tables.containsKey('CFF2');
  final name = tables['name'];
  if (name == null || !tables.containsKey('cmap') || !hasOutlines) return null;
  return FontHeader(
    family: _familyName(bytes, data, name.offset, name.length),
    isCff: cff || tables.containsKey('CFF ') || tables.containsKey('CFF2'),
  );
}

/// Name ID 16 (typographic family) first, then ID 1; platform 3 (Windows),
/// 0 (Unicode), then 1 (Macintosh), so a lossy MacRoman entry never hides a
/// complete UTF-16 one.
String? _familyName(Uint8List bytes, ByteData data, int start, int length) {
  if (length < 6) return null;
  final count = data.getUint16(start + 2);
  final storage = start + data.getUint16(start + 4);
  final end = start + length;
  for (final id in const [16, 1]) {
    for (final platform in const [3, 0, 1]) {
      for (var i = 0; i < count; i++) {
        final record = start + 6 + i * 12;
        if (record + 12 > end) break;
        if (data.getUint16(record + 6) != id) continue;
        if (data.getUint16(record) != platform) continue;
        final len = data.getUint16(record + 8);
        final from = storage + data.getUint16(record + 10);
        if (from + len > bytes.length) continue;
        final label = sanitizeFontLabel(
          _decode(platform, bytes.sublist(from, from + len)),
        );
        if (label.isNotEmpty) return label;
      }
    }
  }
  return null;
}

String _decode(int platform, Uint8List raw) {
  if (platform == 1) return String.fromCharCodes(raw); // Latin-1 range
  return String.fromCharCodes([
    for (var i = 0; i + 1 < raw.length; i += 2) (raw[i] << 8) | raw[i + 1],
  ]);
}
