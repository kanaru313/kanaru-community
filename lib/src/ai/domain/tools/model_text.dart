import '../text/text_sanitizer.dart';

/// Cleans a string the model wrote before the app stores or shows it
/// (playlist names, card fields, titles, `[[t:ID]]` labels): control, bidi
/// and zero-width characters go, line breaks and tabs become spaces, runs of
/// spaces collapse, the ends are trimmed and the text is cut at [maxRunes]
/// characters. The result may be empty: callers refuse an empty name.
String sanitizeModelText(String input, {int maxRunes = 100}) {
  final cleaned = sanitizeText(input).replaceAll(RegExp(r' {2,}'), ' ').trim();
  return clipRunes(cleaned, maxRunes).trim();
}
