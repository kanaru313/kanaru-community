import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/merge_arb.dart';

/// Writes `parts/<name>.arb` files into a fresh temp l10n folder.
Directory _l10n(Map<String, String> parts) {
  final dir = Directory.systemTemp.createTempSync('merge_arb_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  Directory('${dir.path}/parts').createSync();
  parts.forEach(
    (name, body) => File('${dir.path}/parts/$name.arb').writeAsStringSync(body),
  );
  return dir;
}

final _okParts = {
  'app_en': '{"navHome": "Home"}',
  'app_vi': '{"navHome": "Trang chu"}',
  'scan_en': '{"scanExample": "Rescan", "@scanExample": {"description": "x"}}',
  'scan_vi':
      '{"scanExample": "Quet lai", "@scanExample": {"description": "x"}}',
};

void main() {
  test('the committed arb files match the parts', () {
    final out = StringBuffer();
    expect(
      runMergeArb(Directory('lib/l10n'), check: true, out: out),
      0,
      reason: '$out',
    );
  });

  test('merges parts per locale in part order with a generated marker', () {
    final merged = mergeArbParts(_l10n(_okParts));
    expect(merged.keys, containsAll(['en', 'vi']));
    final en = merged['en']!;
    expect(en, contains('"@@locale": "en"'));
    expect(en, contains(generatedMarker));
    expect(en.indexOf('navHome') < en.indexOf('scanExample'), isTrue);
    expect(en, contains('"@scanExample"'));
  });

  test('a duplicate key across parts fails', () {
    // `scanExample` is defined by the scan part and again by the app part.
    final dir = _l10n({
      ..._okParts,
      'app_en': '{"navHome": "Home", "scanExample": "dup"}',
    });
    expect(
      () => mergeArbParts(dir),
      throwsA(
        isA<ArbMergeException>().having(
          (e) => e.message,
          'message',
          contains('scanExample'),
        ),
      ),
    );
  });

  test('a key outside its part prefix fails', () {
    final dir = _l10n({
      ..._okParts,
      'scan_en': '{"playbackCover": "x"}',
      'scan_vi': '{"playbackCover": "x"}',
    });
    expect(
      () => mergeArbParts(dir),
      throwsA(
        isA<ArbMergeException>().having(
          (e) => e.message,
          'message',
          contains('outside'),
        ),
      ),
    );
  });

  test('a key missing in vi fails', () {
    final dir = _l10n({..._okParts, 'scan_vi': '{}'});
    expect(
      () => mergeArbParts(dir),
      throwsA(
        isA<ArbMergeException>().having(
          (e) => e.message,
          'message',
          contains('scanExample'),
        ),
      ),
    );
  });

  test('--check reports a stale merged file and writing fixes it', () {
    final dir = _l10n(_okParts);
    File('${dir.path}/app_en.arb').writeAsStringSync('{}');
    final out = StringBuffer();
    expect(runMergeArb(dir, check: true, out: out), 1);
    expect(out.toString(), contains('stale'));
    expect(out.toString(), contains('dart run tool/merge_arb.dart'));

    expect(runMergeArb(dir, check: false, out: StringBuffer()), 0);
    expect(runMergeArb(dir, check: true, out: StringBuffer()), 0);
  });

  test('an unknown part file fails', () {
    final dir = _l10n({..._okParts, 'extra_en': '{}'});
    expect(() => mergeArbParts(dir), throwsA(isA<ArbMergeException>()));
  });
}
