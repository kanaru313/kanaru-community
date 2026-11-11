import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/song_info_page.dart';

import 'menu_fixtures.dart';

Map<String, String?> _rows(MenuPageSpec page) => {
  for (final i in page.groups.single) i.title: i.subtitle,
};

void main() {
  test('lists the file facts', () {
    final page = songInfoPage(songFile, env())!;
    expect(page.title, 'Song info');
    expect(_rows(page), {
      'Format': 'FLAC',
      'Bitrate': '900 kbps',
      'Sample rate': '44.1 kHz',
      'Bit depth': '16-bit',
      'Size': '28.6 MB',
      'File': '/home/u/Music/Blue/1.flac',
      'Plays': '4',
    });
  });

  test('the path can be copied', () {
    final page = songInfoPage(songFile, env())!;
    final path = page.groups.single.firstWhere((i) => i.title == 'File');
    expect(
      path.trailing!.action,
      const MenuAction.copy('/home/u/Music/Blue/1.flac'),
    );
    expect(path.trailing!.tooltip, 'Copy path');
  });

  test(
    'missing facts read "Unknown"; a whole row of 48 kHz has no decimal',
    () {
      const sparse = SongInfo(
        format: null,
        bitrate: null,
        sampleRate: 48000,
        bitDepth: null,
        sizeBytes: null,
        path: null,
        playCount: 0,
      );
      final page = songInfoPage(sparse, env())!;
      expect(_rows(page), {
        'Format': 'Unknown',
        'Bitrate': 'Unknown',
        'Sample rate': '48 kHz',
        'Bit depth': 'Unknown',
        'Size': 'Unknown',
        'File': 'Unknown',
        'Plays': '0',
      });
      expect(
        page.groups.single.firstWhere((i) => i.title == 'File').trailing,
        isNull,
      );
    },
  );

  test('no file facts, no page', () {
    expect(songInfoPage(null, env()), isNull);
  });

  test('sizes use binary units', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2.0 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
  });

  test('numbers follow the language: a comma in Vietnamese', () {
    expect(formatBytes(3584 * 1024, 'vi'), '3,5 MB');
    expect(formatBytes(3584 * 1024, 'en'), '3.5 MB');
  });
}
