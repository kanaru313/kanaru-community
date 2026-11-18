import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/settings_save_status.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/platform/state/settings_save_status_provider.dart';

import '../support/memory_settings_store.dart';

/// In-memory store that also reports its save status.
class _ReportingStore extends MemorySettingsStore
    implements SettingsSaveStatus {
  final _controller = StreamController<bool>.broadcast(sync: true);
  bool _failing = false;

  @override
  Stream<bool> get saveFailing => _controller.stream;

  @override
  bool get isFailing => _failing;

  void set(bool value) {
    _failing = value;
    _controller.add(value);
  }
}

ProviderContainer _container(MemorySettingsStore store) {
  final c = ProviderContainer(
    overrides: [settingsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('a store without the interface is never failing', () async {
    final c = _container(MemorySettingsStore());
    c.listen(settingsSaveFailingProvider, (_, _) {});
    expect(await c.read(settingsSaveFailingProvider.future), isFalse);
  });

  test('follows a failing store and its recovery', () async {
    final store = _ReportingStore();
    final c = _container(store);
    final seen = <bool>[];
    c.listen(settingsSaveFailingProvider, (_, next) {
      if (next.hasValue) seen.add(next.requireValue);
    });
    await Future<void>.delayed(Duration.zero);
    store.set(true);
    await Future<void>.delayed(Duration.zero);
    store.set(false);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [false, true, false]);
  });

  test('starts with true when the store is already failing', () async {
    final store = _ReportingStore().._failing = true;
    final c = _container(store);
    c.listen(settingsSaveFailingProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(settingsSaveFailingProvider).requireValue, isTrue);
  });
}
