import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/store/plugin_storage_store.dart';

import '../run/support/runner_support.dart';
import 'install_test_support.dart';

void main() {
  late InstallHarness h;
  late RunnerHarness r;
  late PluginStorageStore store;

  setUp(() async {
    h = InstallHarness();
    r = RunnerHarness(h);
    store = h.storage;
    await r.install();
  });

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  Future<int> updatedAt() async => (await h.rows.byId(demoPluginId))!.updatedAt;

  Future<bool> write(String json, {int rev = 0, int? at}) async =>
      store.writeBack(
        demoPluginId,
        json,
        expectedRev: rev,
        expectedUpdatedAt: at ?? await updatedAt(),
      );

  test('a fresh plugin has an empty storage at revision 0', () async {
    final stored = await store.read(demoPluginId);
    expect(stored.json, '');
    expect(stored.rev, 0);
  });

  test('an unknown plugin reads as empty', () async {
    final stored = await store.read('nobody:none');
    expect((stored.json, stored.rev), ('', 0));
  });

  test('a guarded write saves while nothing changed', () async {
    expect(await write('{"token":"abc"}'), isTrue);
    final stored = await store.read(demoPluginId);
    expect(stored.json, '{"token":"abc"}');
    expect(stored.rev, 0, reason: 'only a clear changes the revision');
  });

  test('the last of two writes at the same revision wins', () async {
    expect(await write('{"a":"1"}'), isTrue);
    expect(await write('{"a":"2"}'), isTrue);
    expect((await store.read(demoPluginId)).json, '{"a":"2"}');
  });

  test('a write after remove changes nothing', () async {
    final at = await updatedAt();
    await h.actions.remover.remove(demoPluginId);
    expect(await write('{"a":"1"}', at: at), isFalse);
    expect((await store.read(demoPluginId)).json, '');
  });

  test('a write that began before an update is refused', () async {
    final before = await updatedAt();
    await h.db.customStatement(
      'UPDATE plugins SET updated_at = updated_at + 1 WHERE install_id = ?',
      [demoPluginId],
    );
    expect(await write('{"a":"1"}', at: before), isFalse);
    expect((await store.read(demoPluginId)).json, '');
  });

  test(
    'clear empties the storage and refuses writes at the old revision',
    () async {
      await write('{"a":"1"}');
      await store.clear(demoPluginId);

      final stored = await store.read(demoPluginId);
      expect(stored.json, '');
      expect(stored.rev, 1);
      expect(await write('{"a":"old"}', rev: 0), isFalse);
      expect(await write('{"a":"new"}', rev: 1), isTrue);
      expect((await store.read(demoPluginId)).json, '{"a":"new"}');
    },
  );

  test('clear of an unknown plugin does nothing', () async {
    await store.clear('nobody:none');
    expect((await store.read('nobody:none')).rev, 0);
  });

  test(
    'the storage survives a config write and is gone with the plugin',
    () async {
      await write('{"a":"1"}');
      await h.actions.configWrites.setValue(demoPluginId, 'region', 'vn');
      expect((await store.read(demoPluginId)).json, '{"a":"1"}');

      await h.actions.remover.remove(demoPluginId);
      expect((await store.read(demoPluginId)).json, '');
    },
  );

  group('size', () {
    test('counts UTF-8 bytes of keys and values', () {
      expect(storageSizeBytes('{"ab":"cd"}'), 4);
      // 'é' is 2 bytes, the Vietnamese 'ệ' is 3.
      expect(storageSizeBytes('{"é":"ệ"}'), 5);
    });

    test('is 0 for empty, unreadable or non-object text', () {
      expect(storageSizeBytes(''), 0);
      expect(storageSizeBytes('{oops'), 0);
      expect(storageSizeBytes('[1]'), 0);
    });

    test('the store measures what is saved', () async {
      await write('{"k":"ệ"}');
      expect(await store.sizeBytes(demoPluginId), 4);
    });
  });
}
