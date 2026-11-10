import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/scan/folder_display_path.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

const _labels = VolumeLabels(
  internal: 'Internal storage',
  sdCard: 'SD card',
  usb: 'USB drive',
);

const _internal = StorageVolume(
  root: '/storage/emulated/0',
  kind: StorageVolumeKind.internal,
);
const _sd = StorageVolume(
  root: '/storage/1234-ABCD',
  kind: StorageVolumeKind.sdCard,
);
const _usb = StorageVolume(root: '/media/usb', kind: StorageVolumeKind.usb);
const _home = StorageVolume(root: '/home/u', kind: StorageVolumeKind.home);

void main() {
  test('internal storage: label, then the folders', () {
    expect(
      folderDisplayPath('/storage/emulated/0/Music/Rock', _internal, _labels),
      'Internal storage › Music › Rock',
    );
    expect(
      folderDisplayPath('/storage/emulated/0/Music', _internal, _labels),
      'Internal storage › Music',
    );
    expect(
      folderDisplayPath('/storage/emulated/0', _internal, _labels),
      'Internal storage',
    );
  });

  test('SD card and USB drive use their own label', () {
    expect(
      folderDisplayPath('/storage/1234-ABCD/Music', _sd, _labels),
      'SD card › Music',
    );
    expect(
      folderDisplayPath('/media/usb/Songs/a', _usb, _labels),
      'USB drive › Songs › a',
    );
  });

  test('below the home folder it starts with a tilde', () {
    expect(folderDisplayPath('/home/u/Music', _home, _labels), '~/Music');
    expect(
      folderDisplayPath('/home/u/Music/Live/2020', _home, _labels),
      '~/Music/Live/2020',
    );
    expect(folderDisplayPath('/home/u', _home, _labels), '~');
  });

  test('any other place is shown as it is', () {
    expect(
      folderDisplayPath('/mnt/nas/music', otherVolume, _labels),
      '/mnt/nas/music',
    );
    expect(
      folderDisplayPath('/var/home/u/Music', _home, _labels),
      '/var/home/u/Music',
    );
    expect(folderDisplayPath('/home/user2/x', _home, _labels), '/home/user2/x');
  });

  test('a volume root with a trailing slash still matches', () {
    const withSlash = StorageVolume(
      root: '/home/u/',
      kind: StorageVolumeKind.home,
    );
    expect(folderDisplayPath('/home/u/Music', withSlash, _labels), '~/Music');
  });
}
