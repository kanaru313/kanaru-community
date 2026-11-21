import 'dart:convert';

import '../../domain/config/config_field.dart';
import '../../domain/config/config_value_rules.dart';

/// Longest name of a choice the user adds, and its note (code points).
const customChoiceMaxValue = 200;
const customChoiceMaxSubtitle = 300;

/// One choice the user added to a `custom` single select.
class CustomChoice {
  const CustomChoice(this.value, [this.subtitle]);

  final String value;
  final String? subtitle;

  Map<String, Object> toJson() => {'value': value, 'subtitle': ?subtitle};
}

/// The user's choices by field key.
typedef CustomChoices = Map<String, List<CustomChoice>>;

/// What is stored for one plugin: the values and the user's own choices.
class PluginConfigData {
  const PluginConfigData({this.values = const {}, this.choices = const {}});

  /// Field key to the value as stored (what a form shows).
  final Map<String, Object?> values;

  final CustomChoices choices;
}

/// A name or note typed by the user: control characters out, ends trimmed.
String cleanChoiceText(String text) =>
    text.replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), '').trim();

/// Whether [field] lets the user add choices (a single select with `custom`).
bool isCustomSelect(ConfigField field) =>
    field is SelectField && field.custom && field.format == SelectFormat.single;

/// [field] as the user sees it: a `custom` single select gains [choices]
/// after the plugin's own options. Entries that are empty, repeat an option,
/// or pass [configMaxItems] are ignored. Any other field is returned as is.
ConfigField effectiveField(ConfigField field, List<CustomChoice> choices) {
  if (field is! SelectField || !isCustomSelect(field) || choices.isEmpty) {
    return field;
  }
  final options = [...field.options];
  final seen = {for (final o in options) o.value};
  for (final choice in choices) {
    if (options.length >= configMaxItems) break;
    if (choice.value.isEmpty || !seen.add(choice.value)) continue;
    options.add(
      ConfigOption(
        value: choice.value,
        title: choice.value,
        subtitle: choice.subtitle,
      ),
    );
  }
  return SelectField(
    key: field.key,
    title: field.title,
    subtitle: field.subtitle,
    required: field.required,
    format: field.format,
    options: options,
    custom: field.custom,
    minItems: field.minItems,
    maxItems: field.maxItems,
    defaultValue: field.defaultValue,
  );
}

/// What a script reads for [field]: the stored value, else the default, and
/// null when that does not fit the field (it never falls back to the default
/// then). [field] should come from [effectiveField].
Object? effectiveValue(ConfigField field, Map<String, Object?> stored) {
  final value = stored[field.key] ?? field.defaultValue;
  return value != null && valueFits(field, value) ? value : null;
}

/// Everything a script reads for [fields]: per field the stored value, else
/// the default; a value that does not fit is left out. The same rule as
/// [effectiveValue], over the effective field of each select. Collections
/// are copied.
Map<String, Object> resolveRunConfig(
  List<ConfigField> fields,
  PluginConfigData data,
) {
  final out = <String, Object>{};
  for (final field in fields) {
    final effective = effectiveField(
      field,
      data.choices[field.key] ?? const [],
    );
    final value = effectiveValue(effective, data.values);
    if (value == null) continue;
    out[field.key] = switch (value) {
      List() => [...value],
      Map() => {...value},
      _ => value,
    };
  }
  return out;
}

/// The stored values text decoded; unreadable text, or text that is not an
/// object, counts as no values.
Map<String, Object?> decodeValues(String text) {
  final value = _tryDecode(text);
  return value is Map<String, dynamic> ? {...value} : {};
}

/// The stored choices text decoded; entries that are not a well-formed
/// `{value: String, subtitle?: String}` are dropped.
CustomChoices decodeChoices(String text) {
  final value = _tryDecode(text);
  final out = <String, List<CustomChoice>>{};
  if (value is! Map) return out;
  for (final entry in value.entries) {
    final list = entry.value;
    if (entry.key is! String || list is! List) continue;
    final choices = <CustomChoice>[];
    for (final item in list) {
      if (item is! Map) continue;
      final name = item['value'];
      final note = item['subtitle'];
      if (name is! String || name.isEmpty) continue;
      choices.add(
        CustomChoice(name, note is String && note.isNotEmpty ? note : null),
      );
    }
    if (choices.isNotEmpty) out[entry.key as String] = choices;
  }
  return out;
}

/// [choices] as stored text; a field without choices has no entry.
String encodeChoices(CustomChoices choices) => jsonEncode({
  for (final e in choices.entries)
    if (e.value.isNotEmpty) e.key: [for (final c in e.value) c.toJson()],
});

Object? _tryDecode(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}

String _mode(ConfigField f) => switch (f) {
  InputField() => 'input',
  SelectField() => 'select',
  ToggleField() => 'toggle',
  ListField() => 'list',
  MapField() => 'map',
};

String _format(ConfigField f) => switch (f) {
  InputField(:final format) => format.name,
  SelectField(:final format) => format.name,
  ListField(:final format) => format.name,
  ToggleField() || MapField() => '',
};

/// The stored values and choices after the form went from [before] to
/// [after]. A value stays only when its field still exists with the same
/// mode and format and the value still fits (a choice the user added counts
/// only while the field is still a `custom` select, whose choices stay). A
/// key with no field in [after] goes. Inputs are not changed.
({Map<String, Object?> values, CustomChoices choices}) adaptConfig(
  List<ConfigField> before,
  List<ConfigField> after,
  Map<String, Object?> values,
  CustomChoices choices,
) {
  ConfigField? find(List<ConfigField> form, String key) {
    for (final f in form) {
      if (f.key == key) return f;
    }
    return null;
  }

  final keptChoices = <String, List<CustomChoice>>{
    for (final e in choices.entries)
      if (find(after, e.key) case final f? when isCustomSelect(f))
        e.key: e.value,
  };
  final keptValues = <String, Object?>{};
  for (final entry in values.entries) {
    final field = find(after, entry.key);
    if (field == null) continue;
    final old = find(before, entry.key);
    if (old != null &&
        (_mode(old) != _mode(field) || _format(old) != _format(field))) {
      continue;
    }
    final effective = effectiveField(field, keptChoices[entry.key] ?? const []);
    if (valueFits(effective, entry.value)) keptValues[entry.key] = entry.value;
  }
  return (values: keptValues, choices: keptChoices);
}
