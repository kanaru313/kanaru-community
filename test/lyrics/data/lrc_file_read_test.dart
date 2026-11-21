import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/lrc_file_read.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_text_decoder.dart';

/// Real files in a temp folder; these are plain tests (no FakeAsync).
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('lrc_read_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  String path(String name) => '${dir.path}/$name';

  /// Stat then read, as the loader does.
  Future<LrcFile?> read(
    String p, {
    Duration timeout = lrcReadTimeout,
    LrcBytesReader readBytes = readFileBytes,
  }) async {
    final stat = await statLrcFile(p);
    if (stat == null) return null;
    return readLrcFile(stat, timeout: timeout, readBytes: readBytes);
  }

  test('reads a UTF-8 file with its stat', () async {
    File(path('a.lrc')).writeAsBytesSync(utf8.encode('[00:01.00]Lời'));
    final file = (await read(path('a.lrc')))!;
    expect(decodeLyricsBytes(file.bytes), '[00:01.00]Lời');
    expect(file.stat.path, path('a.lrc'));
    expect(file.stat.size, file.bytes.length);
    expect(file.stat.mtimeMs, greaterThan(0));
  });

  test('reads UTF-16 and Latin-1 bytes unchanged for the decoder', () async {
    final utf16 = <int>[0xFF, 0xFE];
    for (final u in 'hé'.codeUnits) {
      utf16.addAll([u & 0xFF, u >> 8]);
    }
    File(path('b.lrc')).writeAsBytesSync(utf16);
    File(path('c.lrc')).writeAsBytesSync([0x43, 0x61, 0x66, 0xE9]);
    expect(decodeLyricsBytes((await read(path('b.lrc')))!.bytes), 'hé');
    expect(decodeLyricsBytes((await read(path('c.lrc')))!.bytes), 'Café');
  });

  test('missing file and a folder are null', () async {
    expect(await read(path('nope.lrc')), isNull);
    Directory(path('dir.lrc')).createSync();
    expect(await read(path('dir.lrc')), isNull);
    expect(await statLrcFile(path('dir.lrc')), isNull);
  });

  test('a FIFO is never opened', () async {
    if (!Platform.isLinux) return;
    final r = await Process.run('mkfifo', [path('f.lrc')]);
    if (r.exitCode != 0) return;
    final started = Stopwatch()..start();
    expect(await read(path('f.lrc')), isNull);
    expect(await statLrcFile(path('f.lrc')), isNull);
    expect(started.elapsedMilliseconds, lessThan(2000));
  });

  test('exactly the cap is read, one byte more is refused', () async {
    File(path('ok.lrc')).writeAsBytesSync(Uint8List(lrcMaxBytes));
    File(path('big.lrc')).writeAsBytesSync(Uint8List(lrcMaxBytes + 1));
    expect((await read(path('ok.lrc')))!.bytes, hasLength(lrcMaxBytes));
    expect(await read(path('big.lrc')), isNull);
    expect(await statLrcFile(path('big.lrc')), isNull);
  });

  test('a file that grows past the cap after the stat is refused', () async {
    File(path('g.lrc')).writeAsBytesSync([1, 2, 3]);
    final file = await read(
      path('g.lrc'),
      readBytes: (p, max) async => Uint8List(max + 1),
    );
    expect(file, isNull);
  });

  test('an unreadable file is null, not a failure', () async {
    if (Platform.isWindows) return;
    final f = File(path('p.lrc'))..writeAsBytesSync([65]);
    await Process.run('chmod', ['000', f.path]);
    addTearDown(() => Process.run('chmod', ['644', f.path]));
    if (await _canRead(f)) return; // running as root
    expect(await read(f.path), isNull);
  });

  test('a read that stalls is a transient failure after the timeout', () async {
    File(path('s.lrc')).writeAsBytesSync([65]);
    final never = Completer<Uint8List>();
    await expectLater(
      read(
        path('s.lrc'),
        timeout: const Duration(milliseconds: 50),
        readBytes: (p, max) => never.future,
      ),
      throwsA(
        isA<LyricsReadFailure>()
            .having((f) => f.transient, 'transient', isTrue)
            .having((f) => f.kind, 'kind', 'timeout'),
      ),
    );
  });

  test('another I/O error is a transient failure', () async {
    File(path('e.lrc')).writeAsBytesSync([65]);
    await expectLater(
      read(
        path('e.lrc'),
        readBytes: (p, max) => throw const FileSystemException('disk gone'),
      ),
      throwsA(isA<LyricsReadFailure>().having((f) => f.transient, 't', isTrue)),
    );
  });

  test('statLrcFile reports path, size and mtime of a regular file', () async {
    File(path('t.lrc')).writeAsBytesSync([1, 2, 3, 4]);
    final stat = (await statLrcFile(path('t.lrc')))!;
    expect(stat.size, 4);
    expect(stat.path, path('t.lrc'));
  });

  group('failure mapping', () {
    FileSystemException err(int code) =>
        FileSystemException('x', 'p', OSError('', code));

    test('ENOENT is notFound, permanent', () {
      final f = lrcFailureOf(err(2));
      expect((f.kind, f.transient), ('notFound', false));
    });

    test('EACCES and EPERM are permanent', () {
      for (final code in [13, 1]) {
        final f = lrcFailureOf(err(code));
        expect(
          (f.kind, f.transient),
          ('permissionDenied', false),
          reason: '$code',
        );
      }
    });

    test('EIO and anything else are transient', () {
      if (Platform.isWindows) return;
      for (final code in [5, 110, 116, 19, 0]) {
        expect(lrcFailureOf(err(code)).transient, isTrue, reason: '$code');
      }
      expect(lrcFailureOf(const FileSystemException('x')).transient, isTrue);
    });

    test('a read that fails with EIO is a transient failure', () async {
      File(path('i.lrc')).writeAsBytesSync([65]);
      await expectLater(
        read(path('i.lrc'), readBytes: (p, m) => throw err(5)),
        throwsA(
          isA<LyricsReadFailure>().having((f) => f.transient, 't', isTrue),
        ),
      );
    });

    test('a read that fails with EACCES is null', () async {
      File(path('j.lrc')).writeAsBytesSync([65]);
      expect(
        await read(path('j.lrc'), readBytes: (p, m) => throw err(13)),
        isNull,
      );
    });
  });

  group('PathFlights', () {
    test('callers of one path share the running call until it ends', () async {
      final flights = PathFlights<int>();
      final gate = Completer<int>();
      var starts = 0;
      final a = flights.join('p', () {
        starts++;
        return gate.future;
      });
      final b = flights.join('p', () {
        starts++;
        return gate.future;
      });
      expect(starts, 1);
      gate.complete(7);
      expect(await Future.wait([a, b]), [7, 7]);
      await pumpEventQueue();
      expect(await flights.join('p', () async => ++starts), 2);
    });

    test('a failed call is forgotten, other paths are independent', () async {
      final flights = PathFlights<int>();
      await expectLater(
        flights.join('p', () async => throw StateError('x')),
        throwsA(isA<StateError>()),
      );
      await pumpEventQueue();
      expect(await flights.join('p', () async => 1), 1);
      expect(await flights.join('q', () async => 2), 2);
    });
  });
}

Future<bool> _canRead(File f) async {
  try {
    await f.readAsBytes();
    return true;
  } on FileSystemException {
    return false;
  }
}
