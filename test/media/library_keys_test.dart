import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/text/text_fold.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

void main() {
  group('groupKey', () {
    test('lower, trim, collapse whitespace, keep accents', () {
      expect(groupKey('  Hà   NỘI \t'), 'hà nội');
      expect(groupKey('Hà'), isNot(groupKey('Ha')));
    });
    test('NFC: decomposed equals precomposed', () {
      expect(groupKey('Vũ'), groupKey('Vũ'));
    });
  });

  group('searchForm / sortForm', () {
    test('folds accents', () {
      expect(searchForm(' Vũ  Cát Tường '), 'vu cat tuong');
      expect(sortForm('The Đen 2'), 'the den 2');
    });
    test('reader and writer agree on Vietnamese samples', () {
      for (final s in ['Vũ', 'Đen Vâu', 'Hồ Quang Hiếu', 'Trịnh Công Sơn']) {
        expect(searchForm(searchForm(s)), searchForm(s));
      }
    });
  });

  group('albumArtistKeyFor', () {
    test('album artist, first artist, unknown', () {
      expect(albumArtistKeyFor(albumArtist: 'A', artists: ['B']), 'A');
      expect(albumArtistKeyFor(albumArtist: ' ', artists: ['B', 'C']), 'B');
      expect(albumArtistKeyFor(artists: []), '');
    });
  });

  group('songKey', () {
    test('stable across case and spacing, differs by artist', () {
      expect(
        songKey(title: 'Hà  Nội', artists: ['X']),
        songKey(title: 'hà nội', artists: [' x']),
      );
      expect(
        songKey(title: 'a', artists: ['X']),
        isNot(songKey(title: 'a', artists: ['Y'])),
      );
      expect(songKey(title: 'a', artists: []).length, 16);
    });
  });

  group('encode / decode', () {
    test('album round trip incl. empty, emoji, slash', () {
      for (final k in [
        AlbumKey('', ''),
        AlbumKey('ac/dc', 'back in black'),
        AlbumKey('🎵', 'hà nội ✨'),
        AlbumKey('a', ''),
      ]) {
        final id = k.encode();
        expect(id, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
        expect(AlbumKey.decode(id), k);
      }
    });
    test('artist round trip', () {
      final k = ArtistKey('đen vâu/💿');
      expect(ArtistKey.decode(k.encode()), k);
      expect(ArtistKey.decode(ArtistKey('').encode()), ArtistKey(''));
    });
    test('bad ids decode to null', () {
      expect(AlbumKey.decode('!!!'), isNull);
      expect(AlbumKey.decode(encodeKey('no separator')), isNull);
      expect(ArtistKey.decode('/+='), isNull);
      expect(decodeKey('_w'), isNull); // invalid UTF-8 (0xFF)
    });
  });

  group('control characters', () {
    test('become spaces', () {
      expect(groupKey('a\u0000b\u001fc\u007fd'), 'a b c d');
      expect(groupKey('x\u001f'), 'x');
    });
    test('NUL in artist round-trips through the key', () {
      final k = ArtistKey(groupKey('Foo\u0000Bar'));
      expect(ArtistKey.decode(k.encode()), k);
      final a = AlbumKey(groupKey('A\u0000B'), groupKey('T\u001f1'));
      expect(AlbumKey.decode(a.encode()), a);
    });
    test('NUL in a part is rejected', () {
      expect(() => ArtistKey('a\u0000b'), throwsA(isA<AssertionError>()));
      expect(() => AlbumKey('a', 'b\u0000c'), throwsA(isA<AssertionError>()));
    });
  });

  group('decode strictness', () {
    test('non-canonical parts and ids are rejected', () {
      expect(ArtistKey.decode(encodeKey('Upper')), isNull);
      expect(ArtistKey.decode(encodeKey(' a')), isNull);
      expect(AlbumKey.decode(encodeKey('a\u0000B')), isNull);
      expect(AlbumKey.decode('${AlbumKey('a', 'b').encode()}='), isNull);
      expect(AlbumKey.decode(encodeKey('a\u0000b\u0000c')), isNull);
    });
  });

  group('albumKeyFor', () {
    test('groups both parts, null for empty album', () {
      expect(
        albumKeyFor(album: ' Hà  Nội ', albumArtist: 'ĐEN', artists: ['x']),
        AlbumKey('đen', 'hà nội'),
      );
      expect(albumKeyFor(album: 'T', artists: [' Vũ ']), AlbumKey('vũ', 't'));
      expect(albumKeyFor(album: 'T', artists: []), AlbumKey('', 't'));
      expect(albumKeyFor(album: '  ', artists: ['x']), isNull);
      expect(albumKeyFor(artists: ['x']), isNull);
    });
    test('songKey skips blank artists', () {
      expect(
        songKey(title: 't', artists: [' ', 'X']),
        songKey(title: 't', artists: ['X']),
      );
    });
  });

  group('fixed vectors', () {
    test('groupKey / searchForm / sortForm', () {
      const cases = {
        'Đen Vâu': ['đen vâu', 'den vau'],
        'Nguyễn  Văn\tƯu': ['nguyễn văn ưu', 'nguyen van uu'],
        '東京 事変': ['東京 事変', '東京 事変'],
        'Café ÅNGSTRÖM': ['café ångström', 'cafe angstrom'],
        'Track 01': ['track 01', 'track 01'],
      };
      cases.forEach((input, want) {
        expect(groupKey(input), want[0], reason: input);
        expect(searchForm(input), want[1], reason: input);
        expect(sortForm(input), want[1], reason: input);
      });
    });
    test('songKey is a fixed 16-hex value', () {
      final k = songKey(title: 'Hà Nội', artists: ['Vũ']);
      expect(k, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(k, '952d66741d7612ab');
    });
  });

  group('writer and reader agree', () {
    test('NFD upper-case padded writer vs NFC reader', () {
      final stored = '  VU\u0303   CA\u0301T  Tu\u031Bo\u031Bng ';
      const reader = 'vũ cát tương';
      expect(groupKey(stored), groupKey(reader));
      expect(searchForm(stored), searchForm(reader));
      expect(searchForm(stored), 'vu cat tuong');
      expect(foldedContains(searchForm(stored), 'vu'), isTrue);
      expect(foldedContains(stored, 'VŨ cát'), isTrue);
    });
  });
}
