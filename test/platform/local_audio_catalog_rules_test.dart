import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';

void main() {
  test('audio extensions match in any case', () {
    for (final ext in audioExtensions) {
      expect(isAudioPath('/m/a.$ext'), isTrue, reason: ext);
      expect(isAudioPath('/m/A.${ext.toUpperCase()}'), isTrue, reason: ext);
    }
    expect(isAudioPath('/m/a.txt'), isFalse);
    expect(isAudioPath('/m/a'), isFalse);
    expect(isAudioPath('/m.mp3/a'), isFalse);
    expect(isAudioPath('/m/a.mp3.bak'), isFalse);
  });

  test('lyrics sidecars are .lrc in any case', () {
    expect(isLyricsSidecarPath('/m/a.lrc'), isTrue);
    expect(isLyricsSidecarPath('/m/a.LRC'), isTrue);
    expect(isLyricsSidecarPath('/m/a.lrc.txt'), isFalse);
    expect(isLyricsSidecarPath('/m/lrc'), isFalse);
  });

  test('every junk folder name is skipped', () {
    const junk = [
      'lost+found', '@eaDir', '.Trash', '.Trash-1000', '.Trashes', //
      r'$RECYCLE.BIN', r'$Recycle.Bin', '.snapshot', '.snapshots', '.zfs',
      '.stversions', '#recycle', '@Recycle', '#snapshot', '.@__thumb',
      '.AppleDouble',
    ];
    for (final name in junk) {
      expect(isSkippedFolderName(name), isTrue, reason: name);
    }
  });

  test('any dot-folder is skipped, ordinary names are not', () {
    expect(isSkippedFolderName('.cache'), isTrue);
    expect(isSkippedFolderName('.hidden album'), isTrue);
    for (final name in ['Music', 'Live', 'A B', 'Trash', 'snapshot']) {
      expect(isSkippedFolderName(name), isFalse, reason: name);
    }
  });
}
