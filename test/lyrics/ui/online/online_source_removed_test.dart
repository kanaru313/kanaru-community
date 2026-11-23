import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart' show PluginRow;
import 'package:kanaru/src/lyrics/ui/online/online_source_providers.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../../screens/plugins/support/plugin_fixtures.dart' show liveRow;

ProviderContainer _container(Stream<List<PluginRow>> rows) {
  final c = ProviderContainer(
    overrides: [installedPluginsProvider.overrideWith((ref) => rows)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<bool> _removed(ProviderContainer c, String id) async {
  c.listen(onlineSourceRemovedProvider(id), (_, _) {});
  await c.read(installedPluginsProvider.future);
  return c.read(onlineSourceRemovedProvider(id));
}

void main() {
  test('an installed lyrics plugin is not removed', () async {
    final c = _container(Stream.value([liveRow('a')]));
    expect(await _removed(c, 'a'), isFalse);
  });

  test('a plugin that is not in the list is removed', () async {
    final c = _container(Stream.value([liveRow('a')]));
    expect(await _removed(c, 'gone'), isTrue);
  });

  test('a plugin of another kind with that id does not count', () async {
    final c = _container(Stream.value([liveRow('a', kind: 'translate')]));
    expect(await _removed(c, 'a'), isTrue);
  });

  test('an origin this build does not know is still installed', () async {
    final c = _container(Stream.value([liveRow('a', origin: 'mystery')]));
    expect(await _removed(c, 'a'), isFalse);
  });

  test('nothing is removed while the list is loading', () {
    final c = _container(const Stream<List<PluginRow>>.empty());
    c.listen(onlineSourceRemovedProvider('a'), (_, _) {});
    expect(c.read(onlineSourceRemovedProvider('a')), isFalse);
  });
}
