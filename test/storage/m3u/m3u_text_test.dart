import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_text.dart';

void main() {
  group('m3uPlaylistName', () {
    test('drops .m3u and .m3u8 in any case', () {
      for (final f in ['Mix.m3u', 'Mix.M3U8', 'Mix.m3U', 'Mix.m3u8']) {
        expect(m3uPlaylistName(f), 'Mix');
      }
    });

    test('drops only one extension', () {
      expect(m3uPlaylistName('a.M3U8.m3u'), 'a.M3U8');
    });

    test('keeps a name without extension and an inner dot', () {
      expect(m3uPlaylistName('Road.trip'), 'Road.trip');
    });

    test('control and bidi characters become spaces, then trimmed', () {
      expect(m3uPlaylistName('\u202Ea\tb\n.m3u'), 'a b');
    });

    test('cut to 100 graphemes without splitting an emoji', () {
      final name = '${'a' * 99}👨‍👩‍👧‍👦tail.m3u';
      final out = m3uPlaylistName(name);
      expect(out.characters.length, 100);
      expect(out.characters.last, '👨‍👩‍👧‍👦');
    });

    test('empty when nothing is left', () {
      expect(m3uPlaylistName('.m3u'), '');
      expect(m3uPlaylistName('  \u202E .m3u8'), '');
    });
  });

  test('C1 controls and direction marks in a file name become spaces', () {
    expect(m3uPlaylistName('a\u0085b\u200Fc.m3u'), 'a b c');
  });
}
