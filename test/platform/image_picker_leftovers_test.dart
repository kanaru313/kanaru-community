import 'dart:io';

import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/image_picker_leftovers.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  final now = DateTime(2026, 11, 18, 12);

  setUp(() => tmp = Directory.systemTemp.createTempSync('leftovers_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File make(String rel, {required Duration age}) {
    final f = File(p.join(tmp.path, rel))..createSync(recursive: true);
    f.setLastModifiedSync(now.subtract(age));
    return f;
  }

  test('deletes only old matching regular files', () async {
    final old = make('cover-preview-1.png', age: const Duration(hours: 2));
    final young = make('cover-preview-2.png', age: const Duration(minutes: 5));
    final other = make('notes.txt', age: const Duration(days: 9));
    final dir = Directory(p.join(tmp.path, 'cover-preview-dir'))..createSync();
    final link = Link(p.join(tmp.path, 'cover-preview-link'))
      ..createSync(old.path);

    final n = await deleteOldFiles(
      tmp,
      match: (name) => name.startsWith('cover-preview'),
      now: () => now,
    );

    expect(n, 1);
    expect(old.existsSync(), isFalse);
    expect(young.existsSync(), isTrue);
    expect(other.existsSync(), isTrue);
    expect(dir.existsSync(), isTrue);
    expect(FileSystemEntity.isLinkSync(link.path), isTrue);
  });

  test('a link to an old file is kept and its target untouched', () async {
    final target = make('elsewhere/real.png', age: const Duration(days: 3));
    final dir = Directory(p.join(tmp.path, 'sweep'))..createSync();
    Link(p.join(dir.path, 'l.png')).createSync(target.path);

    expect(await deleteOldFiles(dir, match: (_) => true, now: () => now), 0);
    expect(target.existsSync(), isTrue);
    expect(FileSystemEntity.isLinkSync(p.join(dir.path, 'l.png')), isTrue);
  });

  test('missing directory is fine', () async {
    final n = await deleteOldFiles(
      Directory(p.join(tmp.path, 'nope')),
      match: (_) => true,
    );
    expect(n, 0);
  });

  test('picker cache: old copies and emptied uuid folders go', () async {
    const oldId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';
    const newId = '4f2504e0-4f89-11d3-9a0c-0305e82c3302';
    make('$oldId/IMG_1.jpg', age: const Duration(hours: 3));
    final young = make('$newId/IMG_2.jpg', age: const Duration(minutes: 1));
    final stranger = make('other/keep.jpg', age: const Duration(days: 5));

    final n = await sweepPickerCache(tmp, now: () => now);

    expect(n, 1);
    expect(Directory(p.join(tmp.path, oldId)).existsSync(), isFalse);
    expect(young.existsSync(), isTrue);
    expect(stranger.existsSync(), isTrue);
  });

  const oldId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  test('picker cache: uuid-named symlink to outside folder is kept', () async {
    final outside = make('outside/old.jpg', age: const Duration(days: 4));
    final link = Link(p.join(tmp.path, oldId))
      ..createSync(p.dirname(outside.path));

    expect(await sweepPickerCache(tmp, now: () => now), 0);
    expect(outside.existsSync(), isTrue);
    expect(FileSystemEntity.isLinkSync(link.path), isTrue);
  });

  test('picker cache: uuid-named regular file is kept', () async {
    final f = make(oldId, age: const Duration(days: 4));
    expect(await sweepPickerCache(tmp, now: () => now), 0);
    expect(f.existsSync(), isTrue);
  });

  group('cleanImagePickerLeftovers', () {
    test('deletes lost pick file and sweeps the cache', () async {
      final lost = make('lost/pick.jpg', age: const Duration(minutes: 1));
      final cache = Directory(p.join(tmp.path, 'cache'))..createSync();
      final oldCopy = File(p.join(cache.path, oldId, 'a.jpg'))
        ..createSync(recursive: true);
      oldCopy.setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final young = File(
        p.join(cache.path, '4f2504e0-4f89-11d3-9a0c-0305e82c3302', 'b.jpg'),
      )..createSync(recursive: true);

      await cleanImagePickerLeftovers(
        platform: _FakeAndroid(LostDataResponse(files: [XFile(lost.path)])),
        cacheDir: cache,
      );

      expect(lost.existsSync(), isFalse);
      expect(oldCopy.existsSync(), isFalse);
      expect(Directory(p.join(cache.path, oldId)).existsSync(), isFalse);
      expect(young.existsSync(), isTrue);
    });

    test('no lost pick: only sweeps, no throw', () async {
      final cache = Directory(p.join(tmp.path, 'cache'))..createSync();
      await cleanImagePickerLeftovers(
        platform: _FakeAndroid(LostDataResponse.empty()),
        cacheDir: cache,
      );
      expect(cache.existsSync(), isTrue);
    });

    test('getLostData throwing does not throw', () async {
      await cleanImagePickerLeftovers(
        platform: _FakeAndroid(null),
        cacheDir: tmp,
      );
    });

    test('non-Android platform is a no-op', () async {
      final f = make('keep/x.jpg', age: const Duration(days: 9));
      await cleanImagePickerLeftovers(platform: _FakeOther(), cacheDir: tmp);
      expect(f.existsSync(), isTrue);
    });
  });
}

class _FakeAndroid extends ImagePickerAndroid {
  _FakeAndroid(this.response);
  final LostDataResponse? response; // null = throw

  @override
  Future<LostDataResponse> getLostData() async {
    if (response == null) throw StateError('boom');
    return response!;
  }
}

class _FakeOther extends ImagePickerPlatform {}
