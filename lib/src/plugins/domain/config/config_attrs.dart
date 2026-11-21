import '../package/json_read.dart';
import '../package/text_clean.dart';
import 'config_field.dart';

/// Title of a field or option: 1 to 80 code points once cleaned.
String readConfigTitle(Object? value, String field) =>
    readText(value, field, min: 1, max: 80);

/// Optional help text: at most 300 characters, newlines kept; blank is none.
String? readConfigSubtitle(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) invalid(field);
  final text = cleanText(value, keepNewlines: true);
  if (text.runes.length > 300) invalid(field);
  return text.isEmpty ? null : text;
}

/// Optional placeholder: at most 200 characters; blank is none.
String? readPlaceholder(JsonObject raw, String path) {
  final value = raw['placeholder'];
  if (value == null) return null;
  if (value is! String) invalid('$path.placeholder');
  final text = cleanText(value);
  if (text.runes.length > configMaxPlaceholder) invalid('$path.placeholder');
  return text.isEmpty ? null : text;
}

/// Optional finite JSON number; an integer field takes integers in the safe
/// range only.
num? readNumber(
  JsonObject raw,
  String attr,
  String path, {
  required bool whole,
}) {
  final value = raw[attr];
  if (value == null) return null;
  if (value is! num || !value.isFinite) invalid('$path.$attr');
  if (whole && (value is! int || !isSafeInt(value))) {
    invalid('$path.$attr');
  }
  return value;
}

/// `minItems` / `maxItems` of a list or multiple select, capped at [cap].
(int?, int?) readItemBounds(JsonObject raw, String path, int cap) {
  final min = readInt(raw, 'minItems', path, min: 0, max: cap);
  final max = readInt(raw, 'maxItems', path, min: 1, max: cap);
  if (min != null && max != null && min > max) invalid('$path.minItems');
  return (min, max);
}
