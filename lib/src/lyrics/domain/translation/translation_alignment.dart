import '../lyrics.dart';

/// The translation of [line] from [map] (source text, trimmed → translation),
/// or `null` for a gap, a missing or empty translation, and a translation
/// that only repeats the source ignoring case and whitespace.
String? translationFor(LyricLine line, Map<String, String> map) {
  final source = line.text.trim();
  if (source.isEmpty) return null;
  final translated = map[source] ?? map[line.text];
  if (translated == null) return null;
  final trimmed = translated.trim();
  if (trimmed.isEmpty) return null;
  if (_squash(trimmed) == _squash(source)) return null;
  return trimmed;
}

String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
