import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/candidate_reader.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_candidate.dart';

SearchRead _search(Object? data) =>
    readSearchOutput(jsonEncode(data), providerId: 'p1');

Matcher get _badOutput => throwsA(isA<PluginOutputException>());

void main() {
  group('search output', () {
    test('a full item becomes a candidate of the provider', () {
      final out = _search([
        {
          'id': 'abc',
          'title': 'Song',
          'artist': 'Artist',
          'album': 'Alb',
          'durationMs': 200500,
        },
      ]);
      final c = out.candidates.single;
      expect(
        (c.providerId, c.remoteId, c.title, c.artist, c.album, c.duration),
        (
          'p1',
          'abc',
          'Song',
          'Artist',
          'Alb',
          const Duration(milliseconds: 200500),
        ),
      );
      expect(c.body, isNull);
      expect(out.dropped, isEmpty);
    });

    test('inline lyrics become the body, synced when stamped', () {
      final out = _search([
        {'id': '1', 'title': 'a', 'artist': 'b', 'lyrics': '[00:01.00] hi'},
        {'id': '2', 'title': 'a', 'artist': 'b', 'lyrics': 'just words'},
        {'id': '3', 'title': 'a', 'artist': 'b', 'lyrics': '  '},
      ]);
      expect(out.candidates[0].body!.syncedLrc, '[00:01.00] hi');
      expect(out.candidates[1].body!.plain, 'just words');
      expect(out.candidates[2].body, isNull);
    });

    test('a whole-number double duration is accepted', () {
      final out = readSearchOutput(
        '[{"id":"1","title":"a","artist":"b","durationMs":1500.0}]',
        providerId: 'p1',
      );
      expect(
        out.candidates.single.duration,
        const Duration(milliseconds: 1500),
      );
    });

    test(
      'inline lyrics that parse to no line leave the item without a body',
      () {
        final out = _search([
          {'id': '1', 'title': 'a', 'artist': 'b', 'lyrics': '[ar:Foo]'},
        ]);
        expect(out.candidates.single.body, isNull);
        expect(out.candidates.single.hasBody, isFalse);
      },
    );

    test('album null or blank is no album', () {
      final out = _search([
        {'id': '1', 'title': 'a', 'artist': 'b', 'album': null},
        {'id': '2', 'title': 'a', 'artist': 'b', 'album': ' '},
      ]);
      expect(out.candidates.map((c) => c.album), [null, null]);
    });

    test('an invalid item is dropped with a numbered reason', () {
      final good = {'id': '1', 'title': 'a', 'artist': 'b'};
      final out = _search([
        good,
        {'id': '2', 'title': 'a'},
        'text',
        {'id': '', 'title': 'a', 'artist': 'b'},
        {'id': 'x' * 257, 'title': 'a', 'artist': 'b'},
        {'id': '3', 'title': ' ', 'artist': 'b'},
        {'id': '4', 'title': 'a', 'artist': 'b', 'durationMs': 0},
        {'id': '5', 'title': 'a', 'artist': 'b', 'durationMs': 1.5},
        {'id': '6', 'title': 'a', 'artist': 'b', 'durationMs': '90'},
        {'id': '7', 'title': 'a', 'artist': 'b', 'album': 3},
        {'id': '8', 'title': 'a', 'artist': 'b', 'lyrics': 3},
        {'id': 9, 'title': 'a', 'artist': 'b'},
        good,
      ]);
      expect(out.candidates, hasLength(1));
      expect(out.dropped, [
        'result #2: "artist" must be a non-empty string',
        'result #3: must be an object',
        startsWith('result #4: "id" must be a non-empty string'),
        startsWith('result #5: "id" must be a non-empty string'),
        'result #6: "title" must be a non-empty string',
        'result #7: "durationMs" must be an integer above 0',
        'result #8: "durationMs" must be an integer above 0',
        'result #9: "durationMs" must be an integer above 0',
        'result #10: "album" must be a string',
        'result #11: "lyrics" must be a string',
        startsWith('result #12: "id" must'),
        'result #13: "id" repeats an earlier result',
      ]);
    });

    test('an id of 256 characters is kept', () {
      final out = _search([
        {'id': 'x' * 256, 'title': 'a', 'artist': 'b'},
      ]);
      expect(out.candidates, hasLength(1));
    });

    test('inline lyrics over 1 MiB drop the item', () {
      final out = _search([
        {'id': '0', 'title': 'a', 'artist': 'b'},
        {
          'id': '1',
          'title': 'a',
          'artist': 'b',
          'lyrics': 'x' * (1024 * 1024 + 1),
        },
      ]);
      expect(out.candidates.single.remoteId, '0');
      expect(out.dropped.single, 'result #2: "lyrics" is larger than 1 MiB');
    });

    test('a non-empty list without one valid item is an invalid response', () {
      final json = jsonEncode([
        {'id': '1', 'title': 'a'},
        'x',
      ]);
      expect(
        () => readSearchOutput(json, providerId: 'p1'),
        throwsA(
          isA<PluginOutputException>().having((e) => e.dropped, 'dropped', [
            'result #1: "artist" must be a non-empty string',
            'result #2: must be an object',
          ]),
        ),
      );
    });

    test('a repeated id keeps the first, at most 20 results are kept', () {
      final out = _search([
        {'id': '1', 'title': 'first', 'artist': 'b'},
        {'id': '1', 'title': 'second', 'artist': 'b'},
        for (var i = 2; i < 30; i++) {'id': '$i', 'title': 'a', 'artist': 'b'},
      ]);
      expect(out.candidates, hasLength(20));
      expect(out.candidates.first.title, 'first');
      expect(out.dropped.first, 'result #2: "id" repeats an earlier result');
      expect(out.rejectionSummary, startsWith('2 dropped: result #2'));
    });

    test('labels lose control and bidi characters and extra spaces', () {
      final out = _search([
        {
          'id': '1',
          'title': ' So\u0000ng \u202e  of  \n us ',
          'artist': 'A\tb',
          'album': ' \u0001 ',
        },
      ]);
      final c = out.candidates.single;
      expect((c.title, c.artist, c.album), ('Song of us', 'A b', null));
    });

    test('an id with a control character or a title of 513 characters', () {
      final out = _search([
        {'id': 'a\nb', 'title': 'a', 'artist': 'b'},
        {'id': '2', 'title': 'x' * 513, 'artist': 'b'},
        {'id': '3', 'title': 'x' * 512, 'artist': 'b'},
      ]);
      expect(out.candidates.map((c) => c.remoteId), ['3']);
      expect(out.dropped, hasLength(2));
    });

    test('a duration of 24 h or more is ignored, the item kept', () {
      final out = _search([
        {'id': '1', 'title': 'a', 'artist': 'b', 'durationMs': 86400000},
        {
          'id': '2',
          'title': 'a',
          'artist': 'b',
          'durationMs': 9007199254740991,
        },
        {'id': '3', 'title': 'a', 'artist': 'b', 'durationMs': 86399999},
      ]);
      expect(out.candidates.map((c) => c.duration), [
        null,
        null,
        const Duration(milliseconds: 86399999),
      ]);
      expect(out.dropped, isEmpty);
    });

    test('an empty array is a valid, empty answer', () {
      final out = _search(<Object>[]);
      expect(out.candidates, isEmpty);
      expect(out.dropped, isEmpty);
    });

    for (final bad in ['null', '{}', '"x"', '3', 'not json', '']) {
      test('output $bad is a bad shape', () {
        expect(() => readSearchOutput(bad, providerId: 'p1'), _badOutput);
      });
    }
  });

  group('lyrics output', () {
    LyricsBody? read(Object? data) => readLyricsOutput(jsonEncode(data));

    test('null is no lyrics', () {
      expect(readLyricsOutput('null'), isNull);
    });

    test('instrumental', () {
      final body = read({'instrumental': true})!;
      expect(body.instrumental, isTrue);
      expect(body.hasLyrics, isFalse);
    });

    test('instrumental true wins over data', () {
      expect(
        read({'instrumental': true, 'data': 'words'})!.instrumental,
        isTrue,
      );
    });

    test('type lrc without any stamp is plain, txt is plain even with one', () {
      expect(read({'data': 'words', 'type': 'lrc'})!.plain, 'words');
      expect(
        read({'data': '[00:01.00] x', 'type': 'lrc'})!.syncedLrc,
        isNotNull,
      );
      expect(
        read({'data': '[00:01.00] x', 'type': 'txt'})!.plain,
        '[00:01.00] x',
      );
    });

    test('control characters go and CRLF becomes LF', () {
      final body = read({'data': 'a\r\nb\u0000c\u202ed'})!;
      expect(body.plain, 'a\nbcd');
    });

    test('a missing or unknown type is detected from a stamp', () {
      expect(read({'data': '[01:02.30] x'})!.syncedLrc, '[01:02.30] x');
      expect(
        read({'data': '[01:02] x', 'type': 'weird'})!.syncedLrc,
        isNotNull,
      );
      expect(read({'data': 'no stamps [ar:x]'})!.plain, 'no stamps [ar:x]');
    });

    test('text that parses to no line is no lyrics', () {
      for (final text in [
        '[ar:Foo]\n[ti:Bar]',
        '[00:01.00]\n[00:02.00]',
        '[length:03:20]',
      ]) {
        expect(read({'data': text}), isNull, reason: text);
        expect(read({'data': text, 'type': 'lrc'}), isNull, reason: text);
        expect(read({'data': text, 'type': 'txt'}), isNull, reason: text);
      }
    });

    test('blank data and instrumental false is no lyrics', () {
      expect(read({'data': ' \n', 'instrumental': false}), isNull);
    });

    test('data of exactly 1 MiB passes, one more byte is refused', () {
      final ok = 'a' * (1024 * 1024);
      expect(read({'data': ok})!.plain, hasLength(1024 * 1024));
      expect(() => read({'data': '${ok}a'}), _badOutput);
    });

    test('multi-byte text is measured in UTF-8 bytes', () {
      // 400k three-byte characters are 1.2 MB.
      expect(() => read({'data': 'あ' * 400000}), _badOutput);
      expect(read({'data': 'あ' * 300000}), isNotNull);
    });

    for (final bad in [
      <String, Object?>{},
      {'data': 5},
      {'data': null},
      {'data': 'x', 'type': 3},
      {'instrumental': 'yes', 'data': 'x'},
      [1],
      'text',
      7,
    ]) {
      test('${jsonEncode(bad)} is a bad shape', () {
        expect(() => read(bad), _badOutput);
      });
    }

    test('text that is not JSON is a bad shape', () {
      expect(() => readLyricsOutput('{oops'), _badOutput);
    });
  });
}
