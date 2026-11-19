import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/read_rules.dart';
import 'package:kanaru/src/library/state/scan/read_rules_settings.dart';

void main() {
  test('the default fingerprint is a fixed literal', () {
    expect(
      LibraryReadRules.defaults.fingerprint,
      'a0a37db45ddd87b008f1c5082a411aa9509fcef7',
    );
  });

  test('the fingerprint follows every part of the rules', () {
    final base = LibraryReadRules.defaults.fingerprint;
    expect(LibraryReadRules().fingerprint, base);
    expect(
      LibraryReadRules(separators: [...defaultArtistSeparators, ','])
          .fingerprint,
      isNot(base),
    );
    expect(LibraryReadRules(keepWhole: const []).fingerprint, isNot(base));
    expect(
      LibraryReadRules(languageSource: LanguageSource.tagOnly).fingerprint,
      isNot(base),
    );
    // Stored order counts: the canonical form is the stored list.
    expect(
      LibraryReadRules(separators: defaultArtistSeparators.reversed.toList())
          .fingerprint,
      isNot(base),
    );
  });

  group('entry check and decode agree', () {
    const inputs = <String, SplitEntryProblem?>{
      ';': null,
      ' , ': null,
      'with': null,
      '\u0001a\u0002': null,
      '': SplitEntryProblem.empty,
      '   ': SplitEntryProblem.empty,
      '\u0001\u0002': SplitEntryProblem.empty,
    };

    inputs.forEach((raw, problem) {
      test('"${raw.replaceAll(RegExp(r'[\x00-\x1F]'), '?')}"', () {
        if (problem == null) {
          final cleaned = cleanSeparator(raw);
          expect(cleaned, cleaned.trim());
          expect(decodeSplitEntries([raw]), [cleaned]);
          expect(cleanKeepWhole(raw), cleaned);
        } else {
          expect(
            () => cleanSeparator(raw),
            throwsA(
              isA<SplitEntryException>().having(
                (e) => e.problem,
                'problem',
                problem,
              ),
            ),
          );
          expect(() => decodeSplitEntries([raw]), throwsFormatException);
        }
      });
    });

    test('too long, duplicate, list full', () {
      final long = 'x' * (maxSplitEntryLength + 1);
      expect(
        () => cleanSeparator(long),
        throwsA(
          isA<SplitEntryException>().having(
            (e) => e.problem,
            'problem',
            SplitEntryProblem.tooLong,
          ),
        ),
      );
      expect(() => decodeSplitEntries([long]), throwsFormatException);
      expect(cleanSeparator('x' * maxSplitEntryLength), hasLength(64));

      expect(
        () => cleanSeparator('FEAT.', existing: defaultArtistSeparators),
        throwsA(
          isA<SplitEntryException>().having(
            (e) => e.problem,
            'problem',
            SplitEntryProblem.duplicate,
          ),
        ),
      );
      expect(() => decodeSplitEntries([';', ';']), throwsFormatException);

      final full = [for (var i = 0; i < maxSplitEntries; i++) 'e$i'];
      expect(decodeSplitEntries(full), full);
      expect(
        () => cleanSeparator('more', existing: full),
        throwsA(
          isA<SplitEntryException>().having(
            (e) => e.problem,
            'problem',
            SplitEntryProblem.listFull,
          ),
        ),
      );
      expect(
        () => decodeSplitEntries([...full, 'more']),
        throwsFormatException,
      );
    });

    test('a damaged stored list throws, so the setting uses its default', () {
      expect(
        () => artistSeparatorsSetting.decode(['ok', 3]),
        throwsFormatException,
      );
      expect(artistSeparatorsSetting.defaultValue, defaultArtistSeparators);
    });
  });

  test('decode: not a list or a bad entry throws, empty list is valid', () {
    expect(() => decodeSplitEntries('x'), throwsFormatException);
    expect(() => decodeSplitEntries(['a', 4]), throwsFormatException);
    expect(decodeSplitEntries(<String>[]), isEmpty);
    expect(decodeSplitEntries(['  a  ', 'b']), ['a', 'b']);
  });

  test('language source decodes by name and refuses the rest', () {
    expect(languageSourceSetting.decode('tagOnly'), LanguageSource.tagOnly);
    // Not available yet: a stored value behaves as the default.
    expect(
      languageSourceSetting.decode('detectedOnly'),
      LanguageSource.tagThenDetected,
    );
    expect(() => languageSourceSetting.decode('nope'), throwsFormatException);
    expect(() => languageSourceSetting.decode(3), throwsFormatException);
  });

  test('a word entry starts with a letter', () {
    expect(isWordSeparator('feat.'), isTrue);
    expect(isWordSeparator('với'), isTrue);
    expect(isWordSeparator(';'), isFalse);
    expect(isWordSeparator('&'), isFalse);
    expect(isWordSeparator('//'), isFalse);
  });
}
