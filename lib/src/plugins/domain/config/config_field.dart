/// Entry kind of an `input` field. There is no secret kind: the app stores
/// every value as plain text, so a package asking for one is refused.
enum InputFormat { text, multiline, number, integer, url }

/// One value or several of a `select` field.
enum SelectFormat { single, multiple }

/// Item kind of a `list` field.
enum ListFormat { text, number, integer, url }

/// Limits shared by the manifest parser, the config store and the form.
const configMaxFields = 20;
const configMaxItems = 50;

/// Longest text value (code points): input text, list item, map value, url.
const configMaxText = 2000;
const configMaxMapKey = 100;
const configMaxPlaceholder = 200;
const configMinRows = 1;
const configMaxRows = 10;

/// Largest integer a script reads back exactly (a JS number).
const configSafeInt = 9007199254740991;

/// One choice of a `select` field.
class ConfigOption {
  const ConfigOption({required this.value, required this.title, this.subtitle});

  final String value;
  final String title;

  /// Optional second line under the title.
  final String? subtitle;
}

/// One setting a plugin asks the user for. Attributes that do not apply to
/// a field's kind are not on its class.
sealed class ConfigField {
  const ConfigField({
    required this.key,
    required this.title,
    this.subtitle,
    this.required = false,
  });

  /// Name the script reads with `localConfig.getItem(key)`.
  final String key;
  final String title;

  /// Optional help text under the title; may hold newlines.
  final String? subtitle;

  /// The plugin is not ready while the value is empty (a toggle ignores it).
  final bool required;

  /// Initial value, typed by the field: `String` (text, multiline, url,
  /// single select), `num` (number), `int` (integer), `bool` (toggle),
  /// `List<String>` (multiple select, text and url list), `List<num>` /
  /// `List<int>` (number / integer list), `Map<String, String>` (map). Null
  /// when the manifest gives none.
  Object? get defaultValue;
}

final class InputField extends ConfigField {
  const InputField({
    required super.key,
    required super.title,
    super.subtitle,
    super.required,
    this.format = InputFormat.text,
    this.placeholder,
    this.minLength,
    this.maxLength,
    this.rows,
    this.min,
    this.max,
    this.step,
    this.defaultValue,
  });

  final InputFormat format;
  final String? placeholder;

  /// Length bounds (code points) of a text or multiline input.
  final int? minLength;
  final int? maxLength;

  /// Visible lines of a multiline input.
  final int? rows;

  /// Bounds of a number or integer input.
  final num? min;
  final num? max;

  /// Arrow-key increment of a number or integer input (a hint only).
  final num? step;

  @override
  final Object? defaultValue;
}

final class SelectField extends ConfigField {
  const SelectField({
    required super.key,
    required super.title,
    super.subtitle,
    super.required,
    this.format = SelectFormat.single,
    this.options = const [],
    this.custom = false,
    this.minItems,
    this.maxItems,
    this.defaultValue,
  });

  final SelectFormat format;
  final List<ConfigOption> options;

  /// Single select only: the user may add choices of their own, so
  /// [options] may be empty.
  final bool custom;

  /// Item count bounds of a multiple select.
  final int? minItems;
  final int? maxItems;

  @override
  final Object? defaultValue;
}

final class ToggleField extends ConfigField {
  const ToggleField({
    required super.key,
    required super.title,
    super.subtitle,
    super.required,
    this.defaultValue,
  });

  @override
  final Object? defaultValue;
}

final class ListField extends ConfigField {
  const ListField({
    required super.key,
    required super.title,
    super.subtitle,
    super.required,
    this.format = ListFormat.text,
    this.placeholder,
    this.minItems,
    this.maxItems,
    this.defaultValue,
  });

  final ListFormat format;
  final String? placeholder;
  final int? minItems;
  final int? maxItems;

  @override
  final Object? defaultValue;
}

/// Text keys and text values.
final class MapField extends ConfigField {
  const MapField({
    required super.key,
    required super.title,
    super.subtitle,
    super.required,
    this.maxItems,
    this.defaultValue,
  });

  final int? maxItems;

  @override
  final Object? defaultValue;
}
