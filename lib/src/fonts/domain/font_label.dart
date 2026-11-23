/// Largest font file accepted for import.
const maxCustomFontBytes = 20 * 1024 * 1024;

const _maxLabelLength = 64;

final _controlChars = RegExp(
  '[\u0000-\u001F\u007F-\u009F\u200E\u200F\u202A-\u202E\u2066-\u2069]',
);
final _whitespaceRun = RegExp(r'\s+');

/// Makes a name read from a font file safe to show: strips control and bidi
/// override characters, replaces lone surrogates, collapses whitespace, trims
/// and caps the length. Empty when nothing readable is left.
String sanitizeFontLabel(String raw) {
  final units = raw.codeUnits;
  final fixed = StringBuffer();
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    final isHigh = u >= 0xD800 && u <= 0xDBFF;
    final isLow = u >= 0xDC00 && u <= 0xDFFF;
    if (isHigh && i + 1 < units.length) {
      final next = units[i + 1];
      if (next >= 0xDC00 && next <= 0xDFFF) {
        fixed.writeCharCode(u);
        fixed.writeCharCode(next);
        i++;
        continue;
      }
    }
    fixed.writeCharCode(isHigh || isLow ? 0xFFFD : u);
  }
  // Tabs and newlines are whitespace, not noise: they become spaces first.
  final clean = fixed
      .toString()
      .replaceAll(_whitespaceRun, ' ')
      .replaceAll(_controlChars, '')
      .replaceAll(_whitespaceRun, ' ')
      .trim();
  if (clean.runes.length <= _maxLabelLength) return clean;
  return String.fromCharCodes(clean.runes.take(_maxLabelLength)).trim();
}

/// File name without its `.ttf` / `.otf` extension.
String fontFileStem(String fileName) =>
    fileName.replaceFirst(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '');
