import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/domain/online/source_prefs.dart';

LyricsSource _source(String id, {LyricsSourceOrigin? origin}) {
  final o = origin ?? LyricsSourceOrigin.repo;
  return LyricsSource(
    id: id,
    name: id,
    version: 1,
    origin: o,
    enabled: defaultSourceEnabled(o),
  );
}

void main() {
  group('defaults', () {
    test('on for a repository install, off for a file or a link', () {
      expect(defaultSourceEnabled(LyricsSourceOrigin.repo), isTrue);
      expect(defaultSourceEnabled(LyricsSourceOrigin.file), isFalse);
      expect(defaultSourceEnabled(LyricsSourceOrigin.link), isFalse);
    });
  });

  group('applySourcePrefs', () {
    test('no saved prefs: install order and the default switches', () {
      final out = applySourcePrefs(const [], [
        _source('a'),
        _source('b', origin: LyricsSourceOrigin.file),
        _source('c', origin: LyricsSourceOrigin.link),
      ]);
      expect(
        [for (final s in out) (s.id, s.enabled)],
        [('a', true), ('b', false), ('c', false)],
      );
    });

    test('saved order and switches win, new plugins follow', () {
      final out = applySourcePrefs(
        const [SourcePref('c', on: false), SourcePref('a', on: true)],
        [_source('a'), _source('b'), _source('c')],
      );
      expect(
        [for (final s in out) (s.id, s.enabled)],
        [('c', false), ('a', true), ('b', true)],
      );
    });

    test('a saved on for a file install turns it on', () {
      final out = applySourcePrefs(
        const [SourcePref('f', on: true)],
        [_source('f', origin: LyricsSourceOrigin.file)],
      );
      expect(out.single.enabled, isTrue);
    });

    test('a removed plugin drops out, a repeated id counts once', () {
      final out = applySourcePrefs(
        const [
          SourcePref('gone', on: true),
          SourcePref('a', on: false),
          SourcePref('a', on: true),
        ],
        [_source('a')],
      );
      expect([for (final s in out) (s.id, s.enabled)], [('a', false)]);
    });

    test('prefsOf round-trips through the JSON form', () {
      final out = applySourcePrefs(
        const [SourcePref('b', on: false)],
        [_source('a'), _source('b')],
      );
      final json = [for (final p in prefsOf(out)) p.toJson()];
      expect(json, [
        {'id': 'b', 'on': false},
        {'id': 'a', 'on': true},
      ]);
      expect(decodeSourcePrefs(json), prefsOf(out));
    });
  });

  group('decodeSourcePrefs', () {
    test('keeps the first of a repeated id', () {
      expect(
        decodeSourcePrefs([
          {'id': 'a', 'on': true},
          {'id': 'a', 'on': false},
        ]),
        [const SourcePref('a', on: true)],
      );
    });

    test('a malformed item is skipped, the rest of the list stays', () {
      expect(
        decodeSourcePrefs([
          {'id': 'a', 'on': true},
          {'id': 3, 'on': true},
          {'id': 'b'},
          {'id': 'c', 'on': 'yes'},
          1,
          'x',
          {'id': 'd', 'on': false},
        ]),
        [const SourcePref('a', on: true), const SourcePref('d', on: false)],
      );
    });

    for (final bad in <Object?>[
      null,
      'x',
      3,
      {'id': 'a', 'on': true},
    ]) {
      test('$bad is not a list and is refused', () {
        expect(() => decodeSourcePrefs(bad), throwsFormatException);
      });
    }
  });
}
