import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/data/contract/card_reader.dart';
import 'package:kanaru/src/online/domain/contract/online_card.dart';

Map<String, Object?> card([Map<String, Object?> over = const {}]) => {
  'id': 'abc',
  'title': 'Shape of You',
  ...over,
};

void main() {
  test('reads every field', () {
    final (c, why) = readCard({
      'kind': 'album',
      'id': 'a/b 100% ä',
      'title': 'Divide',
      'subtitle': 'Deluxe',
      'artist': 'Ed Sheeran',
      'artists': [
        {'id': '7', 'title': 'Ed Sheeran'},
        {'id': 'https://x.y/a', 'title': 'Guest'},
        {'title': ''},
      ],
      'album': 'Divide',
      'albums': [
        {'id': 'al1', 'title': 'Other'},
      ],
      'durationMs': 233000,
      'artworkUrl': 'https://img.example.com/a.jpg',
      'webUrl': 'https://example.com/t/1',
    });
    expect(why, isNull);
    expect(c!.kind, OnlineCardKind.album);
    expect(c.id, 'a/b 100% ä');
    expect(c.subtitle, 'Deluxe');
    expect(c.artist, 'Ed Sheeran');
    expect(c.artists, const [
      CardRef(id: '7', name: 'Ed Sheeran'),
      CardRef(name: 'Guest'),
    ]);
    expect(c.album, const CardRef(id: 'al1', name: 'Divide'));
    expect(c.duration, const Duration(milliseconds: 233000));
    expect(c.artworkUrl, 'https://img.example.com/a.jpg');
    expect(c.webUrl, 'https://example.com/t/1');
    expect(c.toString(), 'OnlineCard(album, a/b 100% ä)');
  });

  test('album name falls back to albums[0].title', () {
    final (c, _) = readCard(
      card({
        'albums': [
          {'id': 'x', 'title': 'From list'},
        ],
      }),
    );
    expect(c!.album, const CardRef(id: 'x', name: 'From list'));
    expect(readCard(card()).$1!.album, isNull);
  });

  test('missing kind is a track; unknown kinds are dropped', () {
    expect(readCard(card()).$1!.kind, OnlineCardKind.track);
    expect(readCard(card({'kind': 'genre'})).$2, 'unknown kind');
    expect(readCard(card({'kind': 5})).$2, 'unknown kind');
    expect(readCard('x').$1, isNull);
  });

  group('id', () {
    for (final id in [
      '',
      'a' * 201,
      'a\u0000b',
      'a\u007fb',
      '.',
      '..',
      'https://x.y/a',
      '//x.y',
      'file:///etc/passwd',
    ]) {
      test('drops ${id.length > 20 ? 'long id' : id.codeUnits}', () {
        final (c, why) = readCard(card({'id': id}));
        expect(c, isNull);
        expect(why, isNotNull);
      });
    }
    test(
      'drops a non-string id',
      () => expect(readCard(card({'id': 7})).$1, isNull),
    );
    test('keeps plain odd ids untouched', () {
      for (final id in ['a/b', '100%', 'with space ', 'ä日本', 'a' * 200]) {
        expect(readCard(card({'id': id})).$1!.id, id);
      }
    });
  });

  test('title is cleaned and bounded', () {
    final (c, _) = readCard(card({'title': '\u202EHel\u200Blo\u202C'}));
    expect(c!.title, 'Hello');
    expect(readCard(card({'title': 'a' * 301})).$1, isNull);
    expect(readCard(card({'title': 'a' * 300})).$1, isNotNull);
    expect(readCard(card({'title': '\u200B '})).$1, isNull);
  });

  test('over-long optional text reads as absent, card kept', () {
    final (c, _) = readCard(card({'artist': 'a' * 201, 'subtitle': 'b' * 301}));
    expect(c!.artist, isNull);
    expect(c.subtitle, isNull);
  });

  test('duration', () {
    for (final v in [0, -5, 86400001, 1.5, 'x', null]) {
      expect(
        readCard(card({'durationMs': v})).$1!.duration,
        isNull,
        reason: '$v',
      );
    }
    expect(
      readCard(card({'durationMs': 86400000})).$1!.duration,
      const Duration(hours: 24),
    );
    expect(
      readCard(card({'durationMs': 5.0})).$1!.duration,
      const Duration(milliseconds: 5),
    );
  });

  test('links', () {
    for (final url in [
      'http://h.example/a',
      'https://u:p@h.example/',
      'https://h.example:443/a',
      'https://h.example:8443/a',
      'https://h.example/${'a' * 2000}',
      'https:///a',
      7,
    ]) {
      final (c, _) = readCard(card({'artworkUrl': url, 'webUrl': url}));
      expect(c!.artworkUrl, isNull, reason: '$url');
      expect(c.webUrl, isNull, reason: '$url');
    }
  });

  test('artists are capped at 10', () {
    final (c, _) = readCard(
      card({
        'artists': [
          for (var i = 0; i < 15; i++) {'id': '$i', 'title': 'A$i'},
        ],
      }),
    );
    expect(c!.artists, hasLength(10));
  });
}
