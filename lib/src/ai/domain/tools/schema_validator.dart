/// Validates tool arguments against the JSON Schema subset the chat contract
/// allows: `type` (object, string, integer, number, boolean, array),
/// `properties`, `required`, `items`, `enum`, `minimum`, `maximum`,
/// `maxItems`. Unknown keys of the value are
/// rejected for objects, so a model cannot smuggle extra arguments.
///
/// Returns null when [value] is valid, else a short message naming the path.
String? validateAgainstSchema(Map<String, Object?> schema, Object? value) =>
    _check(schema, value, r'$');

String? _check(Map<String, Object?> schema, Object? value, String path) {
  final type = schema['type'];
  switch (type) {
    case 'object':
      if (value is! Map) return '$path must be an object';
      final props = (schema['properties'] as Map?)?.cast<String, Object?>();
      final required =
          (schema['required'] as List?)?.cast<String>() ?? const [];
      for (final key in required) {
        if (value[key] == null) return '$path.$key is required';
      }
      for (final entry in value.entries) {
        final key = entry.key;
        final sub = props?[key];
        if (key is! String || sub is! Map<String, Object?>) {
          return '$path has an unknown argument "${_clip('$key')}"';
        }
        if (entry.value == null) continue; // null counts as absent
        final err = _check(sub, entry.value, '$path.$key');
        if (err != null) return err;
      }
      return null;
    case 'string':
      if (value is! String) return '$path must be a string';
      return _enumCheck(schema, value, path);
    case 'integer':
      if (value is! int) return '$path must be an integer';
      return _rangeCheck(schema, value, path) ??
          _enumCheck(schema, value, path);
    case 'number':
      if (value is! num) return '$path must be a number';
      return _rangeCheck(schema, value, path);
    case 'boolean':
      return value is bool ? null : '$path must be a boolean';
    case 'array':
      if (value is! List) return '$path must be an array';
      final max = schema['maxItems'];
      if (max is int && value.length > max) {
        return '$path must have at most $max items';
      }
      final items = schema['items'];
      if (items is Map<String, Object?>) {
        for (var i = 0; i < value.length; i++) {
          final err = _check(items, value[i], '$path[$i]');
          if (err != null) return err;
        }
      }
      return null;
    default:
      throw ArgumentError('unsupported schema type: $type');
  }
}

String? _rangeCheck(Map<String, Object?> schema, num value, String path) {
  final min = schema['minimum'];
  final max = schema['maximum'];
  if (min is num && value < min) return '$path must be at least $min';
  if (max is num && value > max) return '$path must be at most $max';
  return null;
}

String? _enumCheck(Map<String, Object?> schema, Object value, String path) {
  final allowed = schema['enum'];
  if (allowed is List && !allowed.contains(value)) {
    return '$path must be one of ${allowed.join(', ')}';
  }
  return null;
}

String _clip(String s) => s.length <= 40 ? s : '${s.substring(0, 40)}...';
