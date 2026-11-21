import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/config_writes.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';

import 'install_test_support.dart';

class _Failing extends PluginConfigStore {
  _Failing(InstallHarness h) : super(h.db, h.rows);

  @override
  Future<ConfigWrite> setValue(String installId, String key, Object? value) =>
      throw StateError('db down');
}

void main() {
  test('a database failure is `failed`, not "unknown key"', () async {
    final h = InstallHarness();
    addTearDown(h.dispose);
    final writes = PluginConfigWrites(queue: h.queue, store: _Failing(h));
    expect(await writes.setValue('plugin-x', 'k', 'v'), ConfigWrite.failed);
    // The queue goes on.
    expect(
      await h.actions.configWrites.setValue('plugin-x', 'k', 'v'),
      ConfigWrite.unknownKey,
    );
  });
}
