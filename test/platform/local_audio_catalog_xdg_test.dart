import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/local_files/xdg_music_folder.dart';

void main() {
  test('a relative XDG_CONFIG_HOME is ignored', () async {
    final result = await readXdgMusicDirectory({
      'HOME': '/nonexistent-home-for-test',
      'XDG_CONFIG_HOME': 'relative/config',
    });
    expect(result, isNull);
  });

  const env = {'HOME': '/home/u'};

  String? resolve(String? content, {Set<String> existing = const {}}) =>
      xdgMusicDirectory(env, content, isDirectory: existing.contains);

  test('reads a \$HOME-relative value', () {
    expect(
      resolve(
        'XDG_MUSIC_DIR="\$HOME/Musik"\n',
        existing: {'/home/u/Musik', '/home/u/Music'},
      ),
      '/home/u/Musik',
    );
  });

  test('reads an absolute value and normalises it', () {
    expect(
      resolve(
        'XDG_MUSIC_DIR="/data//songs/./"\n',
        existing: {'/data/songs'},
      ),
      '/data/songs',
    );
  });

  test('the last assignment wins and comments are ignored', () {
    expect(
      resolve(
        '# XDG_MUSIC_DIR="\$HOME/Old"\n'
        'XDG_MUSIC_DIR="\$HOME/A"\nXDG_MUSIC_DIR="\$HOME/B"\n',
        existing: {'/home/u/A', '/home/u/B'},
      ),
      '/home/u/B',
    );
  });

  test('rejected values fall back to ~/Music', () {
    const existing = {'/home/u/Music', '/', '/home/u', '/home', '/x'};
    const rejected = [
      'XDG_MUSIC_DIR="\$HOME"',
      'XDG_MUSIC_DIR="\$HOME/"',
      'XDG_MUSIC_DIR="/"',
      'XDG_MUSIC_DIR="/home"',
      'XDG_MUSIC_DIR="/x/../home/u"',
      'XDG_MUSIC_DIR="relative/dir"',
      'XDG_MUSIC_DIR=""',
      'XDG_MUSIC_DIR="\$HOME/../x"',
    ];
    for (final line in rejected) {
      expect(resolve('$line\n', existing: existing), '/home/u/Music', reason: line);
    }
  });

  test('a configured folder that does not exist falls back', () {
    expect(
      resolve('XDG_MUSIC_DIR="\$HOME/Gone"\n', existing: {'/home/u/Music'}),
      '/home/u/Music',
    );
  });

  test('no folder at all gives null', () {
    expect(resolve(null), isNull);
    expect(xdgMusicDirectory({'HOME': 'rel'}, null, isDirectory: (_) => true), isNull);
    expect(xdgMusicDirectory(const {}, null, isDirectory: (_) => true), isNull);
  });
}
