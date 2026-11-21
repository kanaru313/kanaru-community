import 'config_collection_rules.dart';
import 'config_field.dart';
import 'config_value_problem.dart';

export 'config_collection_rules.dart' show urlProblem, mapKeyIsValid;
export 'config_value_problem.dart';

/// Whether [value] is a legal value of [field] (emptiness is not checked:
/// `required` is the caller's concern).
bool valueFits(ConfigField field, Object? value) =>
    valueProblem(field, value) == null;

/// The first rule [value] breaks for [field], or null when it fits. Lists
/// and maps may be JSON-decoded (`List<dynamic>`, `Map<String, dynamic>`).
ValueProblem? valueProblem(ConfigField field, Object? value) => switch (field) {
  ToggleField() => value is bool ? null : ValueProblem.wrongType,
  SelectField() => _select(field, value),
  InputField() => _input(field, value),
  ListField() => listProblem(field, value),
  MapField() => mapProblem(field, value),
};

ValueProblem? _select(SelectField field, Object? value) {
  if (field.format == SelectFormat.single) {
    if (value is! String) return ValueProblem.wrongType;
    return field.options.any((o) => o.value == value)
        ? null
        : ValueProblem.notOption;
  }
  if (value is! List) return ValueProblem.wrongType;
  final seen = <Object?>{};
  for (final item in value) {
    if (item is! String) return ValueProblem.badItem;
    if (!field.options.any((o) => o.value == item)) {
      return ValueProblem.notOption;
    }
    if (!seen.add(item)) return ValueProblem.badItem;
  }
  return countProblem(
    value.length,
    min: field.minItems,
    max: field.maxItems,
    cap: field.options.length,
  );
}

ValueProblem? _input(InputField field, Object? value) {
  switch (field.format) {
    case InputFormat.number:
    case InputFormat.integer:
      final whole = field.format == InputFormat.integer;
      final number = finiteNumber(value, whole: whole);
      if (number == null) {
        return value is num && whole
            ? ValueProblem.notInteger
            : ValueProblem.wrongType;
      }
      if (number is int && number.abs() > configSafeInt) {
        return number < 0 ? ValueProblem.belowMin : ValueProblem.aboveMax;
      }
      final min = field.min;
      final max = field.max;
      if (min != null && number < min) return ValueProblem.belowMin;
      if (max != null && number > max) return ValueProblem.aboveMax;
      return null;
    case InputFormat.url:
      return value is String ? urlProblem(value) : ValueProblem.wrongType;
    case InputFormat.text:
    case InputFormat.multiline:
      if (value is! String) return ValueProblem.wrongType;
      final length = value.runes.length;
      if (length < (field.minLength ?? 0)) return ValueProblem.tooShort;
      if (length > (field.maxLength ?? configMaxText)) {
        return ValueProblem.tooLong;
      }
      return null;
  }
}

/// [value] as a finite number (an int when [whole]), or null. A string is
/// never read as a number.
num? finiteNumber(Object? value, {required bool whole}) {
  if (value is! num || !value.isFinite) return null;
  if (whole && value is! int) return null;
  return value;
}
