import '../package/json_read.dart';
import '../package/package_problem.dart';
import 'config_attrs.dart';
import 'config_field.dart';
import 'config_number_text.dart';
import 'config_value_rules.dart';

/// Parses an `input` field. Stops with `UnknownConfigFormat` for a format
/// outside text, multiline, number, integer and url (`secret` included).
InputField readInputField({
  required String key,
  required String title,
  required String? subtitle,
  required bool required,
  required JsonObject raw,
}) {
  final path = 'config.$key';
  final format = switch (raw['format']) {
    null || 'text' => InputFormat.text,
    'multiline' => InputFormat.multiline,
    'number' => InputFormat.number,
    'integer' => InputFormat.integer,
    'url' => InputFormat.url,
    _ => throw PackageProblemError(UnknownConfigFormat('$path.format')),
  };
  final isText = format == InputFormat.text || format == InputFormat.multiline;
  final isNumeric =
      format == InputFormat.number || format == InputFormat.integer;
  final whole = format == InputFormat.integer;
  final minLength = isText
      ? readInt(raw, 'minLength', path, min: 0, max: configMaxText)
      : null;
  final maxLength = isText
      ? readInt(raw, 'maxLength', path, min: 1, max: configMaxText)
      : null;
  if (minLength != null && maxLength != null && minLength > maxLength) {
    invalid('$path.minLength');
  }
  final min = isNumeric ? readNumber(raw, 'min', path, whole: whole) : null;
  final max = isNumeric ? readNumber(raw, 'max', path, whole: whole) : null;
  if (min != null && max != null && min > max) invalid('$path.min');
  final step = isNumeric ? readNumber(raw, 'step', path, whole: whole) : null;
  if (step != null && step <= 0) invalid('$path.step');
  final field = InputField(
    key: key,
    title: title,
    subtitle: subtitle,
    required: required,
    format: format,
    placeholder: format == InputFormat.text || format == InputFormat.url
        ? readPlaceholder(raw, path)
        : null,
    minLength: minLength,
    maxLength: maxLength,
    rows: format == InputFormat.multiline
        ? readInt(raw, 'rows', path, min: configMinRows, max: configMaxRows)
        : null,
    min: min,
    max: max,
    step: step,
    defaultValue: _typedDefault(raw['default'], format),
  );
  final value = field.defaultValue;
  if (value != null && valueProblem(field, value) != null) {
    invalid('$path.default');
  }
  return field;
}

/// A number default may be a decimal string (the form older manifests used),
/// kept as a number; any other default is checked as it is.
Object? _typedDefault(Object? value, InputFormat format) {
  if (format == InputFormat.number && value is String) {
    return parseNumberText(value) ?? value;
  }
  return value;
}
