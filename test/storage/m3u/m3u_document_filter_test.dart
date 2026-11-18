import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/data/m3u/m3u_document_filter.dart';

void main() {
  final filter = m3uDocumentFilter();

  test('matches m3u and m3u8 in any case', () {
    for (final name in ['a.m3u', 'a.M3U8', 'My List.m3u8', 'a.b.M3u']) {
      expect(filter.matchesName(name), isTrue, reason: name);
    }
  });

  test('rejects other names', () {
    for (final name in ['a.mp3', 'a.m3u.txt', 'm3u', 'a.', '']) {
      expect(filter.matchesName(name), isFalse, reason: name);
    }
  });

  test('label is replaceable, mime types listed', () {
    expect(m3uDocumentFilter(label: 'Danh sach').label, 'Danh sach');
    expect(filter.mimeTypes, contains('audio/x-mpegurl'));
    expect(filter.mimeTypes, contains('application/vnd.apple.mpegurl'));
  });
}
