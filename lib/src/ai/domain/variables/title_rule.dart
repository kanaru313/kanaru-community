import '../text/text_sanitizer.dart';
import '../tools/model_text.dart';

/// Longest conversation title taken from the first message (characters).
const int conversationTitleChars = 40;

/// The title of a new conversation: the first 40 characters of the first
/// message with its variables already shown as their values ([filledText]),
/// cleaned like any model-facing text, plus "…" when it was cut.
String conversationTitle(String filledText) {
  final clean = sanitizeModelText(filledText, maxRunes: 1 << 20);
  if (clean.runes.length <= conversationTitleChars) return clean;
  return '${clipRunes(clean, conversationTitleChars).trimRight()}…';
}
