import 'config_field.dart';

/// The required fields of [schema] that have no usable value in [config]
/// (what a run would read, defaults already merged in). Empty means the
/// plugin is ready.
///
/// A value is missing when it is absent, a string with nothing but
/// whitespace, or an empty list or map. A toggle is never missing (off is an
/// answer). A number zero is a value.
List<ConfigField> missingRequiredConfig(
  List<ConfigField> schema,
  Map<String, Object?> config,
) => [
  for (final field in schema)
    if (field.required && field is! ToggleField && _isEmpty(config[field.key]))
      field,
];

bool _isEmpty(Object? value) => switch (value) {
  null => true,
  String s => s.trim().isEmpty,
  List<Object?> l => l.isEmpty,
  Map<Object?, Object?> m => m.isEmpty,
  _ => false,
};
