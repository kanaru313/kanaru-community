import '../../../foundation/result.dart';
import '../package/json_read.dart';
import '../package/package_problem.dart';
import 'config_attrs.dart';
import 'config_collection_parser.dart';
import 'config_field.dart';
import 'config_input_parser.dart';

final _configKey = RegExp(r'^[A-Za-z0-9_]{1,40}$');

/// Parses the optional `config` object of a manifest (at most 20 fields,
/// kept in manifest order). Attributes that do not apply to a field's mode
/// and format are ignored, except `custom`, which only a `select` may carry.
Result<List<ConfigField>, PackageProblem> parseConfigSchema(Object? value) {
  try {
    return Ok(readConfigSchema(value));
  } on PackageProblemError catch (e) {
    return Err(e.problem);
  }
}

/// [parseConfigSchema] for the manifest parser: stops with the problem.
List<ConfigField> readConfigSchema(Object? value) {
  if (value == null) return const [];
  final object = asObject(value);
  if (object == null || object.length > configMaxFields) invalid('config');
  return List.unmodifiable([
    for (final entry in object.entries) _field(entry.key, entry.value),
  ]);
}

ConfigField _field(String key, Object? value) {
  final path = 'config.$key';
  if (!_configKey.hasMatch(key)) invalid(path);
  final raw = asObject(value);
  if (raw == null) invalid(path);
  if (raw['custom'] != null && raw['mode'] != 'select') {
    invalid('$path.custom');
  }
  final title = readConfigTitle(raw['title'], '$path.title');
  final subtitle = readConfigSubtitle(raw['subtitle'], '$path.subtitle');
  final required = readBool(raw, 'required', path);
  return switch (raw['mode']) {
    'input' => readInputField(
      key: key,
      title: title,
      subtitle: subtitle,
      required: required,
      raw: raw,
    ),
    'select' => readSelectField(
      key: key,
      title: title,
      subtitle: subtitle,
      required: required,
      raw: raw,
    ),
    'list' => readListField(
      key: key,
      title: title,
      subtitle: subtitle,
      required: required,
      raw: raw,
    ),
    'map' => readMapField(
      key: key,
      title: title,
      subtitle: subtitle,
      required: required,
      raw: raw,
    ),
    'toggle' => _toggle(key, title, subtitle, required, raw),
    _ => invalid('$path.mode'),
  };
}

ToggleField _toggle(
  String key,
  String title,
  String? subtitle,
  bool required,
  JsonObject raw,
) {
  final path = 'config.$key';
  if (raw['format'] != null) {
    throw PackageProblemError(UnknownConfigFormat('$path.format'));
  }
  final fallback = raw['default'];
  if (fallback != null && fallback is! bool) invalid('$path.default');
  return ToggleField(
    key: key,
    title: title,
    subtitle: subtitle,
    required: required,
    defaultValue: fallback,
  );
}
