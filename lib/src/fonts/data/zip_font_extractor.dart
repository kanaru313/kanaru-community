import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// The zip cannot be used: unsafe path, duplicate name, no font, or damaged.
class FontZipException implements Exception {
  const FontZipException(this.message);
  final String message;

  @override
  String toString() => 'FontZipException: $message';
}

/// Most bytes the files of one font zip may add up to.
const maxFontZipBytes = 32 * 1024 * 1024;

final _driveRegExp = RegExp(r'^[a-zA-Z]:');

bool _isFontName(String lower) =>
    lower.endsWith('.ttf') || lower.endsWith('.otf');

bool _isLicenseName(String name) =>
    name == 'OFL.txt' || name.toUpperCase().startsWith('LICENSE');

/// Reads [zip] and returns the font files and the licence text by flat file
/// name (folders dropped). Pure: writes nothing. Everything that is not a
/// `.ttf` / `.otf` or a licence file is ignored. Throws [FontZipException]
/// for a `..`, absolute or drive path, two files with one name, a zip with no
/// font, or one that does not unpack.
Map<String, Uint8List> extractFontZip(Uint8List zip) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(zip);
  } on Object catch (e) {
    throw FontZipException('not a readable zip: ${e.runtimeType}');
  }
  final out = <String, Uint8List>{};
  final seen = <String>{};
  var total = 0;
  var fonts = 0;
  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final raw = entry.name.replaceAll('\\', '/');
    if (raw.startsWith('/') || _driveRegExp.hasMatch(raw)) {
      throw FontZipException('absolute path in zip: ${entry.name}');
    }
    final parts = raw
        .split('/')
        .where((p) => p.isNotEmpty && p != '.')
        .toList();
    if (parts.isEmpty || parts.contains('..')) {
      throw FontZipException('unsafe path in zip: ${entry.name}');
    }
    final name = parts.last;
    final isFont = _isFontName(name.toLowerCase());
    if (!isFont && !_isLicenseName(name)) continue;
    if (!seen.add(name.toLowerCase())) {
      throw FontZipException('two files named $name');
    }
    total += entry.size;
    if (total > maxFontZipBytes) throw const FontZipException('zip too large');
    final Uint8List bytes;
    try {
      bytes = entry.content;
    } on Object catch (e) {
      throw FontZipException('cannot unpack $name: ${e.runtimeType}');
    }
    if (bytes.length != entry.size) {
      throw FontZipException('size of $name does not match');
    }
    if (isFont) fonts++;
    out[name] = bytes;
  }
  if (fonts == 0) throw const FontZipException('no font file in zip');
  return out;
}

/// [extractFontZip] on a worker isolate, so a large zip never blocks a frame.
Future<Map<String, Uint8List>> extractFontZipInIsolate(Uint8List zip) =>
    Isolate.run(() => extractFontZip(zip));
