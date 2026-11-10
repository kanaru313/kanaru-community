import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/android_storage_volumes.dart';
import 'package:kanaru/src/platform/data/linux_storage_volumes.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

void main() {
  group('Android', () {
    test('strips the app-specific suffix', () {
      expect(
        AndroidStorageVolumes.rootFromAppDir(
          '/storage/emulated/0/Android/data/io.github.kanaru313.kanaru/files',
        ),
        '/storage/emulated/0',
      );
      expect(
        AndroidStorageVolumes.rootFromAppDir(
          '/storage/1A2B-3C4D/Android/data/io.github.kanaru313.kanaru/files',
        ),
        '/storage/1A2B-3C4D',
      );
      expect(
        AndroidStorageVolumes.rootFromAppDir('/storage/emulated/0/Music'),
        isNull,
      );
      expect(
        AndroidStorageVolumes.rootFromAppDir('/Android/data/x/files'),
        isNull,
      );
    });

    test('list: internal and SD card, sorted and de-duplicated', () async {
      final v = AndroidStorageVolumes(
        externalDirs: () async => [
          Directory('/storage/1A2B-3C4D/Android/data/p/files'),
          Directory('/storage/emulated/0/Android/data/p/files'),
          Directory('/storage/emulated/0/Android/data/p/cache'),
        ],
      );
      expect(await v.list(), const [
        StorageVolume(
          root: '/storage/1A2B-3C4D',
          kind: StorageVolumeKind.sdCard,
        ),
        StorageVolume(
          root: '/storage/emulated/0',
          kind: StorageVolumeKind.internal,
        ),
      ]);
      expect(
        v.volumeOf('/storage/1A2B-3C4D/Music/a.mp3').kind,
        StorageVolumeKind.sdCard,
      );
      expect(
        v.volumeOf('/storage/emulated/0/Music').kind,
        StorageVolumeKind.internal,
      );
      expect(v.volumeOf('/storage/emulated/01/Music'), otherVolume);
      expect(v.volumeOf('/data/x'), otherVolume);
    });

    test('a failed platform call still knows the internal volume', () async {
      final v = AndroidStorageVolumes(externalDirs: () async => null);
      expect(
        v.volumeOf('/storage/emulated/0/Music').kind,
        StorageVolumeKind.internal,
      );
      expect((await v.list()).single.root, '/storage/emulated/0');
    });
  });

  group('Linux', () {
    test('HOME is the home volume; other paths are other', () async {
      final v = LinuxStorageVolumes(environment: {'HOME': '/home/me'});
      expect(await v.list(), const [
        StorageVolume(root: '/home/me', kind: StorageVolumeKind.home),
      ]);
      expect(v.volumeOf('/home/me/Music').kind, StorageVolumeKind.home);
      expect(v.volumeOf('/home/me').kind, StorageVolumeKind.home);
      expect(v.volumeOf('/home/meow/Music'), otherVolume);
      expect(v.volumeOf('/mnt/usb/x'), otherVolume);
    });

    test('no usable HOME gives no volumes', () async {
      expect(await LinuxStorageVolumes(environment: {}).list(), isEmpty);
      expect(
        await LinuxStorageVolumes(environment: {'HOME': 'rel'}).list(),
        isEmpty,
      );
    });
  });

  test('the longest root wins', () {
    const outer = StorageVolume(
      root: '/storage',
      kind: StorageVolumeKind.other,
    );
    const inner = StorageVolume(
      root: '/storage/ABCD-0000',
      kind: StorageVolumeKind.sdCard,
    );
    expect(volumeForPath([outer, inner], '/storage/ABCD-0000/x'), inner);
    expect(volumeForPath([inner, outer], '/storage/ABCD-0000/x'), inner);
  });
}
