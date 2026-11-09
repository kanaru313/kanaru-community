import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../domain/setting.dart';
import '../domain/settings_store.dart';

/// Overridden by `runKanaru` (and by tests) with the real store.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider must be overridden'),
);

/// Holds one [Setting]'s value; rebuilds when its key changes in the store.
class SettingNotifier<T> extends Notifier<T> {
  SettingNotifier(this.setting);

  final Setting<T> setting;

  @override
  T build() {
    final store = ref.watch(settingsStoreProvider);
    final sub = store.changes.where((k) => k == setting.key).listen((_) {
      state = _read(store);
    });
    ref.onDispose(sub.cancel);
    return _read(store);
  }

  T _read(SettingsStore store) {
    final raw = store.read(setting.key);
    if (raw == null) return setting.defaultValue;
    try {
      return setting.decode(raw);
    } on Object catch (e) {
      Logger('settings').warning('Bad value for ${setting.key}, using default: $e');
      return setting.defaultValue;
    }
  }

  /// Stores [value] and updates the state at once.
  Future<void> set(T value) {
    final store = ref.read(settingsStoreProvider);
    // Before the write: two quick sets never show the older value again, and
    // nothing touches the notifier after an await (it may be disposed by then).
    state = value;
    return store.write(setting.key, setting.encode(value));
  }
}

/// Declare once per setting as a top-level final:
/// `final repeatProvider = settingNotifierProvider(repeatSetting);`
NotifierProvider<SettingNotifier<T>, T> settingNotifierProvider<T>(Setting<T> setting) =>
    NotifierProvider<SettingNotifier<T>, T>(() => SettingNotifier<T>(setting));
