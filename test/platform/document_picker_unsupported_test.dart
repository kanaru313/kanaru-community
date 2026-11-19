import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/data/document_picker_unsupported.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';

void main() {
  const picker = UnsupportedDocumentPicker();
  const target = SaveTarget(name: 'a.m3u8', handle: '/x/a.m3u8');

  test('dialogs return null', () async {
    const filter = DocumentFilter(label: 'M3U', extensions: ['m3u']);
    expect(await picker.openDocument(filter), isNull);
    expect(await picker.createDocument(suggestedName: 'a.m3u8'), isNull);
  });

  test('read and write report unsupported', () async {
    final read = await picker.read(
      const PickedDocument(name: 'a', handle: 'a'),
      maxBytes: 10,
    );
    expect((read as Err).error, DocumentError.unsupported);
    final write = await picker.write(target, Uint8List(1));
    expect((write as Err).error, DocumentError.unsupported);
  });

  test('discard does nothing', () async {
    await picker.discard(target);
  });

  test('filter matches extensions case-insensitively', () {
    const filter = DocumentFilter(label: 'M3U', extensions: ['m3u', 'M3U8']);
    expect(filter.matchesName('Mix.M3U'), isTrue);
    expect(filter.matchesName('mix.m3u8'), isTrue);
    expect(filter.matchesName('mix.txt'), isFalse);
    expect(filter.matchesName('m3u'), isFalse);
    expect(filter.matchesName('mix.'), isFalse);
  });
}
