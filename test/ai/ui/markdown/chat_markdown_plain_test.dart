import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/ui/markdown/chat_markdown_plain.dart';

void main() {
  String plain(String md, [Map<String, String> labels = const {}]) =>
      plainAnswerText(md, trackLabel: (id) => labels[id]);

  test('markers are dropped', () {
    expect(
      plain('a **bold** and `code` and *slanted* word'),
      'a bold and code and slanted word',
    );
  });

  test('lists keep their numbers and bullets', () {
    expect(plain('1. one\n2. two\n\n- x\n- y'), '1. one\n2. two\n\n• x\n• y');
  });

  test('a song line becomes title – artist, an unknown one is dropped', () {
    final out = plain('Try:\n[[t:7]]\n[[t:8]]\n[[t:9]]', {
      '7': 'Lac troi – Son Tung',
      '8': 'Chay ngay di – Son Tung',
    });
    expect(out, 'Try:\n\nLac troi – Son Tung\nChay ngay di – Son Tung');
    expect(out, isNot(contains('[[t:')));
  });

  test('trackTokensOf lists the ids as typed', () {
    expect(trackTokensOf('x\n[[t:7]]\ny\n[[t:8]]'), ['7', '8']);
  });

  test(
    'a long song run (one box on screen) copies and lists like a short one',
    () {
      final md = [for (var i = 1; i <= 12; i++) '[[t:$i]]'].join('\n');
      expect(trackTokensOf(md), [for (var i = 1; i <= 12; i++) '$i']);
      final out = plain('Top:\n$md', {
        for (var i = 1; i <= 12; i++) '$i': 'S$i',
      });
      expect(
        out,
        'Top:\n\n${[for (var i = 1; i <= 12; i++) 'S$i'].join('\n')}',
      );
    },
  );
}
