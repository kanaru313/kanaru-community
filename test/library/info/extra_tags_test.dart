import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/tags/extra_tags.dart';

void main() {
  test('round trip keeps both fields and the version', () {
    final raw = encodeExtraTags(
      releaseDate: '2019-07-15',
      description: 'Live at home',
    );
    expect(jsonDecode(raw!), {
      'v': extraTagsVersion,
      'releaseDate': '2019-07-15',
      'description': 'Live at home',
    });
    expect(
      decodeExtraTags(raw),
      const ExtraTags(releaseDate: '2019-07-15', description: 'Live at home'),
    );
  });

  test('null keys are left out and nothing to store gives null', () {
    expect(jsonDecode(encodeExtraTags(description: 'x')!), {
      'v': extraTagsVersion,
      'description': 'x',
    });
    expect(encodeExtraTags(), isNull);
    expect(encodeExtraTags(releaseDate: '  ', description: ''), isNull);
  });

  test('broken or foreign input decodes to empty', () {
    for (final raw in [null, '', '{', 'nope', '[]', '"s"', '42', 'null']) {
      expect(decodeExtraTags(raw).isEmpty, isTrue, reason: '$raw');
    }
  });

  test('unknown keys and wrong types are ignored', () {
    final tags = decodeExtraTags(
      '{"v":9,"extra":1,"releaseDate":2019,"description":"ok"}',
    );
    expect(tags, const ExtraTags(description: 'ok'));
  });

  test('a long description is cut so the blob stays within 4 KB', () {
    final raw = encodeExtraTags(
      releaseDate: '2019',
      description: 'ế' * 5000, // 3 bytes per character
    )!;
    expect(utf8.encode(raw).length, lessThanOrEqualTo(4096));
    final tags = decodeExtraTags(raw);
    expect(tags.releaseDate, '2019');
    expect(tags.description, isNotEmpty);
    expect(tags.description!.replaceAll('ế', ''), isEmpty);
  });

  test('a surrogate pair is never split by the cut', () {
    final raw = encodeExtraTags(description: '😀' * 3000)!;
    expect(utf8.encode(raw).length, lessThanOrEqualTo(4096));
    expect(decodeExtraTags(raw).description, isNot(contains('�')));
  });

  test('a release date over 64 bytes is dropped, not cut', () {
    expect(encodeExtraTags(releaseDate: '2' * 65), isNull);
    final raw = encodeExtraTags(releaseDate: '2' * 65, description: 'x');
    expect(decodeExtraTags(raw), const ExtraTags(description: 'x'));
    expect(
      decodeExtraTags(encodeExtraTags(releaseDate: '2' * 64)).releaseDate,
      hasLength(64),
    );
  });

  test('a huge description is cut within the cap', () {
    final raw = encodeExtraTags(description: 'a' * 1000000)!;
    expect(utf8.encode(raw).length, lessThanOrEqualTo(4096));
  });
}
