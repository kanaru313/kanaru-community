import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('settings_test');
    file = File('${dir.path}/settings.json');
  });
  tearDown(() async {
    // Restore access in case a test removed it.
    for (final e in dir.listSync()) {
      if (e is File) Process.runSync('chmod', ['600', e.path]);
    }
    await dir.delete(recursive: true);
  });

  List<File> badCopies() =>
      dir.listSync().whereType<File>().where((f) => f.path.contains('.bad-')).toList();

  Future<void> expectRecovered(String content) async {
    await file.writeAsString(content);
    final store = await JsonSettingsStore.open(file);
    expect(store.read('theme'), isNull);
    expect(badCopies(), hasLength(1));
    expect(await badCopies().single.readAsString(), content);
    await store.write('a.b', 1);
    await store.flush();
    expect((await JsonSettingsStore.open(file)).read('a.b'), 1);
  }

  test('unknown key reads null', () async {
    final store = await JsonSettingsStore.open(file);
    expect(store.read('a.b'), isNull);
  });

  test('round trip after flush', () async {
    final store = await JsonSettingsStore.open(file);
    await store.write('library.tabs', ['a', 'b']);
    await store.write('playback.repeat', 2);
    await store.flush();
    final json = jsonDecode(await file.readAsString()) as Map;
    expect(json['format'], 'kanaru-settings');
    expect(json['version'], 1);
    final again = await JsonSettingsStore.open(file);
    expect(again.read('library.tabs'), ['a', 'b']);
    expect(again.read('playback.repeat'), 2);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('writing null removes the key', () async {
    final store = await JsonSettingsStore.open(file);
    await store.write('a.b', 1);
    await store.write('a.b', null);
    await store.flush();
    expect((await JsonSettingsStore.open(file)).read('a.b'), isNull);
  });

  test('writes are coalesced into one scheduled write', () async {
    final timers = <void Function()>[];
    final store = await JsonSettingsStore.open(file, timerFactory: (_, cb) {
      timers.add(cb);
      return Timer(const Duration(days: 1), () {});
    });
    await store.write('a.b', 1);
    await store.write('a.b', 2);
    expect(timers, hasLength(1));
    expect(file.existsSync(), isFalse);
    timers.single();
    await store.flush();
    final json = jsonDecode(await file.readAsString()) as Map;
    expect((json['values'] as Map)['a.b'], 2);
  });

  test('a re-entrant write from a listener works with two listeners', () async {
    final store = await JsonSettingsStore.open(file);
    final seen = <String>[];
    store.changes.listen((k) {
      if (k == 'a.b') store.write('a.c', 1);
    });
    store.changes.listen(seen.add);
    await store.write('a.b', 1);
    await Future<void>.delayed(Duration.zero);
    expect(seen, containsAll(['a.b', 'a.c']));
  });

  test('a stale temp file is removed on load', () async {
    final tmp = File('${file.path}.tmp')..writeAsStringSync('junk');
    await JsonSettingsStore.open(file);
    expect(tmp.existsSync(), isFalse);
  });

  test('version 0 is rejected', () => expectRecovered('{"format":"kanaru-settings","version":0,"values":{}}'));

  test('flush writes immediately', () async {
    final store = await JsonSettingsStore.open(file, writeDelay: const Duration(seconds: 30));
    await store.write('a.b', 1);
    await store.flush();
    expect(file.existsSync(), isTrue);
  });

  test('changes stream emits the key only when the value changed', () async {
    final store = await JsonSettingsStore.open(file);
    final seen = <String>[];
    store.changes.listen(seen.add);
    await store.write('a.b', 1);
    await store.write('a.b', 1);
    await store.write('a.c', 'x');
    await store.write('a.b', null);
    await store.flush();
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['a.b', 'a.c', 'a.b']);
  });

  test('invalid JSON is copied aside', () => expectRecovered('{nope'));
  test('a JSON array is copied aside', () => expectRecovered('[1,2]'));
  test('an old-app shaped object is copied aside',
      () => expectRecovered('{"version": 3, "theme": "dark"}'));
  test('a newer version is copied aside',
      () => expectRecovered('{"format":"kanaru-settings","version":2,"values":{"theme":"x"}}'));

  test('an unreadable file is set aside once and the store works again', () async {
    await file.writeAsString('{"format":"kanaru-settings","version":1,"values":{"theme":"x"}}');
    Process.runSync('chmod', ['000', file.path]);
    try {
      file.readAsStringSync();
      markTestSkipped('permissions not enforced (running as root)');
      return;
    } on FileSystemException {
      // Expected: the file is unreadable.
    }
    final store = await JsonSettingsStore.open(file);
    expect(store.read('theme'), isNull);
    expect(badCopies(), hasLength(1));
    await store.write('a.b', 1);
    await store.flush();
    expect((await JsonSettingsStore.open(file)).read('a.b'), 1);
    expect(badCopies(), hasLength(1));
  }, testOn: 'linux');
}
