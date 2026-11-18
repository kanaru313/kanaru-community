/// A typed settings key with a default. Pure Dart; modules declare their own
/// constants.
class Setting<T> {
  const Setting(
    this.key,
    this.defaultValue, {
    required this.decode,
    required this.encode,
  });

  final String key;
  final T defaultValue;

  /// Turns the stored JSON into [T]. Throws [FormatException] on a value it
  /// does not understand; the default is used then.
  final T Function(Object? json) decode;

  /// Turns [T] into a JSON-encodable value.
  final Object? Function(T value) encode;
}

/// The member of [values] named [raw]. Throws [FormatException] when [raw] is
/// not a string or names no member, so a [Setting.decode] using it falls back
/// to the default.
T enumByName<T extends Enum>(List<T> values, Object? raw) {
  if (raw is String) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
  }
  throw FormatException('unknown value: $raw');
}
