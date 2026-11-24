import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/translation/translate_output.dart';

TranslateChunk ok(TranslateOutput o) => o as TranslateChunk;

void main() {
  test('reads texts and detected per source', () {
    final o = ok(
      readTranslateOutput(
        jsonEncode([
          {'text': 'xin chao', 'detected': 'en'},
          {'text': 'tam biet'},
        ]),
        ['hello', 'bye'],
        to: 'vi',
      ),
    );
    expect(o.texts, {'hello': 'xin chao', 'bye': 'tam biet'});
    expect(o.detected, {'hello': 'en', 'bye': null});
    expect(o.isEcho, isFalse);
  });

  test('strips controls and bidi, newline becomes a space', () {
    final o = ok(
      readTranslateOutput(
        jsonEncode([
          {'text': 'a\n\nb\u202Ec\u0007d'},
        ]),
        ['src'],
      ),
    );
    expect(o.texts['src'], 'a bcd');
  });

  test('length mismatch is rejected', () {
    expect(
      readTranslateOutput('[{"text":"a"}]', ['a', 'b']),
      isA<TranslateRejected>(),
    );
  });

  test('more than half of non-blank sources empty is rejected', () {
    final out = jsonEncode([
      {'text': ''},
      {'text': ''},
      {'text': 'x'},
      {'text': ''},
    ]);
    expect(
      readTranslateOutput(out, ['a', 'b', 'c', '']),
      isA<TranslateRejected>(),
    );
    final half = jsonEncode([
      {'text': ''},
      {'text': 'x'},
      {'text': ''},
    ]);
    expect(readTranslateOutput(half, ['a', 'b', '']), isA<TranslateChunk>());
  });

  test('text over 4x source + 200 is rejected', () {
    final out = jsonEncode([
      {'text': 'x' * 205},
    ]);
    expect(readTranslateOutput(out, ['a']), isA<TranslateRejected>());
    expect(
      readTranslateOutput(
        jsonEncode([
          {'text': 'x' * 204},
        ]),
        ['a'],
      ),
      isA<TranslateChunk>(),
    );
  });

  test('detected: bad tag dropped; target on a changed line dropped', () {
    final o = ok(
      readTranslateOutput(
        jsonEncode([
          {'text': 'xin', 'detected': 'not a tag!'},
          {'text': 'chao', 'detected': 'vi'},
          {'text': 'same', 'detected': 'vi-VN'},
        ]),
        ['a', 'b', 'same'],
        to: 'vi',
      ),
    );
    expect(o.detected, {'a': null, 'b': null, 'same': 'vi-VN'});
    expect(o.isEcho, isFalse);
  });

  test('isEcho when every text equals its source', () {
    final o = ok(
      readTranslateOutput(
        jsonEncode([
          {'text': 'a'},
          {'text': 'b'},
        ]),
        ['a', 'b'],
      ),
    );
    expect(o.isEcho, isTrue);
  });

  test('rejection reasons carry no lyric text', () {
    final r = readTranslateOutput('[{"text":5}]', [
      'SECRET LYRIC',
    ]) as TranslateRejected;
    expect(r.reason, isNot(contains('SECRET')));
  });

  test('never throws on malformed input', () {
    for (final bad in [
      '',
      '{',
      'null',
      '[1]',
      '[null]',
      '[[]]',
      '"x"',
      '[{"text":5}]',
      '[{"text":"a","detected":5}]',
      '[{"text":"${'z' * 100000}"}]',
    ]) {
      expect(
        () => readTranslateOutput(bad, ['a']),
        returnsNormally,
        reason: bad.length > 50 ? 'huge' : bad,
      );
    }
    expect(() => readTranslateOutput('[]', []), returnsNormally);
  });
}
