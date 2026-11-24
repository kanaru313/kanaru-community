import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../lyrics.dart';

/// Identifies the text of [lines] for the translation cache: lowercase hex
/// sha256 of the non-blank line texts joined with `\n`. Timestamps, gaps and
/// word timings are ignored, so re-timed lyrics of the same words keep their
/// saved translation.
///
/// This definition is a storage contract: changing it orphans every cached
/// translation.
String lyricsContentHash(List<LyricLine> lines) {
  final texts = [
    for (final line in lines)
      if (line.text.trim().isNotEmpty) line.text,
  ];
  return sha256.convert(utf8.encode(texts.join('\n'))).toString();
}
