import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';

import '../support/memory_settings_store.dart';

ProviderContainer _container(MemorySettingsStore store) {
  final c = ProviderContainer(
    overrides: [settingsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('starts closed and toggles one panel at a time', () {
    final c = _container(MemorySettingsStore());
    final panel = c.read(rightPanelProvider.notifier);
    expect(c.read(rightPanelProvider), RightPanelKind.closed);
    panel.toggle(RightPanelKind.queue);
    expect(c.read(rightPanelProvider), RightPanelKind.queue);
    panel.toggle(RightPanelKind.chat);
    expect(c.read(rightPanelProvider), RightPanelKind.chat);
    panel.toggle(RightPanelKind.chat);
    expect(c.read(rightPanelProvider), RightPanelKind.closed);
  });

  test('every change is stored and restored by the next launch', () async {
    final store = MemorySettingsStore();
    final first = _container(store);
    first.read(rightPanelProvider.notifier).show(RightPanelKind.queue);
    expect(store.read('shell.right_panel'), 'queue');

    // A new container stands for the next launch.
    expect(_container(store).read(rightPanelProvider), RightPanelKind.queue);

    first.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
    expect(_container(store).read(rightPanelProvider), RightPanelKind.chat);
    first.read(rightPanelProvider.notifier).close();
    expect(_container(store).read(rightPanelProvider), RightPanelKind.closed);
  });

  test('chat last time: restored open on the chat', () async {
    final store = MemorySettingsStore();
    await store.write('shell.right_panel', 'chat');
    final c = _container(store);
    expect(c.read(rightPanelProvider), RightPanelKind.chat);
  });

  test('a bad stored value reads as closed', () async {
    final store = MemorySettingsStore();
    await store.write('shell.right_panel', 'sideways');
    expect(_container(store).read(rightPanelProvider), RightPanelKind.closed);
  });
}
