import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/domain/setting.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import 'dart:io';

const _repeat = Setting<int>(
  'playback.repeat',
  0,
  decode: _decode,
  encode: _encode,
);
int _decode(Object? j) => j is int ? j : throw const FormatException('int expected');
int _castDecode(Object? j) => j as int;
Object? _encode(int v) => v;
const _cast = Setting<int>('playback.cast', 7, decode: _castDecode, encode: _encode);
final _castProvider = settingNotifierProvider(_cast);
final _repeatProvider = settingNotifierProvider(_repeat);

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('setting_test'));
  tearDown(() => dir.delete(recursive: true));

  Future<ProviderContainer> container() async {
    final store = await JsonSettingsStore.open(File('${dir.path}/settings.json'));
    final c = ProviderContainer(overrides: [settingsStoreProvider.overrideWithValue(store)]);
    addTearDown(store.flush);
    addTearDown(c.dispose);
    return c;
  }

  test('default, set, and rebuild on change', () async {
    final c = await container();
    expect(c.read(_repeatProvider), 0);
    await c.read(_repeatProvider.notifier).set(2);
    expect(c.read(_repeatProvider), 2);
    expect(c.read(settingsStoreProvider).read('playback.repeat'), 2);
  });

  test('an undecodable stored value falls back to the default', () async {
    final c = await container();
    await c.read(settingsStoreProvider).write('playback.repeat', 'oops');
    expect(c.read(_repeatProvider), 0);
  });

  test('a decoder that throws a TypeError falls back to the default', () async {
    final c = await container();
    await c.read(settingsStoreProvider).write('playback.cast', 'oops');
    expect(c.read(_castProvider), 7);
  });

  test('set(A); set(B) ends in B and never shows A after B', () async {
    final c = await container();
    final seen = <int>[];
    c.listen(_repeatProvider, (_, v) => seen.add(v));
    final n = c.read(_repeatProvider.notifier);
    final a = n.set(1);
    final b = n.set(2);
    await Future.wait([a, b]);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(_repeatProvider), 2);
    expect(seen, [1, 2]);
  });
}
