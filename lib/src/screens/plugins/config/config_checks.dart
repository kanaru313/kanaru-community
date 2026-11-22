import '../../../plugins/domain/config/config_field.dart';
import '../../../plugins/domain/config/config_number_text.dart';
import '../../../plugins/domain/config/config_value_rules.dart';

/// What is wrong with what the user typed, before anything is sent. The
/// words come from `config_texts.dart`.
enum ConfigIssueKind {
  required,
  notNumber,
  notInteger,
  belowMin,
  aboveMax,
  tooShort,
  tooLong,
  badUrl,
  tooFewItems,
  tooManyItems,
  badItem,
  badName,
  duplicateName,
}

class ConfigIssue {
  const ConfigIssue(this.kind, [this.n]);

  final ConfigIssueKind kind;

  /// The bound the issue names (min, max, length, item count).
  final num? n;

  /// Whether what the user typed must not be sent. A missing required value
  /// is shown but still sent (the empty value is how the plugin's "needs
  /// setup" band learns of it).
  bool get blocks => kind != ConfigIssueKind.required;

  @override
  bool operator ==(Object other) =>
      other is ConfigIssue && other.kind == kind && other.n == n;

  @override
  int get hashCode => Object.hash(kind, n);
}

/// What a box holds, read for the store.
class ConfigCheck {
  const ConfigCheck._(this.value, this.issue, this.cleared);

  /// Nothing typed: the value goes back to the default.
  const ConfigCheck.cleared() : this._(null, null, true);

  const ConfigCheck.value(Object? value) : this._(value, null, false);

  const ConfigCheck.bad(ConfigIssue issue) : this._(null, issue, false);

  final Object? value;
  final ConfigIssue? issue;
  final bool cleared;

  bool get ok => issue == null;
}

/// A text, multiline, number, integer or url box. Whitespace only is empty.
ConfigCheck checkInputText(InputField field, String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const ConfigCheck.cleared();
  switch (field.format) {
    case InputFormat.number:
    case InputFormat.integer:
      final whole = field.format == InputFormat.integer;
      final number = parseNumberText(trimmed, whole: whole);
      if (number == null) {
        return ConfigCheck.bad(
          ConfigIssue(
            whole ? ConfigIssueKind.notInteger : ConfigIssueKind.notNumber,
          ),
        );
      }
      final min = field.min;
      final max = field.max;
      if (min != null && number < min) {
        return ConfigCheck.bad(ConfigIssue(ConfigIssueKind.belowMin, min));
      }
      if (max != null && number > max) {
        return ConfigCheck.bad(ConfigIssue(ConfigIssueKind.aboveMax, max));
      }
      return _fits(field, number, whole ? ConfigIssueKind.notInteger : null);
    case InputFormat.url:
      final problem = urlProblem(trimmed);
      if (problem == null) return ConfigCheck.value(trimmed);
      return ConfigCheck.bad(
        problem == ValueProblem.tooLong
            ? const ConfigIssue(ConfigIssueKind.tooLong, configMaxText)
            : const ConfigIssue(ConfigIssueKind.badUrl),
      );
    case InputFormat.text:
    case InputFormat.multiline:
      final length = text.runes.length;
      final min = field.minLength;
      final max = field.maxLength ?? configMaxText;
      if (min != null && length < min) {
        return ConfigCheck.bad(ConfigIssue(ConfigIssueKind.tooShort, min));
      }
      if (length > max) {
        return ConfigCheck.bad(ConfigIssue(ConfigIssueKind.tooLong, max));
      }
      return ConfigCheck.value(text);
  }
}

/// The store's own rule as the last word (a number past the safe range).
ConfigCheck _fits(InputField field, num number, ConfigIssueKind? otherwise) =>
    valueFits(field, number)
    ? ConfigCheck.value(number)
    : ConfigCheck.bad(ConfigIssue(otherwise ?? ConfigIssueKind.notNumber));

/// A list: [rows] are the non-blank rows in order. [bad] are the positions of
/// the rows that do not fit the list's format.
class ListCheck {
  const ListCheck(this.value, this.bad, this.issue);

  final List<Object> value;
  final Set<int> bad;
  final ConfigIssue? issue;

  bool get canSend => !(issue?.blocks ?? false);
}

ListCheck checkList(ListField field, List<String> rows) {
  final items = <Object>[];
  final bad = <int>{};
  for (var i = 0; i < rows.length; i++) {
    final text = rows[i].trim();
    final item = switch (field.format) {
      ListFormat.text => text.runes.length <= configMaxText ? text : null,
      ListFormat.url => urlProblem(text) == null ? text : null,
      ListFormat.number => parseNumberText(text),
      ListFormat.integer => parseNumberText(text, whole: true),
    };
    if (item == null || (item is num && !valueFits(_probe(field), [item]))) {
      bad.add(i);
    } else {
      items.add(item);
    }
  }
  if (bad.isNotEmpty) {
    return ListCheck(items, bad, const ConfigIssue(ConfigIssueKind.badItem));
  }
  return ListCheck(
    items,
    bad,
    _countIssue(items.length, field.minItems, field.maxItems, field.required),
  );
}

/// [field] without count bounds, to ask the store's rule about one item.
ListField _probe(ListField field) =>
    ListField(key: field.key, title: field.title, format: field.format);

ConfigIssue? _countIssue(int count, int? min, int? max, bool required) {
  if (count < (min ?? 0)) return ConfigIssue(ConfigIssueKind.tooFewItems, min);
  final limit = max == null || max > configMaxItems ? configMaxItems : max;
  if (count > limit) return ConfigIssue(ConfigIssueKind.tooManyItems, limit);
  if (count == 0 && required) {
    return const ConfigIssue(ConfigIssueKind.required);
  }
  return null;
}

/// A table: row issues by position among the non-blank rows, and one for the
/// whole table.
class MapCheck {
  const MapCheck(this.value, this.rowIssues, this.issue);

  final Map<String, String> value;
  final Map<int, ConfigIssue> rowIssues;
  final ConfigIssue? issue;

  /// Nothing may be saved while a row is wrong.
  bool get canSend => rowIssues.isEmpty && !(issue?.blocks ?? false);
}

MapCheck checkMap(MapField field, List<(String, String)> rows) {
  final value = <String, String>{};
  final issues = <int, ConfigIssue>{};
  for (var i = 0; i < rows.length; i++) {
    final (name, text) = rows[i];
    if (!mapKeyIsValid(name)) {
      issues[i] = const ConfigIssue(ConfigIssueKind.badName);
    } else if (value.containsKey(name)) {
      issues[i] = const ConfigIssue(ConfigIssueKind.duplicateName);
    } else if (text.runes.length > configMaxText) {
      issues[i] = const ConfigIssue(ConfigIssueKind.tooLong, configMaxText);
    } else {
      value[name] = text;
    }
  }
  final max = field.maxItems == null || field.maxItems! > configMaxItems
      ? configMaxItems
      : field.maxItems!;
  ConfigIssue? issue;
  if (rows.length > max) {
    issue = ConfigIssue(ConfigIssueKind.tooManyItems, max);
  } else if (rows.isEmpty && field.required) {
    issue = const ConfigIssue(ConfigIssueKind.required);
  }
  return MapCheck(value, issues, issue);
}

/// The chips of a multiple select: [chosen] values in any order.
ConfigIssue? checkChoices(SelectField field, int chosen) {
  final min = field.minItems;
  if (chosen < (min ?? 0)) {
    return ConfigIssue(ConfigIssueKind.tooFewItems, min);
  }
  if (chosen == 0 && field.required) {
    return const ConfigIssue(ConfigIssueKind.required);
  }
  return null;
}

/// [value] as the text of a box: no decimal point when whole, no float noise
/// (`0.30000000000000004`).
String configNumberText(num value) {
  if (value is int) return '$value';
  final rounded = (value * 1e10).round() / 1e10;
  return rounded == rounded.truncateToDouble() && rounded.abs() < 1e15
      ? '${rounded.toInt()}'
      : '$rounded';
}

/// What to store for [value] of [field]: null (no override, the default
/// applies) when it equals the default the form already shows, else [value].
/// A toggle without a default reads as off; an emptied list, table or choice
/// set is still stored (empty is a value the plugin's required check sees).
/// With [anyOrder] lists match as sets (a multiple select's chips).
Object? configOverride(
  ConfigField field,
  Object? value, {
  bool anyOrder = false,
}) {
  final effective = field.defaultValue ?? (field is ToggleField ? false : null);
  return _sameValue(value, effective, anyOrder) ? null : value;
}

bool _sameValue(Object? a, Object? b, bool anyOrder) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    if (anyOrder) return a.toSet().containsAll(b);
    for (var i = 0; i < a.length; i++) {
      if (!_sameValue(a[i], b[i], false)) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || !_sameValue(e.value, b[e.key], false)) {
        return false;
      }
    }
    return true;
  }
  return a == b || (a != null && b != null && '$a' == '$b');
}
