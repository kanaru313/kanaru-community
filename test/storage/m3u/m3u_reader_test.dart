import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/storage/data/m3u/m3u_reader.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_limits.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_parse.dart';

class _Picker implements DocumentPicker {
  _Picker(this.result);
  final Result<Uint8List, DocumentError> result;
  int? lastMax;
  int reads = 0;

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) async {
    reads++;
    lastMax = maxBytes;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('$i');
}

M3uParse failingParse(Uint8List _) => throw const FormatException('boom');

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  const text = '#EXTM3U\n#EXTINF:10,A - B\n/m/a.mp3\nrock/b.flac\n';

  test('parses like the direct parser, with name and base folder', () async {
    final picker = _Picker(Ok(bytes(text)));
    final out = await readM3u(
      picker,
      const PickedDocument(
        name: 'Mix.m3u8',
        handle: 'h',
        localPath: '/home/u/Lists/Mix.m3u8',
      ),
    );
    final ok = out as M3uReadOk;
    final direct = parseM3u(bytes(text));
    expect(ok.parse.entries.map((e) => e.text), ['/m/a.mp3', 'rock/b.flac']);
    expect(
      ok.parse.entries.map((e) => e.line),
      direct.entries.map((e) => e.line),
    );
    expect(ok.parse.entries.first.extinf?.title, 'B');
    expect(ok.fileName, 'Mix.m3u8');
    expect(ok.baseDir, '/home/u/Lists');
    expect(picker.lastMax, m3uMaxBytes);
  });

  test('no local path: no base folder; root file: base is /', () async {
    final picker = _Picker(Ok(bytes(text)));
    final none = await readM3u(
      picker,
      const PickedDocument(name: 'a.m3u', handle: 'h'),
    );
    expect((none as M3uReadOk).baseDir, isNull);
    final root = await readM3u(
      picker,
      const PickedDocument(name: 'a.m3u', handle: 'h', localPath: '/a.m3u'),
    );
    expect((root as M3uReadOk).baseDir, '/');
  });

  test('picker errors pass through', () async {
    for (final e in DocumentError.values) {
      final out = await readM3u(
        _Picker(Err(e)),
        const PickedDocument(name: 'a.m3u', handle: 'h'),
      );
      expect((out as M3uReadFailed).error, e);
    }
  });

  test('a name outside the filter is notAFile and is not read', () async {
    final picker = _Picker(Ok(bytes(text)));
    final out = await readM3u(
      picker,
      const PickedDocument(name: 'a.txt', handle: 'h'),
    );
    expect((out as M3uReadFailed).error, DocumentError.notAFile);
    expect(picker.reads, 0);
  });

  test('a parser error propagates', () async {
    await expectLater(
      readM3u(
        _Picker(Ok(bytes(text))),
        const PickedDocument(name: 'a.m3u', handle: 'h'),
        parseFile: failingParse,
      ),
      throwsFormatException,
    );
  });
}
