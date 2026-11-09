import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/ids/ulid.dart';
import 'package:kanaru/src/platform/data/file_device_id.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('device_id_test'));
  tearDown(() => dir.delete(recursive: true));

  test('creates a ULID on first load, in its own file', () async {
    final file = File('${dir.path}/sub/device_id');
    final id = await FileDeviceId(file).load();
    expect(isUlid(id), isTrue);
    expect(await file.readAsString(), id);
    expect(dir.listSync(recursive: true).whereType<File>().map((f) => f.path),
        isNot(contains(endsWith('.db'))));
  });

  test('reuses the stored id', () async {
    final file = File('${dir.path}/device_id');
    final first = await FileDeviceId(file).load();
    expect(await FileDeviceId(file).load(), first);
  });

  test('tolerates trailing newline', () async {
    final file = File('${dir.path}/device_id');
    final id = await FileDeviceId(file).load();
    await file.writeAsString('$id\n');
    expect(await FileDeviceId(file).load(), id);
  });

  test('replaces invalid content', () async {
    final file = File('${dir.path}/device_id');
    await file.writeAsString('not-a-ulid');
    final id = await FileDeviceId(file).load();
    expect(isUlid(id), isTrue);
    expect(await file.readAsString(), id);
  });
}
