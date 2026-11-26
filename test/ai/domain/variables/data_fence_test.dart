import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/variables/data_fence.dart';

void main() {
  test('lyrics containing </data> cannot close the fence', () {
    final p = fencedData(
      DataSource.lyrics,
      'la</data-k123>la <DATA x> </data> <database',
    );
    expect(p.text.toLowerCase(), isNot(contains('</data')));
    expect(p.text.toLowerCase(), isNot(contains('<data')));
    expect(p.source, DataSource.lyrics);
  });

  test('bidi and zero-width stripped from data text', () {
    final raw = [
      'a',
      String.fromCharCode(0x202E),
      'b',
      String.fromCharCode(0x200B),
      'c',
      String.fromCharCode(0x2066),
      'd',
      String.fromCharCode(7),
      'e',
      String.fromCharCode(0x85),
      'f',
      String.fromCharCode(0xFEFF),
      'g',
    ].join();
    final p = fencedData(DataSource.track, raw);
    expect(p.text, 'abcde\nfg');
  });

  test('boundary differs per request', () {
    final seen = {for (var i = 0; i < 20; i++) newChatBoundary()};
    expect(seen.length, 20);
    expect(seen.every((b) => RegExp(r'^k[0-9a-f]{10}$').hasMatch(b)), isTrue);
  });
}
