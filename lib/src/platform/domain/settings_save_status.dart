/// Whether the last attempt to write settings to disk failed. Pure Dart; a
/// store may implement it next to `SettingsStore`.
abstract interface class SettingsSaveStatus {
  /// Emits `true` when a write fails and `false` when a later one succeeds;
  /// only changes are emitted.
  Stream<bool> get saveFailing;

  /// The latest value of [saveFailing] (`false` before any write).
  bool get isFailing;
}
