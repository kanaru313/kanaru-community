/// Small per-device key-value settings. Keys are `<module>.<name>`
/// (`library.tabs`, `playback.repeat`). Values are JSON-encodable.
abstract interface class SettingsStore {
  /// Current value from memory, or null when the key was never written.
  Object? read(String key);

  /// Stores [value] (null removes the key). Persisted in the background,
  /// coalesced; the future completes when the change is in memory and
  /// scheduled, not when it is on disk (use [flush] for that).
  Future<void> write(String key, Object? value);

  /// Keys that changed, one event per [write] that altered the value.
  Stream<String> get changes;

  /// Writes any pending change to disk now. Called on pause/hide and before exit.
  Future<void> flush();
}
