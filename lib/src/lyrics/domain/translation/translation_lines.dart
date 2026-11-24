import '../../../plugins/domain/package/translate_spec.dart';
import '../lyrics.dart';

/// Most unique lines one translation job sends.
const maxTranslatedLines = 1000;

/// Most characters (summed over unique lines) one translation job sends.
const maxTranslatedChars = 20000;

/// Most chunks (plugin runs) one song may need.
const maxChunksPerSong = 20;

/// The distinct non-blank line texts of [lines], trimmed, in first-seen
/// order. A repeated chorus is sent once.
List<String> uniqueLineTexts(List<LyricLine> lines) {
  final seen = <String>{};
  return [
    for (final line in lines)
      if (line.text.trim().isNotEmpty && seen.add(line.text.trim()))
        line.text.trim(),
  ];
}

/// Splits [lines] into consecutive chunks of at most `spec.maxLines` lines
/// and `spec.maxChars` characters. A line longer than `maxChars` is alone in
/// its chunk. Order is kept.
List<List<String>> chunkLines(List<String> lines, TranslateSpec spec) {
  final chunks = <List<String>>[];
  var current = <String>[];
  var chars = 0;
  for (final line in lines) {
    final full =
        current.length >= spec.maxLines ||
        (current.isNotEmpty && chars + line.length > spec.maxChars);
    if (full) {
      chunks.add(current);
      current = <String>[];
      chars = 0;
    }
    current.add(line);
    chars += line.length;
  }
  if (current.isNotEmpty) chunks.add(current);
  return chunks;
}

/// Whether [lines] split into [chunks] exceed what one job may do; the
/// caller then fails with `tooLong` before sending anything.
bool exceedsTranslationCaps(List<String> lines, List<List<String>> chunks) {
  if (lines.length > maxTranslatedLines) return true;
  if (chunks.length > maxChunksPerSong) return true;
  var chars = 0;
  for (final line in lines) {
    chars += line.length;
  }
  return chars > maxTranslatedChars;
}
