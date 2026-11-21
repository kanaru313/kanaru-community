import '../package/json_read.dart';
import '../package/package_problem.dart';
import 'config_attrs.dart';
import 'config_field.dart';
import 'config_value_rules.dart';

/// Parses a `select` field.
SelectField readSelectField({
  required String key,
  required String title,
  required String? subtitle,
  required bool required,
  required JsonObject raw,
}) {
  final path = 'config.$key';
  final format = switch (raw['format']) {
    null || 'single' => SelectFormat.single,
    'multiple' => SelectFormat.multiple,
    _ => throw PackageProblemError(UnknownConfigFormat('$path.format')),
  };
  final custom = readBool(raw, 'custom', path);
  // The user adds the choices of a custom select, so it is single choice.
  if (custom && format == SelectFormat.multiple) invalid('$path.custom');
  final options = _options(raw['options'], '$path.options', allowEmpty: custom);
  final multiple = format == SelectFormat.multiple;
  final (minItems, maxItems) = multiple
      ? readItemBounds(raw, path, options.length)
      : (null, null);
  SelectField build(Object? value) => SelectField(
    key: key,
    title: title,
    subtitle: subtitle,
    required: required,
    format: format,
    options: options,
    custom: custom,
    minItems: minItems,
    maxItems: maxItems,
    defaultValue: value,
  );
  final value = raw['default'];
  if (value == null) return build(null);
  if (valueProblem(build(value), value) != null) invalid('$path.default');
  return build(value is List ? List<String>.unmodifiable(value) : value);
}

/// Parses a `list` field.
ListField readListField({
  required String key,
  required String title,
  required String? subtitle,
  required bool required,
  required JsonObject raw,
}) {
  final path = 'config.$key';
  final format = switch (raw['format']) {
    null || 'text' => ListFormat.text,
    'number' => ListFormat.number,
    'integer' => ListFormat.integer,
    'url' => ListFormat.url,
    _ => throw PackageProblemError(UnknownConfigFormat('$path.format')),
  };
  final (minItems, maxItems) = readItemBounds(raw, path, configMaxItems);
  final placeholder = readPlaceholder(raw, path);
  ListField build(Object? value) => ListField(
    key: key,
    title: title,
    subtitle: subtitle,
    required: required,
    format: format,
    placeholder: placeholder,
    minItems: minItems,
    maxItems: maxItems,
    defaultValue: value,
  );
  final value = raw['default'];
  if (value == null) return build(null);
  if (valueProblem(build(value), value) != null) invalid('$path.default');
  return build(switch (format) {
    ListFormat.number => List<num>.unmodifiable((value as List).cast<num>()),
    ListFormat.integer => List<int>.unmodifiable((value as List).cast<int>()),
    _ => List<String>.unmodifiable((value as List).cast<String>()),
  });
}

/// Parses a `map` field (text keys and text values).
MapField readMapField({
  required String key,
  required String title,
  required String? subtitle,
  required bool required,
  required JsonObject raw,
}) {
  final path = 'config.$key';
  final format = raw['format'];
  if (format != null && format != 'text') {
    throw PackageProblemError(UnknownConfigFormat('$path.format'));
  }
  final maxItems = readInt(raw, 'maxItems', path, min: 1, max: configMaxItems);
  MapField build(Object? value) => MapField(
    key: key,
    title: title,
    subtitle: subtitle,
    required: required,
    maxItems: maxItems,
    defaultValue: value,
  );
  final value = raw['default'];
  if (value == null) return build(null);
  if (valueProblem(build(value), value) != null) invalid('$path.default');
  return build(Map<String, String>.unmodifiable((value as Map).cast()));
}

List<ConfigOption> _options(
  Object? value,
  String field, {
  required bool allowEmpty,
}) {
  // A custom select may leave `options` out too.
  if (allowEmpty && value == null) return const [];
  if (value is! List ||
      (value.isEmpty && !allowEmpty) ||
      value.length > configMaxItems) {
    invalid(field);
  }
  final options = <ConfigOption>[];
  final seen = <String>{};
  for (final item in value) {
    final map = asObject(item);
    if (map == null) invalid(field);
    final optionValue = map['value'];
    if (optionValue is! String ||
        optionValue.isEmpty ||
        optionValue.runes.length > 200 ||
        !seen.add(optionValue)) {
      invalid(field);
    }
    options.add(
      ConfigOption(
        value: optionValue,
        title: readConfigTitle(map['title'], field),
        subtitle: readConfigSubtitle(map['subtitle'], field),
      ),
    );
  }
  return List.unmodifiable(options);
}
