import 'package_problem.dart';
import 'text_clean.dart';

/// A decoded JSON object. `jsonDecode` yields `Map<String, dynamic>`, which
/// is read through this type so no member access is dynamic.
typedef JsonObject = Map<String, Object?>;

/// Stops the parse with `InvalidManifest(field)`.
Never invalid(String field) =>
    throw PackageProblemError(InvalidManifest(field));

/// [value] as an object, or null when it is anything else.
JsonObject? asObject(Object? value) => value is JsonObject ? value : null;

/// A string with control characters removed and edges trimmed, then
/// length-checked in code points. A missing value gives '' when [optional].
String readText(
  Object? value,
  String field, {
  int min = 0,
  required int max,
  bool optional = false,
  bool keepNewlines = false,
}) {
  if (value == null && optional) return '';
  if (value is! String) invalid(field);
  final cleaned = cleanText(value, keepNewlines: keepNewlines);
  final length = cleaned.runes.length;
  if (length < min || length > max) invalid(field);
  return cleaned;
}

/// Optional integer within [min]..[max]; null when absent.
int? readInt(
  JsonObject raw,
  String attr,
  String path, {
  required int min,
  required int max,
}) {
  final value = raw[attr];
  if (value == null) return null;
  if (value is! int || value < min || value > max) invalid('$path.$attr');
  return value;
}

/// Optional boolean; [fallback] when absent.
bool readBool(
  JsonObject raw,
  String attr,
  String path, {
  bool fallback = false,
}) {
  final value = raw[attr];
  if (value == null) return fallback;
  if (value is! bool) invalid('$path.$attr');
  return value;
}
