import 'dart:async';

import 'package:kanaru/src/platform/domain/settings_store.dart';

/// In-memory [SettingsStore] for widget tests (no file I/O).
class MemorySettingsStore implements SettingsStore {
  final Map<String, Object?> _values = {};
  final _changes = StreamController<String>.broadcast();

  @override
  Object? read(String key) => _values[key];

  @override
  Future<void> write(String key, Object? value) async {
    final changed = value == null
        ? _values.remove(key) != null
        : _values[key] != value;
    if (value != null) _values[key] = value;
    if (changed) _changes.add(key);
  }

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<void> flush() async {}
}
