import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';

import '../support/memory_settings_store.dart';

const _chat = PanelSurface(id: 'chat', order: 0, body: _body);
Widget _body(BuildContext _) => const SizedBox();

ExtensionRegistry _registry(PanelSurface? chat) {
  final r = ExtensionRegistry();
  if (chat != null) r.addPanelSurface(chat);
  return r;
}

ProviderContainer _container(MemorySettingsStore store, {PanelSurface? chat}) {
  final c = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(store),
      extensionRegistryProvider.overrideWithValue(_registry(chat)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('starts closed and toggles one panel at a time', () {
    final c = _container(MemorySettingsStore(), chat: _chat);
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
    final first = _container(store, chat: _chat);
    first.read(rightPanelProvider.notifier).show(RightPanelKind.queue);
    expect(store.read('shell.right_panel'), 'queue');

    // A new container stands for the next launch.
    expect(
      _container(store, chat: _chat).read(rightPanelProvider),
      RightPanelKind.queue,
    );

    first.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
    expect(
      _container(store, chat: _chat).read(rightPanelProvider),
      RightPanelKind.chat,
    );
    first.read(rightPanelProvider.notifier).close();
    expect(
      _container(store, chat: _chat).read(rightPanelProvider),
      RightPanelKind.closed,
    );
  });

  test('chat last time but no chat in this build: starts closed', () async {
    final store = MemorySettingsStore();
    await store.write('shell.right_panel', 'chat');
    final c = _container(store);
    expect(c.read(rightPanelProvider), RightPanelKind.closed);
    // And the chat cannot be opened either.
    c.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
    expect(c.read(rightPanelProvider), RightPanelKind.closed);
  });

  test('a bad stored value reads as closed', () async {
    final store = MemorySettingsStore();
    await store.write('shell.right_panel', 'sideways');
    expect(_container(store).read(rightPanelProvider), RightPanelKind.closed);
  });
}
