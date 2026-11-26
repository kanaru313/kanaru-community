/// Reads validated tool arguments. The schema check already ran, so types
/// are right; these helpers only apply defaults and clamps.
extension ToolArgs on Map<String, Object?> {
  int intOr(String key, int fallback) => (this[key] as int?) ?? fallback;

  /// A non-negative offset (0 when absent).
  int get offset => (this['offset'] as int?) ?? 0;

  String? string(String key) => this[key] as String?;

  List<int> intList(String key) =>
      ((this[key] as List?) ?? const []).cast<int>();
}

/// A page-size property, 1..[max], for the schema.
Map<String, Object?> limitProperty(int max, {String? description}) => {
  'type': 'integer',
  'minimum': 1,
  'maximum': max,
  'description': ?description,
};

Map<String, Object?> get offsetProperty => const {
  'type': 'integer',
  'minimum': 0,
  'description': 'Index of the first item to return (paging).',
};

/// An object schema with no extra arguments allowed.
Map<String, Object?> objectSchema(
  Map<String, Map<String, Object?>> properties, {
  List<String> required = const [],
}) => {
  'type': 'object',
  'properties': properties,
  if (required.isNotEmpty) 'required': required,
};
