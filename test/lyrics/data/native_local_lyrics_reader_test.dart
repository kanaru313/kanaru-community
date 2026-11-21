import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/lrc_file_read.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/data/native_local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/rust/api/error.dart';
import 'package:kanaru/src/rust/api/lyrics.dart';

NativeError _error(NativeErrorKind kind, {bool transient = false}) =>
    NativeError(kind: kind, detail: 'secret/path', transient: transient);

void main() {
  test('maps the DTO: text and SYLT lines with durations', () async {
    final reader = NativeLocalLyricsReader(
      readTagFn: (_) async => EmbeddedLyricsDto(
        text: 'plain',
        synced: [SyncedLyricLineDto(timeMs: 1500, text: 'a')],
      ),
    );
    final tag = (await reader.readTag('/m/a.mp3'))!;
    expect(tag.text, 'plain');
    expect(tag.synced, [const LyricLine(Duration(milliseconds: 1500), 'a')]);
  });

  test('no lyrics in the file is null', () async {
    final reader = NativeLocalLyricsReader(readTagFn: (_) async => null);
    expect(await reader.readTag('/m/a.mp3'), isNull);
  });

  test('passes the path to the bridge', () async {
    String? seen;
    final reader = NativeLocalLyricsReader(
      readTagFn: (p) async {
        seen = p;
        return null;
      },
    );
    await reader.readTag('/m/x.flac');
    expect(seen, '/m/x.flac');
  });

  const permanent = [
    NativeErrorKind.notFound,
    NativeErrorKind.permissionDenied,
    NativeErrorKind.corrupt,
    NativeErrorKind.unsupported,
    NativeErrorKind.panic,
  ];
  for (final kind in permanent) {
    test('${kind.name} is a permanent failure', () async {
      final reader = NativeLocalLyricsReader(
        readTagFn: (_) async => throw _error(kind),
      );
      await expectLater(
        reader.readTag('/m/a.mp3'),
        throwsA(
          isA<LyricsReadFailure>()
              .having((f) => f.transient, 'transient', isFalse)
              .having((f) => f.kind, 'kind', kind.name),
        ),
      );
    });
  }

  test('a native timeout is transient, with or without the flag', () async {
    for (final flag in [true, false]) {
      final reader = NativeLocalLyricsReader(
        readTagFn: (_) async =>
            throw _error(NativeErrorKind.timeout, transient: flag),
      );
      await expectLater(
        reader.readTag('/m/a.mp3'),
        throwsA(
          isA<LyricsReadFailure>().having((f) => f.transient, 't', isTrue),
        ),
      );
    }
  });

  test('a failure carries no path', () async {
    final reader = NativeLocalLyricsReader(
      readTagFn: (_) async => throw _error(NativeErrorKind.io, transient: true),
    );
    try {
      await reader.readTag('/m/a.mp3');
      fail('expected a failure');
    } on LyricsReadFailure catch (f) {
      expect(f.toString(), isNot(contains('secret')));
    }
  });

  test('NoLocalLyricsReader reads nothing', () async {
    const reader = NoLocalLyricsReader();
    expect(await reader.readTag('/x'), isNull);
    expect(await reader.statLrc('/x.lrc'), isNull);
    expect(
      await reader.readLrc(const LrcStat(path: '/x.lrc', mtimeMs: 1, size: 1)),
      isNull,
    );
  });

  test('a .lrc read is joined by path, mtime and size', () {
    const a = LrcStat(path: '/m/a.lrc', mtimeMs: 1, size: 10);
    expect(
      lrcReadKey(a),
      lrcReadKey(const LrcStat(path: '/m/a.lrc', mtimeMs: 1, size: 10)),
    );
    expect(
      lrcReadKey(a),
      isNot(lrcReadKey(const LrcStat(path: '/m/a.lrc', mtimeMs: 2, size: 10))),
    );
    expect(
      lrcReadKey(a),
      isNot(lrcReadKey(const LrcStat(path: '/m/a.lrc', mtimeMs: 1, size: 11))),
    );
    expect(
      lrcReadKey(a),
      isNot(lrcReadKey(const LrcStat(path: '/m/b.lrc', mtimeMs: 1, size: 10))),
    );
  });
}
