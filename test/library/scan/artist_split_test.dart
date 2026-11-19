import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/artist_split.dart';
import 'package:kanaru/src/library/domain/scan/read_rules.dart';

void main() {
  List<String> split(String v) => splitArtists([v]);

  test('splits on ; and / and keeps AC/DC whole', () {
    expect(split('A; B'), ['A', 'B']);
    expect(split('A;B'), ['A', 'B']);
    expect(split('A/B'), ['A', 'B']);
    expect(split('AC/DC'), ['AC/DC']);
    expect(split('ac/dc'), ['ac/dc']);
    expect(split('AC/DC; Queen'), ['AC/DC', 'Queen']);
    expect(split('Queen / AC/DC'), ['Queen', 'AC/DC']);
    expect(split('BAC/DCE'), ['BAC', 'DCE']);
  });

  test('splits on featuring words between whitespace only', () {
    expect(split('A feat. B'), ['A', 'B']);
    expect(split('A FEAT B'), ['A', 'B']);
    expect(split('A ft B'), ['A', 'B']);
    expect(split('A ft. B'), ['A', 'B']);
    expect(split('A featuring B'), ['A', 'B']);
    expect(split('Featherweight'), ['Featherweight']);
    expect(split('Soft Machine'), ['Soft Machine']);
  });

  test('a bracketed featuring part gives its names too', () {
    expect(split('A (feat. B)'), ['A', 'B']);
    expect(split('A [ft. B]'), ['A', 'B']);
    expect(split('A (feat. B); C'), ['A', 'B', 'C']);
  });

  test('never splits on comma, ampersand or with', () {
    expect(split('A & B'), ['A & B']);
    expect(split('A, B'), ['A, B']);
    expect(split('A with B'), ['A with B']);
    expect(split('Earth, Wind & Fire'), ['Earth, Wind & Fire']);
  });

  test('repeated names are deduped by group key, first spelling kept', () {
    expect(splitArtists(['Hà Anh Tuấn', 'hà  anh tuấn']), ['Hà Anh Tuấn']);
    expect(splitArtists(['A; a', 'A feat. B']), ['A', 'B']);
    // Accents are kept: two different artists.
    expect(splitArtists(['Anh; Ánh']), ['Anh', 'Ánh']);
  });

  test('Vietnamese names keep their accents', () {
    expect(split('Đen Vâu feat. Linh Cáo'), ['Đen Vâu', 'Linh Cáo']);
  });

  test('empty parts and control characters are dropped', () {
    expect(split(' ; ;A;; '), ['A']);
    expect(split(''), isEmpty);
    expect(split('   '), isEmpty);
    expect(split('A\u0000B'), ['A B']);
    expect(splitArtists(const []), isEmpty);
  });

  test('artistsForRow pairs each name with its group key', () {
    expect(artistsForRow(['Hà Anh; Hà Anh', ' B ']), [
      (key: 'hà anh', name: 'Hà Anh'),
      (key: 'b', name: 'B'),
    ]);
  });

  group('rules', () {
    List<String> withRules(String v, List<String> sep, [List<String>? keep]) =>
        splitArtists(
          [v],
          rules: ArtistSplitRules(
            separators: sep,
            keepWhole: keep ?? defaultArtistKeepWhole,
          ),
        );

    test('the defaults object equals the explicit default lists', () {
      const corpus = [
        'Earth, Wind & Fire',
        'AC/DC',
        'AC/DC feat. Queen',
        'Featherweight',
        'Soft.Cell',
        'Defeat.X',
        'A (feat. B)',
        'A\u0000B',
        'Đen feat. Chi Pu / MIN',
        'A ft. B; C featuring D',
      ];
      final explicit = ArtistSplitRules(
        separators: defaultArtistSeparators,
        keepWhole: defaultArtistKeepWhole,
      );
      for (final v in corpus) {
        expect(
          splitArtists([v], rules: explicit),
          splitArtists([v]),
          reason: v,
        );
      }
      expect(split('Soft.Cell'), ['Soft.Cell']);
      expect(split('Defeat.X'), ['Defeat.X']);
      expect(split('Đen feat. Chi Pu / MIN'), ['Đen', 'Chi Pu', 'MIN']);
      expect(split('A\u0000B'), ['A B']);
    });

    test(
      'a symbol entry splits anywhere, a word entry only between spaces',
      () {
        expect(withRules('A,B', [',']), ['A', 'B']);
        expect(withRules('A & B', ['&']), ['A', 'B']);
        expect(withRules('A with B', ['with']), ['A', 'B']);
        expect(withRules('Without Me', ['with']), ['Without Me']);
        expect(withRules('A feat. B', ['feat', 'feat.']), ['A', 'B']);
      },
    );

    test('entries are matched literally, not as patterns', () {
      expect(withRules('A.B', ['.']), ['A', 'B']);
      expect(withRules('AxB', ['.']), ['AxB']);
      expect(withRules('A+B', ['+']), ['A', 'B']);
      expect(withRules('A|B', ['|']), ['A', 'B']);
    });

    test('no separators leave each value whole', () {
      expect(withRules('A; B / C', const []), ['A; B / C']);
    });

    test('kept names are never split by any active separator', () {
      expect(withRules('Simon & Garfunkel', ['&'], ['Simon & Garfunkel']), [
        'Simon & Garfunkel',
      ]);
      expect(
        withRules(
          'Earth, Wind & Fire; Queen',
          [',', '&', ';'],
          ['Earth, Wind & Fire'],
        ),
        ['Earth, Wind & Fire', 'Queen'],
      );
      expect(
        withRules(
          'earth, wind & fire feat. X',
          [',', '&', 'feat.'],
          ['Earth, Wind & Fire'],
        ),
        ['earth, wind & fire', 'X'],
      );
      // A word entry cannot cut a kept name either.
      expect(
        withRules('Kool and the Gang and Y', ['and'], ['Kool and the Gang']),
        ['Kool and the Gang', 'Y'],
      );
      expect(
        withRules(
          'Bob, Earth, Wind & Fire',
          [',', '&'],
          ['Earth, Wind & Fire'],
        ),
        ['Bob', 'Earth, Wind & Fire'],
      );
    });

    test('private-use characters in a tag survive, with or without kept names', () {
      expect(split('A\uE000B'), ['A\uE000B']);
      expect(split('Apple\uF8FF; B'), ['Apple\uF8FF', 'B']);
      // The placeholder of AC/DC must not collide with a character of the tag.
      expect(split('\uE000 AC/DC / \uE001'), ['\uE000 AC/DC', '\uE001']);
      expect(
        withRules(
          '\uE000 Earth, Wind & Fire, \uE001',
          [','],
          ['Earth, Wind & Fire'],
        ),
        ['\uE000 Earth, Wind & Fire', '\uE001'],
      );
    });

    test('overlapping kept names: the longer one wins in any order', () {
      for (final keep in [
        ['Wind & Fire', 'Earth, Wind & Fire'],
        ['Earth, Wind & Fire', 'Wind & Fire'],
      ]) {
        expect(withRules('Earth, Wind & Fire, Bob', [',', '&'], keep), [
          'Earth, Wind & Fire',
          'Bob',
        ]);
      }
    });
  });

  test('segments mark the separators the rules would split at', () {
    String show(ArtistSplitRules r, String t) =>
        [for (final p in r.segments(t)) p.separator ? '[${p.text}]' : p.text]
            .join();
    expect(
      show(ArtistSplitRules.defaults, 'Đen feat. Chi Pu / MIN'),
      'Đen[ feat. ]Chi Pu[ / ]MIN',
    );
    // A kept name is never marked, even if it holds a separator.
    expect(show(ArtistSplitRules.defaults, 'AC/DC / Queen'), 'AC/DC[ / ]Queen');
    expect(
      show(ArtistSplitRules(separators: const [], keepWhole: const []), 'A; B'),
      'A; B',
    );
  });
}
