import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/waveform_cache.dart';
import 'package:kanaru/src/playback/data/waveform_repository.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';
import 'package:kanaru/src/rust/api/error.dart';
import 'package:path/path.dart' as p;

NativeError _error(NativeErrorKind kind, {bool transient = false}) =>
    NativeError(kind: kind, detail: 'x', transient: transient);

/// A fake native function: counts starts, answers from [answer].
class _Native {
  _Native(this.answer);

  Future<Ready> Function() answer;
  int starts = 0;
  int cancels = 0;

  WaveformRun call(String path) {
    starts++;
    return (result: answer(), cancel: () => cancels++);
  }
}

Ready _ready([int n = 3]) =>
    Ready(Uint8List.fromList(List.generate(n, (i) => i * 10)), 4000);

void main() {
  late Directory tmp;
  late File song;
  late WaveformCache cache;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kanaru-waveform-test');
    song = File(p.join(tmp.path, 'song.flac'))..writeAsBytesSync([1, 2, 3]);
    cache = WaveformCache(Directory(p.join(tmp.path, 'cache', 'v1')));
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  WaveformRepository repo(
    _Native native, {
    Duration timeout = const Duration(seconds: 20),
  }) => WaveformRepository(cache: cache, start: native.call, timeout: timeout);

  Future<WaveformResult> load(WaveformRepository r) => r.load(song.path).result;

  test('decodes once, then the cache answers', () async {
    final native = _Native(() async => _ready());
    final r = repo(native);
    final first = await load(r);
    expect(first, isA<Ready>());
    final second = await load(r);
    expect(native.starts, 1);
    expect((second as Ready).levels, (first as Ready).levels);
    expect(second.durationMs, 4000);
    expect(
      cache.dir.listSync().whereType<File>().map((f) => p.extension(f.path)),
      ['.kwf'],
    );
  });

  test('peek reads the cache without decoding', () async {
    final native = _Native(() async => _ready());
    final r = repo(native);
    expect(await r.peek(song.path), isNull);
    await load(r);
    expect(await r.peek(song.path), isA<Ready>());
    expect(native.starts, 1);
  });

  for (final kind in [
    NativeErrorKind.unsupported,
    NativeErrorKind.corrupt,
    NativeErrorKind.tooLarge,
    NativeErrorKind.panic,
  ]) {
    test('${kind.name} is cached as a negative', () async {
      final native = _Native(() => Future.error(_error(kind)));
      final r = repo(native);
      expect(await load(r), isA<NoWaveform>());
      expect(await load(r), isA<NoWaveform>());
      expect(native.starts, 1);
    });
  }

  for (final e in [
    _error(NativeErrorKind.cancelled, transient: true),
    _error(NativeErrorKind.io, transient: true),
    _error(NativeErrorKind.io),
    _error(NativeErrorKind.notFound),
    _error(NativeErrorKind.permissionDenied),
  ]) {
    test(
      '${e.kind.name} (transient: ${e.transient}) is never cached',
      () async {
        final native = _Native(() => Future.error(e));
        final r = repo(native);
        expect(await load(r), isA<RetryLater>());
        expect(await load(r), isA<RetryLater>());
        expect(native.starts, 2);
        expect(cache.dir.existsSync(), isFalse);
      },
    );
  }

  test('a track under 10 ms is a cached negative', () async {
    final native = _Native(() async => Ready(Uint8List(0), 5));
    final r = repo(native);
    expect(await load(r), isA<NoWaveform>());
    expect(await load(r), isA<NoWaveform>());
    expect(native.starts, 1);
  });

  test('a job over the timeout is cancelled and retried later', () async {
    final never = Completer<Ready>();
    final native = _Native(() => never.future);
    final r = repo(native, timeout: const Duration(milliseconds: 30));
    expect(await load(r), isA<RetryLater>());
    expect(native.cancels, 1);
    expect(cache.dir.existsSync(), isFalse);
  });

  test('cancel() reaches the native job and ends in RetryLater', () async {
    final pending = Completer<Ready>();
    late _Native native;
    native = _Native(() => pending.future);
    final job = repo(native).load(song.path);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(native.starts, 1);
    job.cancel();
    expect(native.cancels, 1);
    pending.completeError(_error(NativeErrorKind.cancelled, transient: true));
    expect(await job.result, isA<RetryLater>());
  });

  test('a load cancelled before it starts never calls native', () async {
    final native = _Native(() async => _ready());
    final job = repo(native).load(song.path);
    job.cancel();
    expect(await job.result, isA<RetryLater>());
    expect(native.starts, 0);
  });

  test('a file that changes is decoded again', () async {
    final native = _Native(() async => _ready());
    final r = repo(native);
    await load(r);
    song.writeAsBytesSync([1, 2, 3, 4]);
    await load(r);
    expect(native.starts, 2);
  });

  test('a missing file is retried later and never decoded', () async {
    final native = _Native(() async => _ready());
    final r = repo(native);
    final result = await r.load(p.join(tmp.path, 'gone.flac')).result;
    expect(result, isA<RetryLater>());
    expect(native.starts, 0);
  });

  test('a native library that cannot start is retried later', () async {
    final r = WaveformRepository(
      cache: cache,
      start: (_) => throw StateError('library not loaded'),
    );
    expect(await load(r), isA<RetryLater>());
  });

  test('a damaged cache file is ignored and rewritten', () async {
    final native = _Native(() async => _ready());
    final r = repo(native);
    await load(r);
    final file = cache.dir.listSync().whereType<File>().single;
    file.writeAsBytesSync([9, 9, 9]);
    expect(await load(r), isA<Ready>());
    expect(native.starts, 2);
    expect(await load(r), isA<Ready>());
    expect(native.starts, 2);
  });

  test('a cache hit touches the file', () async {
    final native = _Native(() async => _ready());
    final r = repo(native);
    await load(r);
    final file = cache.dir.listSync().whereType<File>().single;
    final old = DateTime.now().subtract(const Duration(days: 30));
    await file.setLastModified(old);
    await load(r);
    expect(file.lastModifiedSync().isAfter(old), isTrue);
  });

  group('sweep', () {
    Future<List<String>> fill(WaveformCache c, int count) async {
      final names = <String>[];
      final base = DateTime(2026, 1, 1);
      await c.dir.create(recursive: true);
      for (var i = 0; i < count; i++) {
        final f = File(p.join(c.dir.path, 'key$i.kwf'))..writeAsBytesSync([i]);
        await f.setLastModified(base.add(Duration(minutes: i)));
        names.add(p.basename(f.path));
      }
      return names;
    }

    test('does nothing up to the maximum', () async {
      final c = WaveformCache(cache.dir, maxFiles: 5, keepFiles: 3);
      await fill(c, 5);
      expect(await c.sweep(), 0);
      expect(c.dir.listSync().length, 5);
    });

    test(
      'over the maximum deletes the oldest down to the kept count',
      () async {
        final c = WaveformCache(cache.dir, maxFiles: 5, keepFiles: 3);
        await fill(c, 6);
        expect(await c.sweep(), 3);
        final left = c.dir.listSync().map((e) => p.basename(e.path)).toSet();
        expect(left, {'key3.kwf', 'key4.kwf', 'key5.kwf'});
      },
    );

    test('a missing folder is fine', () async {
      expect(await cache.sweep(), 0);
    });

    test('runs once per repository, at the first load', () async {
      final c = WaveformCache(cache.dir, maxFiles: 2, keepFiles: 1);
      await fill(c, 4);
      final native = _Native(() async => _ready());
      final r = WaveformRepository(cache: c, start: native.call);
      await load(r);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // 4 old files swept to 1, plus the newly written one.
      expect(c.dir.listSync().whereType<File>().length, lessThanOrEqualTo(2));
    });
  });

  group('one native job at a time', () {
    test('a job that never settles keeps the next one from starting', () async {
      final never = Completer<Ready>();
      final native = _Native(() => never.future);
      final r = repo(native, timeout: const Duration(milliseconds: 40));
      final other = File(p.join(tmp.path, 'other.flac'))..writeAsBytesSync([9]);
      expect(await load(r), isA<RetryLater>());
      expect(native.cancels, 1);
      // The first job was cancelled but never ended: no second native call.
      expect(await r.load(other.path).result, isA<RetryLater>());
      expect(native.starts, 1);
    });

    test('the next job starts once the previous one ended', () async {
      final first = Completer<Ready>();
      var calls = 0;
      final native = _Native(
        () => calls++ == 0 ? first.future : Future.value(_ready()),
      );
      final r = repo(native);
      final other = File(p.join(tmp.path, 'other.flac'))..writeAsBytesSync([9]);
      final a = r.load(song.path);
      final b = r.load(other.path).result;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(native.starts, 1);
      first.complete(_ready(4));
      expect(await a.result, isA<Ready>());
      expect(await b, isA<Ready>());
      expect(native.starts, 2);
    });

    test('cancelling a load that waits for the native job frees it', () async {
      final never = Completer<Ready>();
      final native = _Native(() => never.future);
      final r = repo(native);
      final other = File(p.join(tmp.path, 'other.flac'))..writeAsBytesSync([9]);
      r.load(song.path);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final waiting = r.load(other.path);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      waiting.cancel();
      expect(await waiting.result, isA<RetryLater>());
      expect(native.starts, 1);
    });
  });

  group('timeouts', () {
    test('a bigger file gets more time, up to a cap', () {
      final r = WaveformRepository(
        cache: cache,
        start: (_) => throw StateError('unused'),
        bytesPerSecond: 1000,
      );
      expect(r.timeoutFor(0), const Duration(seconds: 20));
      expect(r.timeoutFor(10000), const Duration(seconds: 30));
      expect(r.timeoutFor(1 << 40), const Duration(seconds: 55));
    });

    test('two timeouts in a row cache a negative', () async {
      final pending = <Completer<Ready>>[];
      final native = _Native(() {
        final c = Completer<Ready>();
        pending.add(c);
        return c.future;
      });
      final r = repo(native, timeout: const Duration(milliseconds: 30));
      expect(await load(r), isA<RetryLater>());
      pending.last.completeError(
        _error(NativeErrorKind.cancelled, transient: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(await load(r), isA<NoWaveform>());
      pending.last.completeError(
        _error(NativeErrorKind.cancelled, transient: true),
      );
      expect(await load(r), isA<NoWaveform>());
      expect(native.starts, 2);
    });

    test('a native timeout counts as a strike like a Dart one', () async {
      final native = _Native(
        () => Future.error(_error(NativeErrorKind.timeout, transient: true)),
      );
      final r = repo(native);
      expect(await load(r), isA<RetryLater>());
      expect(await load(r), isA<NoWaveform>());
      expect(await load(r), isA<NoWaveform>());
      expect(native.starts, 2);
    });

    test('a negative from timeouts expires after a week', () async {
      var now = DateTime(2026, 11, 10);
      final c = WaveformCache(cache.dir, now: () => now);
      final native = _Native(
        () => Future.error(_error(NativeErrorKind.timeout, transient: true)),
      );
      final r = WaveformRepository(cache: c, start: native.call);
      await load(r);
      expect(await load(r), isA<NoWaveform>());
      now = now.add(const Duration(days: 6));
      expect(await load(r), isA<NoWaveform>());
      expect(native.starts, 2);
      now = now.add(const Duration(days: 2));
      expect(await load(r), isA<RetryLater>());
      expect(native.starts, 3);
    });

    test('a permanent negative never expires', () async {
      var now = DateTime(2026, 11, 10);
      final c = WaveformCache(cache.dir, now: () => now);
      final native = _Native(
        () => Future.error(_error(NativeErrorKind.corrupt)),
      );
      final r = WaveformRepository(cache: c, start: native.call);
      await load(r);
      now = now.add(const Duration(days: 400));
      expect(await load(r), isA<NoWaveform>());
      expect(native.starts, 1);
    });

    test('a success between timeouts resets the count', () async {
      var step = 0;
      final pending = <Completer<Ready>>[];
      final native = _Native(() {
        if (step++ == 1) return Future.value(_ready());
        final c = Completer<Ready>();
        pending.add(c);
        return c.future;
      });
      final r = repo(native, timeout: const Duration(milliseconds: 30));
      expect(await load(r), isA<RetryLater>());
      pending.single.completeError(
        _error(NativeErrorKind.cancelled, transient: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(await load(r), isA<Ready>());
    });
  });

  test('stale temporary files are swept, fresh ones are kept', () async {
    final c = WaveformCache(cache.dir, maxFiles: 100, keepFiles: 50);
    await cache.dir.create(recursive: true);
    final stale = File(p.join(cache.dir.path, 'a.kwf.tmp0'))
      ..writeAsBytesSync([1]);
    final fresh = File(p.join(cache.dir.path, 'b.kwf.tmp1'))
      ..writeAsBytesSync([1]);
    await stale.setLastModified(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    await c.sweep();
    expect(stale.existsSync(), isFalse);
    expect(fresh.existsSync(), isTrue);
  });

  test('the key changes with path, size and mtime only', () {
    final a = waveformCacheKey('/a.flac', 10, 5);
    expect(waveformCacheKey('/a.flac', 10, 5), a);
    expect(waveformCacheKey('/b.flac', 10, 5), isNot(a));
    expect(waveformCacheKey('/a.flac', 11, 5), isNot(a));
    expect(waveformCacheKey('/a.flac', 10, 6), isNot(a));
    expect(a.length, 40);
  });
}
