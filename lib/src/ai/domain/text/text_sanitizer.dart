/// Cleans text that is untrusted for the model or for the screen: control
/// characters, bidirectional controls, zero-width characters and lone
/// surrogates. Shared by the tool rows, the model-text rules of the write
/// tools and the data fences of the prompt.
///
/// Removed: C0 and C1 controls (also DEL), soft hyphen, Arabic letter mark,
/// Mongolian vowel separator, zero-width space / joiners (U+200B-200D), the
/// bidi marks and overrides (U+200E-200F, U+202A-202E, U+2066-2069), word
/// joiner and invisible operators (U+2060-2064), the byte order mark, and the
/// specials block's interlinear marks. A lone surrogate becomes U+FFFD.
///
/// Line breaks (LF, CR, CRLF, NEL, U+2028, U+2029) are kept as one `\n` when
/// [keepLineBreaks] is true (a tab is kept too), otherwise they and tabs
/// become one space.
String sanitizeText(String input, {bool keepLineBreaks = false}) {
  final out = StringBuffer();
  final units = input.codeUnits;
  var i = 0;
  while (i < units.length) {
    final u = units[i];
    i++;
    if (u == 0x0D) {
      // CRLF is one break.
      if (i < units.length && units[i] == 0x0A) i++;
      _lineBreak(out, keepLineBreaks);
    } else if (u == 0x0A || u == 0x85 || u == 0x2028 || u == 0x2029) {
      _lineBreak(out, keepLineBreaks);
    } else if (u == 0x09) {
      out.writeCharCode(keepLineBreaks ? 0x09 : 0x20);
    } else if (_isRemoved(u)) {
      continue;
    } else if (u >= 0xD800 && u <= 0xDBFF) {
      if (i < units.length && units[i] >= 0xDC00 && units[i] <= 0xDFFF) {
        out.writeCharCode(u);
        out.writeCharCode(units[i]);
        i++;
      } else {
        out.writeCharCode(0xFFFD);
      }
    } else if (u >= 0xDC00 && u <= 0xDFFF) {
      out.writeCharCode(0xFFFD);
    } else {
      out.writeCharCode(u);
    }
  }
  return out.toString();
}

void _lineBreak(StringBuffer out, bool keep) =>
    out.writeCharCode(keep ? 0x0A : 0x20);

bool _isRemoved(int u) =>
    u < 0x20 ||
    (u >= 0x7F && u <= 0x9F) ||
    u == 0xAD ||
    u == 0x061C ||
    u == 0x180E ||
    (u >= 0x200B && u <= 0x200F) ||
    (u >= 0x202A && u <= 0x202E) ||
    (u >= 0x2060 && u <= 0x2064) ||
    (u >= 0x2066 && u <= 0x2069) ||
    u == 0xFEFF ||
    (u >= 0xFFF9 && u <= 0xFFFB);

/// Cuts [text] to at most [maxRunes] characters (code points), never inside a
/// surrogate pair.
String clipRunes(String text, int maxRunes) {
  if (maxRunes <= 0) return '';
  var count = 0;
  var end = 0;
  for (final r in text.runes) {
    if (count == maxRunes) return text.substring(0, end);
    count++;
    end += r > 0xFFFF ? 2 : 1;
  }
  return text;
}
