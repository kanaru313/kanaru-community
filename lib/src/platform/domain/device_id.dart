/// Provides the id of this install, stable across starts.
abstract interface class DeviceIdSource {
  /// Returns the stored id, creating and storing a new one when missing or invalid.
  Future<String> load();
}
