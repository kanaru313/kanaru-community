import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/native_cover_import.dart';
import 'package:kanaru/src/library/state/covers/cover_leftovers_sweep.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('kanaru_sweep_'));
  tearDown(() => dir.deleteSync(recursive: true));

  File make(String name, {Duration age = Duration.zero}) {
    final f = File('${dir.path}/$name')..writeAsBytesSync([1]);
    f.setLastModifiedSync(DateTime.now().subtract(age));
    return f;
  }

  test('deletes old preview files only, runs the picker cleanup', () async {
    final old = make(
      '${coverPreviewPrefix}a.jpg',
      age: const Duration(hours: 2),
    );
    final young = make('${coverPreviewPrefix}b.jpg');
    final other = make('notes.txt', age: const Duration(hours: 2));
    var picker = 0;

    await sweepCoverLeftovers(
      previewDir: dir,
      cleanPicker: () async => picker++,
    );

    expect(picker, 1);
    expect(old.existsSync(), isFalse);
    expect(young.existsSync(), isTrue, reason: 'an open dialog may use it');
    expect(other.existsSync(), isTrue, reason: 'not ours');
  });

  test('a missing folder and a failing picker cleanup do not throw', () async {
    await sweepCoverLeftovers(
      previewDir: Directory('${dir.path}/none'),
      cleanPicker: () async => throw StateError('boom'),
    );
  });
}
