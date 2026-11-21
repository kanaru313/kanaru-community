import '../package/text_clean.dart';
import 'config_field.dart';
import 'config_value_problem.dart';

final _whitespace = RegExp(r'\s');

/// Item-count rule shared by a multiple select, a list and a map: below
/// [min], or above [max] (itself held to [cap]).
ValueProblem? countProblem(
  int count, {
  required int? min,
  required int? max,
  required int cap,
}) {
  if (count < (min ?? 0)) return ValueProblem.tooFewItems;
  final limit = max ?? cap;
  if (count > (limit < cap ? limit : cap)) return ValueProblem.tooManyItems;
  return null;
}

/// The text between `://` and the first `/`, `?` or `#`, or null without
/// `://`. The parsed authority drops an empty user name, so `https://@host`
/// is caught on the raw text; an `@` later in the URL is not user info.
String? _authorityOf(String value) {
  final scheme = value.indexOf('://');
  if (scheme < 0) return null;
  final start = scheme + 3;
  var end = start;
  while (end < value.length) {
    final c = value[end];
    if (c == '/' || c == '?' || c == '#') break;
    end++;
  }
  return value.substring(start, end);
}

/// https only, with a host, no credentials, no whitespace, control or format
/// characters, within the text cap. Null when [value] fits.
ValueProblem? urlProblem(String value) {
  if (value.runes.length > configMaxText) return ValueProblem.tooLong;
  if (_whitespace.hasMatch(value)) return ValueProblem.badUrl;
  final uri = Uri.tryParse(value);
  if (value != cleanText(value)) return ValueProblem.badUrl;
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.isEmpty ||
      _authorityOf(value)?.contains('@') != false) {
    return ValueProblem.badUrl;
  }
  return null;
}

/// 1 to 100 code points with no control or format characters and no outer
/// space; `__proto__` is refused. Case matters.
bool mapKeyIsValid(String key) =>
    key.isNotEmpty &&
    key.runes.length <= configMaxMapKey &&
    key == cleanText(key) &&
    key != '__proto__';

ValueProblem? listProblem(ListField field, Object? value) {
  if (value is! List) return ValueProblem.wrongType;
  final problem = countProblem(
    value.length,
    min: field.minItems,
    max: field.maxItems,
    cap: configMaxItems,
  );
  if (problem != null) return problem;
  for (final item in value) {
    final ok = switch (field.format) {
      ListFormat.text =>
        item is String &&
            item.trim().isNotEmpty &&
            item.runes.length <= configMaxText,
      ListFormat.url => item is String && urlProblem(item) == null,
      ListFormat.number => item is num && item.isFinite,
      ListFormat.integer => item is int && isSafeInt(item),
    };
    if (!ok) return ValueProblem.badItem;
  }
  return null;
}

ValueProblem? mapProblem(MapField field, Object? value) {
  if (value is! Map) return ValueProblem.wrongType;
  final max = field.maxItems ?? configMaxItems;
  if (value.length > (max < configMaxItems ? max : configMaxItems)) {
    return ValueProblem.tooManyItems;
  }
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String || !mapKeyIsValid(key)) return ValueProblem.badKey;
    final item = entry.value;
    if (item is! String || item.runes.length > configMaxText) {
      return ValueProblem.badItem;
    }
  }
  return null;
}
