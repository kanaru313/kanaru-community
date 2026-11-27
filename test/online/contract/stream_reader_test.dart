import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/data/contract/stream_reader.dart';
import 'package:kanaru/src/online/domain/contract/online_output_exception.dart';
import 'package:kanaru/src/online/domain/contract/stream_answer.dart';

Map<String, Object?> body([Map<String, Object?> over = const {}]) => {
  'url': 'https://cdn.example.com/a.mp3?x=1',
  'mimeType': 'audio/mpeg',
  ...over,
};

StreamRead read(Map<String, Object?> v) => readStreamOutput(jsonEncode(v));
StreamAnswer ok(Map<String, Object?> v) => (read(v) as StreamPlayable).answer;
Matcher get invalid => throwsA(isA<OnlineOutputException>());

void main() {
  test('reads every field', () {
    final a = ok(
      body({
        'headers': {'Authorization': 'Bearer abcdefgh', 'Cookie': 'a=b'},
        'bitrate': 128000,
        'expiresAtMs': 1700000000000,
      }),
    );
    expect(a.url.host, 'cdn.example.com');
    expect(a.headers, {'authorization': 'Bearer abcdefgh', 'cookie': 'a=b'});
    expect(a.container, StreamContainer.mp3);
    expect(a.bitrate, 128000);
    expect(
      a.expiresAt,
      DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
    );
    expect(a.expiresAt!.isUtc, isTrue);
  });

  test('bad url is invalid, even with an HLS type', () {
    final base = 'https://cdn.example.com/';
    for (final url in [
      'http://cdn.example.com/a',
      'https://cdn.example.com:443/a',
      'https://cdn.example.com:8443/a',
      'https://u:p@cdn.example.com/a',
      '/relative/a.mp3',
      'https://cdn.example.com/${'a' * (8 * 1024)}',
      7,
    ]) {
      expect(() => read(body({'url': url})), invalid, reason: '$url');
      expect(
        () => read(body({'url': url, 'mimeType': 'application/x-mpegurl'})),
        invalid,
      );
    }
    expect(() => readStreamOutput('[]'), invalid);
    expect(() => readStreamOutput('nope'), invalid);
    expect(ok(body({'url': '${base}ok'})).url.path, '/ok');
  });

  test('headers', () {
    final twenty = {for (var i = 0; i < 20; i++) 'x-h$i': 'v'};
    expect(ok(body({'headers': twenty})).headers, hasLength(20));
    expect(
      () => read(
        body({
          'headers': {...twenty, 'x-h20': 'v'},
        }),
      ),
      invalid,
    );
    expect(() => read(body({'headers': 'x'})), invalid);
    expect(
      () => read(
        body({
          'headers': {'x-a': 1},
        }),
      ),
      invalid,
    );
    expect(
      () => read(
        body({
          'headers': {'x-a': 'a\r\nb: c'},
        }),
      ),
      invalid,
    );
    final a = ok(
      body({
        'headers': {
          'Range': 'bytes=0-',
          'If-Range': 'x',
          'Cookie': 'sid=1',
          'Authorization': 'Basic abc',
        },
      }),
    );
    expect(a.headers.keys.toSet(), {'cookie', 'authorization'});
    expect(ok(body({'headers': null})).headers, isEmpty);
  });

  test('containers', () {
    StreamContainer? of(String mime) =>
        (read(body({'mimeType': mime})) as StreamPlayable).answer.container;
    expect(of('audio/mpeg'), StreamContainer.mp3);
    expect(of('audio/webm; codecs="opus"'), StreamContainer.webm);
    expect(of('audio/mp4; codecs="mp4a.40.2"'), StreamContainer.mp4);
    expect(of('video/mp4'), StreamContainer.mp4);
    expect(of('video/webm'), StreamContainer.webm);
    expect(of(' AUDIO/MPEG '), StreamContainer.mp3);
  });

  test('HLS and other known families are unsupported', () {
    for (final (mime, type) in [
      ('application/vnd.apple.mpegurl', 'application/vnd.apple.mpegurl'),
      ('Application/X-MpegURL', 'application/x-mpegurl'),
      ('audio/mpegurl; charset=utf-8', 'audio/mpegurl'),
      ('AUDIO/X-MPEGURL', 'audio/x-mpegurl'),
      ('audio/ogg', 'audio/ogg'),
      ('audio/flac', 'audio/flac'),
      ('audio/aac', 'audio/aac'),
    ]) {
      final r = read(body({'mimeType': mime}));
      expect(r, isA<StreamUnsupported>(), reason: mime);
      expect((r as StreamUnsupported).mediaType, type);
    }
  });

  test('malformed mimeType is invalid', () {
    for (final mime in ['text/html', 'nonsense', 42, '', 'audio/', null]) {
      expect(() => read(body({'mimeType': mime})), invalid, reason: '$mime');
    }
  });

  test('bitrate and expiry that are not positive read as unknown', () {
    for (final v in [0, -1, 'x', null]) {
      final a = ok(body({'bitrate': v, 'expiresAtMs': v}));
      expect(a.bitrate, isNull, reason: '$v');
      expect(a.expiresAt, isNull, reason: '$v');
    }
    expect(ok(body({'expiresAtMs': 9e15})).expiresAt, isNull);
  });

  test('toString hides url and headers', () {
    final a = ok(
      body({
        'headers': {'cookie': 'secret-cookie-value'},
      }),
    );
    final text = a.toString();
    expect(text, 'StreamAnswer(mp3)');
    expect(text, isNot(contains('cdn.example')));
    expect(text, isNot(contains('secret')));
  });
}
