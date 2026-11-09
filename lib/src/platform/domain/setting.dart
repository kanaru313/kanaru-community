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
