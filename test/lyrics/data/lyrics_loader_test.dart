import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_read.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/data/lyrics_loader.dart';
import 'package:kanaru/src/lyrics/data/lyrics_parse_jobs.dart';
import 'package:kanaru/src/lyrics/data/lyrics_read_cache.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../support/fake_local_lyrics_reader.dart';

LyricsRequest _req(int id, {String? lrc, String? revision = 'r1'}) =>
    LyricsRequest(
      trackId: TrackId(id),
      audioPath: '/m/$id.flac',
      trackRevision: revision,
      lrcPath: lrc,
    );

const _transient = LyricsReadFailure(kind: 'timeout', transient: true);
const _permanent = LyricsReadFailure(kind: 'corrupt', transient: false);

void main() {
  late FakeLocalLyricsReader reader;
  late LyricsReadCache cache;
  late int isolateCalls;
  late LyricsLoader loader;

  setUp(() {
    reader = FakeLocalLyricsReader();
    cache = LyricsReadCache();
    isolateCalls = 0;
    loader = LyricsLoader(
      reader,
      cache: cache,
      runner: <R>(computation) async {
        isolateCalls++;
        return computation();
      },
    );
  });

  test('reads tag and .lrc and keeps both sources', () async {
    reader.tags['/m/1.flac'] = const EmbeddedLyrics(text: 'plain tag');
    reader.lrcs['/m/1.lrc'] = '[00:01.00]a';
    final read = await loader.load(_req(1, lrc: '/m/1.lrc'));
    expect(read.tag!.synced, isFalse);
    expect(read.lrc!.synced, isTrue);
    expect(read.incomplete, isFalse);
  });

  test('a cached read is not read again; peek sees it', () async {
    reader.tags['/m/1.flac'] = const EmbeddedLyrics(text: 'x');
    final first = await loader.load(_req(1));
    expect(loader.peek(const TrackId(1)), first);
    await loader.load(_req(1));
    expect(reader.tagReads, hasLength(1));
  });

  test('a new revision or audio path reads again', () async {
    await loader.load(_req(1));
    await loader.load(_req(1, revision: 'r2'));
    expect(reader.tagReads, hasLength(2));
  });

  test('concurrent requests for one key share one read', () async {
    reader.holdTags.add('/m/1.flac');
    final a = loader.load(_req(1));
    final b = loader.load(_req(1));
    await pumpEventQueue();
    reader.releaseTag('/m/1.flac');
    await Future.wait([a, b]);
    expect(reader.tagReads, hasLength(1));
  });

  group('.lrc', () {
    test('a changed stat reads the file again', () async {
      reader.lrcs['/m/1.lrc'] = '[00:01.00]a';
      await loader.load(_req(1, lrc: '/m/1.lrc'));
      await loader.load(_req(1, lrc: '/m/1.lrc'));
      expect(reader.lrcReads, hasLength(1));
      reader.lrcs['/m/1.lrc'] = '[00:01.00]edited';
      reader.lrcMtime['/m/1.lrc'] = 2;
      final read = await loader.load(_req(1, lrc: '/m/1.lrc'));
      expect(reader.lrcReads, hasLength(2));
      expect(read.lrc!.lines.single.text, 'edited');
    });

    test('a new .lrc appearing after a "none" read is found', () async {
      expect((await loader.load(_req(1))).lrc, isNull);
      reader.lrcs['/m/1.lrc'] = '[00:01.00]a';
      expect((await loader.load(_req(1))).lrc, isNotNull);
    });

    test(
      'without a scan locator both spellings are probed, in order',
      () async {
        reader.lrcs['/m/1.LRC'] = '[00:01.00]upper';
        final read = await loader.load(_req(1));
        expect(reader.stats, ['/m/1.lrc', '/m/1.LRC']);
        expect(read.lrc!.lines.single.text, 'upper');
      },
    );

    test('with a locator only that file is looked at', () async {
      reader.lrcs['/m/1.lrc'] = '[00:01.00]probe';
      await loader.load(_req(1, lrc: '/m/other.lrc'));
      expect(reader.stats, ['/m/other.lrc']);
    });
  });

  group('sources are independent', () {
    test(
      'a transient tag failure keeps the .lrc, marks incomplete, not cached',
      () async {
        reader.tagErrors['/m/1.flac'] = _transient;
        reader.lrcs['/m/1.lrc'] = '[00:01.00]a';
        final read = await loader.load(_req(1, lrc: '/m/1.lrc'));
        expect(read.lrc, isNotNull);
        expect(read.tag, isNull);
        expect(read.incomplete, isTrue);
        expect(loader.peek(const TrackId(1)), isNull);
        reader.tagErrors.clear();
        await loader.load(_req(1, lrc: '/m/1.lrc'));
        expect(reader.tagReads, hasLength(2), reason: 're-requested');
      },
    );

    test('a transient .lrc failure keeps the tag, not cached', () async {
      reader.tags['/m/1.flac'] = const EmbeddedLyrics(text: 'tag');
      reader.lrcs['/m/1.lrc'] = '[00:01.00]a';
      reader.lrcErrors['/m/1.lrc'] = _transient;
      final read = await loader.load(_req(1, lrc: '/m/1.lrc'));
      expect(read.tag, isNotNull);
      expect(read.incomplete, isTrue);
      expect(cache.length, 0);
    });

    test('a failing stat is incomplete and the read is not cached', () async {
      reader.statErrors['/m/1.lrc'] = _transient;
      reader.tags['/m/1.flac'] = const EmbeddedLyrics(text: 'tag');
      final read = await loader.load(_req(1, lrc: '/m/1.lrc'));
      expect(read.tag, isNotNull);
      expect(read.incomplete, isTrue);
      expect(cache.length, 0);
    });

    test('a permanent tag failure with no .lrc is a cached "none"', () async {
      reader.tagErrors['/m/1.flac'] = _permanent;
      final read = await loader.load(_req(1));
      expect(read.tag, isNull);
      expect(read.incomplete, isFalse);
      await loader.load(_req(1));
      expect(reader.tagReads, hasLength(1));
    });

    test('an unknown error counts as transient', () async {
      reader.tagErrors['/m/1.flac'] = StateError('ffi not loaded');
      final read = await loader.load(_req(1));
      expect(read.incomplete, isTrue);
      expect(cache.length, 0);
    });
  });

  group('tag queue', () {
    test('newest request first; older waiting ones still run', () async {
      reader.holdTags.add('/m/1.flac');
      reader.tags['/m/2.flac'] = const EmbeddedLyrics(text: 'two');
      reader.tags['/m/3.flac'] = const EmbeddedLyrics(text: 'three');
      final a = loader.load(_req(1));
      await pumpEventQueue();
      final b = loader.load(_req(2));
      final c = loader.load(_req(3));
      await pumpEventQueue();
      reader.releaseTag('/m/1.flac');
      await a;
      expect((await c).tag!.lines.single.text, 'three');
      expect((await b).tag!.lines.single.text, 'two');
      expect(reader.tagReads, ['/m/1.flac', '/m/3.flac', '/m/2.flac']);
    });

    test('a cancelled waiting request is dropped and never read', () async {
      reader.holdTags.add('/m/1.flac');
      final a = loader.load(_req(1));
      await pumpEventQueue();
      final cancel = LoadCancel();
      final b = loader.load(_req(2), cancel: cancel);
      final dropped = expectLater(b, throwsA(isA<LyricsSuperseded>()));
      await pumpEventQueue();
      cancel.cancel();
      await dropped;
      reader.releaseTag('/m/1.flac');
      await a;
      await pumpEventQueue();
      expect(reader.tagReads, ['/m/1.flac']);
      expect(loader.peek(const TrackId(2)), isNull);
    });

    test(
      'a read two requesters share survives one of them cancelling',
      () async {
        reader.holdTags.add('/m/1.flac');
        reader.tags['/m/2.flac'] = const EmbeddedLyrics(text: 'two');
        final a = loader.load(_req(1));
        await pumpEventQueue();
        final first = LoadCancel();
        final second = LoadCancel();
        final x = loader.load(_req(2), cancel: first);
        final y = loader.load(_req(2), cancel: second);
        await pumpEventQueue();
        first.cancel();
        reader.releaseTag('/m/1.flac');
        await a;
        expect((await y).tag, isNotNull);
        expect((await x).tag, isNotNull);
        expect(reader.tagReads.where((p) => p == '/m/2.flac'), hasLength(1));
      },
    );

    test('a request after everyone cancelled starts a fresh read', () async {
      reader.holdTags.add('/m/1.flac');
      reader.tags['/m/2.flac'] = const EmbeddedLyrics(text: 'two');
      final a = loader.load(_req(1));
      await pumpEventQueue();
      final cancel = LoadCancel();
      final dropped = expectLater(
        loader.load(_req(2), cancel: cancel),
        throwsA(isA<LyricsSuperseded>()),
      );
      await pumpEventQueue();
      cancel.cancel();
      await dropped;
      final again = loader.load(_req(2));
      reader.releaseTag('/m/1.flac');
      await a;
      expect((await again).tag, isNotNull);
    });
  });

  test(
    'a reopen after the requester left joins the already running read',
    () async {
      reader.holdTags.add('/m/1.flac');
      final cancel = LoadCancel();
      final first = loader.load(_req(1), cancel: cancel);
      await pumpEventQueue();
      cancel.cancel();
      final again = loader.load(_req(1));
      await pumpEventQueue();
      reader.releaseTag('/m/1.flac');
      await Future.wait([first, again]);
      expect(reader.tagReads, ['/m/1.flac']);
    },
  );

  group('isolate threshold', () {
    final big = 'x' * (lyricsIsolateThreshold + 1);

    test(
      'large .lrc bytes and large tag text are parsed through the runner',
      () async {
        reader.lrcs['/m/1.lrc'] = '[00:01.00]$big';
        reader.tags['/m/1.flac'] = EmbeddedLyrics(text: big);
        await loader.load(_req(1, lrc: '/m/1.lrc'));
        expect(isolateCalls, 2);
      },
    );

    test('small input is parsed inline', () async {
      reader.lrcs['/m/1.lrc'] = '[00:01.00]small';
      reader.tags['/m/1.flac'] = const EmbeddedLyrics(text: 'small');
      await loader.load(_req(1, lrc: '/m/1.lrc'));
      expect(isolateCalls, 0);
    });

    test('SYLT lines are never parsed', () async {
      reader.tags['/m/1.flac'] = const EmbeddedLyrics(
        synced: [LyricLine(Duration(seconds: 1), 'a')],
      );
      final read = await loader.load(_req(1));
      expect(read.tag!.synced, isTrue);
      expect(isolateCalls, 0);
    });

    test('the real isolate parses a large file', () async {
      final real = LyricsLoader(reader);
      reader.lrcs['/m/1.lrc'] = '[00:01.00]$big\n[00:02.00]end';
      final read = await real.load(_req(1, lrc: '/m/1.lrc'));
      expect(read.lrc!.lines, hasLength(2));
    });
  });

  test(
    'a parse that throws is "no lyrics", cached; read failures are not',
    () async {
      var runs = 0;
      final failing = LyricsLoader(
        reader,
        runner: <R>(c) async {
          runs++;
          throw StateError('isolate died');
        },
      );
      reader.tags['/m/1.flac'] = EmbeddedLyrics(
        text: 'x' * (lyricsIsolateThreshold + 1),
      );
      final read = await failing.load(_req(1));
      expect(read.tag, isNull);
      expect(read.incomplete, isFalse);
      await failing.load(_req(1));
      expect(runs, 1, reason: 'cached: the same content is not parsed again');
      expect(reader.tagReads, hasLength(1));
    },
  );

  test('the byte budget evicts older reads', () async {
    final small = LyricsLoader(
      reader,
      cache: LyricsReadCache(maxTextChars: 100),
    );
    for (var i = 1; i <= 3; i++) {
      reader.tags['/m/$i.flac'] = EmbeddedLyrics(text: 'y' * 60);
      await small.load(_req(i));
    }
    expect(small.peek(const TrackId(1)), isNull);
    expect(small.peek(const TrackId(3)), isNotNull);
  });

  test('unreadable tag text does not throw out of load', () async {
    reader.tags['/m/1.flac'] = const EmbeddedLyrics(text: '[ar:x]');
    final read = await loader.load(_req(1));
    expect(read.tag, isNull);
    expect(read.lrc, isNull);
  });

  test('origin of each source is set', () async {
    reader.tags['/m/1.flac'] = const EmbeddedLyrics(text: 'a');
    reader.lrcs['/m/1.lrc'] = 'b';
    final read = await loader.load(_req(1, lrc: '/m/1.lrc'));
    expect(read.tag!.origin, LyricsOrigin.tag);
    expect(read.lrc!.origin, LyricsOrigin.lrc);
  });
}
