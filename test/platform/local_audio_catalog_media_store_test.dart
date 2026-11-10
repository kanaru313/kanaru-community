import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/media_store/media_store_audio_catalog.dart';
import 'package:kanaru/src/platform/data/media_store/media_store_channel_client.dart';
import 'package:kanaru/src/platform/data/media_store/media_store_like_pattern.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';

const _music = '/storage/emulated/0/Music';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(MediaStoreChannelClient.channelName);

  late List<MethodCall> calls;
  late Map<String, Object? Function(MethodCall)> handlers;

  setUp(() {
    calls = [];
    handlers = {'primaryRoot': (_) => '/storage/emulated/0'};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final h = handlers[call.method];
      if (h == null) throw MissingPluginException();
      return h(call);
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  MediaStoreAudioCatalog catalog({
    bool exists = true,
    Future<String> Function(String)? resolve,
    int firstRunMin = 30000,
    Duration timeout = const Duration(seconds: 5),
  }) => MediaStoreAudioCatalog(
    MediaStoreChannelClient(),
    rootExists: (_) async => exists,
    resolveLinks: resolve,
    firstRunMinDurationMs: firstRunMin,
    timeout: timeout,
  );

  Map<String, Object?> audioReply(List<(String, int, int, int)> rows) => {
    'paths': [for (final r in rows) r.$1],
    'sizes': Int64List.fromList([for (final r in rows) r.$2]),
    'emptyPaths': 0,
    'modifiedSec': Int64List.fromList([for (final r in rows) r.$3]),
    'durationsMs': Int64List.fromList([for (final r in rows) r.$4]),
  };

  Map<String, Object?> lyricsReply(List<String> paths) => {
    'paths': paths,
    'sizes': Int64List.fromList([for (final _ in paths) 10]),
    'modifiedSec': Int64List.fromList([for (final _ in paths) 5]),
  };

  group('mediaStoreLikePattern', () {
    test('escapes %, _ and backslash', () {
      expect(mediaStoreLikePattern(r'/s/100%_mix\x'), r'/s/100\%\_mix\\x/%');
    });

    test('appends a suffix after the wildcard', () {
      expect(mediaStoreLikePattern('/s/a', suffix: '.lrc'), '/s/a/%.lrc');
    });
  });

  group('listAudio', () {
    test('decodes rows, converts seconds to ms, maps -1 to null', () async {
      handlers['listAudio'] = (_) => audioReply([
        ('$_music/a.flac', 100, 7, 200000),
        ('$_music/b.mp3', 50, 8, -1),
      ]);
      handlers['listLyrics'] = (_) => lyricsReply(['$_music/a.LRC']);
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.reachable, isTrue);
      expect(listing.audio, hasLength(2));
      expect(listing.audio[0].mtimeMs, 7000);
      expect(listing.audio[0].sizeBytes, 100);
      expect(listing.audio[0].durationMs, 200000);
      expect(listing.audio[1].durationMs, isNull);
      expect(listing.lyrics.single.path, '$_music/a.LRC');
      expect(listing.lyrics.single.mtimeMs, 5000);
      final args = calls.first.arguments as Map;
      expect(args['likePattern'], '$_music/%');
      expect(args['root'], _music);
      expect((calls[1].arguments as Map)['likePattern'], '$_music/%.lrc');
    });

    test('rows outside the root are dropped and logged with samples', () async {
      handlers['listAudio'] = (_) => audioReply([
        ('/storage/emulated/0/Library/x.flac', 1, 1, 1000),
        ('/storage/emulated/0/Music Videos/y.mp3', 1, 1, 1000),
        ('/storage/emulated/0/Other/z.mp3', 1, 1, 1000),
        ('/storage/emulated/0/Other/w.mp3', 1, 1, 1000),
        ('$_music/ok.mp3', 1, 1, 1000),
      ]);
      handlers['listLyrics'] = (_) => lyricsReply(['/storage/emulated/0/Other/a.lrc']);
      final records = <LogRecord>[];
      final sub = Logger('platform.media_store').onRecord.listen(records.add);
      addTearDown(sub.cancel);
      Logger.root.level = Level.ALL;
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.audio.map((f) => f.path), ['$_music/ok.mp3']);
      final line = records.map((r) => r.message).singleWhere(
        (m) => m.contains('outside the root'),
      );
      expect(line, contains('5 MediaStore rows'));
      expect(line, contains('Library/x.flac'));
      expect(line, isNot(contains('w.mp3')), reason: 'only 3 samples');
    });

    test('case differences follow SQLite LIKE: ASCII folds, others do not',
        () async {
      handlers['listAudio'] = (_) => audioReply([
        ('/storage/emulated/0/music/z.mp3', 1, 1, 1000),
        ('/storage/emulated/0/NHẠC ĐỎ/a.mp3', 1, 1, 1000),
      ]);
      handlers['listLyrics'] = (_) => lyricsReply([]);
      final asciiRoot = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(asciiRoot.audio, hasLength(1));
      final vi = await catalog().listAudio(
        root: '/storage/emulated/0/Nhạc Đỏ',
        excludedKeys: const {},
      );
      expect(vi.audio, isEmpty);
    });

    test('lyrics under a root with a non-ASCII capital keep the root spelling',
        () async {
      const root = '/storage/emulated/0/Nhạc Đỏ';
      handlers['listAudio'] = (_) => audioReply([]);
      handlers['listLyrics'] = (_) => lyricsReply(['$root/a.LRC']);
      final listing = await catalog().listAudio(
        root: root,
        excludedKeys: const {},
      );
      expect((calls[1].arguments as Map)['likePattern'], '$root/%.lrc');
      expect(listing.lyrics.single.path, '$root/a.LRC');
    });

    test('the Android app-data tree is skipped by absolute path under any root',
        () async {
      handlers['listAudio'] = (_) => audioReply([
        ('/storage/emulated/0/Android/media/wa/v.mp3', 1, 1, 1000),
        ('/storage/emulated/0/Music/Android/b.mp3', 1, 1, 1000),
        ('/storage/emulated/0/Music/ok.mp3', 1, 1, 1000),
      ]);
      handlers['listLyrics'] = (_) =>
          lyricsReply(['/storage/emulated/0/Android/media/wa/v.lrc']);
      final wide = await catalog().listAudio(
        root: '/storage/emulated/0',
        excludedKeys: const {},
      );
      expect(wide.audio.map((f) => f.path), [
        '/storage/emulated/0/Music/Android/b.mp3',
        '/storage/emulated/0/Music/ok.mp3',
      ]);
      expect(wide.skippedOut, 1);
      expect(wide.lyrics, isEmpty);
      // A user folder called Android below Music is not app data.
      final music = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(music.audio.map((f) => f.path), [
        '$_music/Android/b.mp3',
        '$_music/ok.mp3',
      ]);
      expect(music.skippedOut, 0);
    });

    test('a root the user picked inside Android/ is listed as chosen', () async {
      const root = '/storage/emulated/0/Android/media/Podcasts';
      handlers['listAudio'] = (_) => audioReply([('$root/e1.mp3', 1, 1, 1000)]);
      handlers['listLyrics'] = (_) => lyricsReply([]);
      final listing = await catalog().listAudio(
        root: root,
        excludedKeys: const {},
      );
      expect(listing.audio, hasLength(1));
      expect(listing.skippedOut, 0);
    });

    test('no lyrics query starts after the audio query timed out', () async {
      handlers['listAudio'] = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return audioReply([]);
      };
      handlers['listLyrics'] = (_) => lyricsReply([]);
      final listing = await catalog(
        timeout: const Duration(milliseconds: 30),
      ).listAudio(root: _music, excludedKeys: const {});
      expect(listing.unreachableReason, UnreachableReason.timedOut);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(calls.map((c) => c.method), ['listAudio']);
    });

    test('a reply with a wrong element type is an io failure, not a crash',
        () async {
      handlers['listAudio'] = (_) => {
        ...audioReply([]),
        'paths': <Object>[1, 2],
      };
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.unreachableReason, UnreachableReason.failed);
    });

    test('parallel lists of different length are an io failure', () async {
      handlers['listAudio'] = (_) => {
        ...audioReply([('$_music/a.mp3', 1, 1, 1000)]),
        'sizes': <int>[],
      };
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.unreachableReason, UnreachableReason.failed);
    });

    test('lyrics lists of different length are an io failure', () async {
      handlers['listAudio'] = (_) => audioReply([('$_music/a.mp3', 1, 1, 1000)]);
      handlers['listLyrics'] = (_) => {
        ...lyricsReply(['$_music/a.lrc']),
        'modifiedSec': <int>[],
      };
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.unreachableReason, UnreachableReason.failed);
    });

    test('rows with an empty path are counted in skippedOut', () async {
      handlers['listAudio'] = (_) => {
        ...audioReply([('$_music/a.mp3', 1, 1, 1000)]),
        'emptyPaths': 4,
      };
      handlers['listLyrics'] = (_) => lyricsReply([]);
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.skippedOut, 4);
    });

    test('a folder name with % and _ is matched through the pattern', () async {
      const root = '/storage/emulated/0/100%_mix';
      handlers['listAudio'] = (_) => audioReply([('$root/a.mp3', 1, 1, 1000)]);
      handlers['listLyrics'] = (_) => lyricsReply([]);
      final listing = await catalog().listAudio(
        root: root,
        excludedKeys: const {},
      );
      expect(listing.audio, hasLength(1));
      expect((calls.first.arguments as Map)['likePattern'], r'/storage/emulated/0/100\%\_mix/%');
    });

    test('dot-folders and @eaDir rows are dropped and counted', () async {
      handlers['listAudio'] = (_) => audioReply([
        ('$_music/.thumbs/a.mp3', 1, 1, 1000),
        ('$_music/@eaDir/b.mp3', 1, 1, 1000),
        ('$_music/Album/.hidden.mp3', 1, 1, 1000),
        ('$_music/Album/c.mp3', 1, 1, 1000),
      ]);
      handlers['listLyrics'] = (_) => lyricsReply(['$_music/.thumbs/a.lrc']);
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.audio.map((f) => f.path), ['$_music/Album/c.mp3']);
      expect(listing.skippedOut, 3);
      expect(listing.lyrics, isEmpty);
    });

    test('excluded keys drop rows and are counted, siblings stay', () async {
      handlers['listAudio'] = (_) => audioReply([
        ('$_music/A/x.mp3', 1, 1, 1000),
        ('$_music/A/deep/y.mp3', 1, 1, 1000),
        ('$_music/A B/z.mp3', 1, 1, 1000),
      ]);
      handlers['listLyrics'] = (_) => lyricsReply(['$_music/A/x.lrc']);
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: {'A'},
      );
      expect(listing.audio.map((f) => f.path), ['$_music/A B/z.mp3']);
      expect(listing.excludedOut, 2);
      expect(listing.lyrics, isEmpty);
    });

    test('short rows are dropped and counted only with a pre-filter', () async {
      handlers['listAudio'] = (_) => audioReply([
        ('$_music/short.mp3', 1, 1, 10000),
        ('$_music/long.mp3', 1, 1, 100000),
        ('$_music/unknown.mp3', 1, 1, -1),
      ]);
      handlers['listLyrics'] = (_) => lyricsReply([]);
      var listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
        skipShorterThanMs: 30000,
      );
      expect(listing.shortOut, 1);
      expect(listing.audio, hasLength(2));
      expect(listing.filteredOut, 1);
      listing = await catalog().listAudio(root: _music, excludedKeys: const {});
      expect(listing.shortOut, 0);
      expect(listing.audio, hasLength(3));
    });

    test('a missing root is unreachable without a query', () async {
      final listing = await catalog(exists: false).listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.reachable, isFalse);
      expect(calls, isEmpty);
    });

    test('a permission error is reported as unreachable(permission)', () async {
      handlers['listAudio'] = (_) =>
          throw PlatformException(code: 'permission', message: 'denied');
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.reachable, isFalse);
      expect(listing.unreachableReason, UnreachableReason.permission);
    });

    test('other channel errors become unreachable(failed)', () async {
      handlers['listAudio'] = (_) => throw PlatformException(code: 'io');
      final listing = await catalog().listAudio(
        root: _music,
        excludedKeys: const {},
      );
      expect(listing.unreachableReason, UnreachableReason.failed);
    });

    test('a query past the time limit is unreachable(timedOut)', () async {
      handlers['listAudio'] = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return audioReply([]);
      };
      final listing = await catalog(
        timeout: const Duration(milliseconds: 50),
      ).listAudio(root: _music, excludedKeys: const {});
      expect(listing.unreachableReason, UnreachableReason.timedOut);
    });
  });

  group('folders and suggestion', () {
    void folders(Map<String, int> counts) {
      handlers['audioFolders'] = (_) => {
        'paths': counts.keys.toList(),
        'counts': Int32List.fromList(counts.values.toList()),
      };
    }

    test('audioFolders drops dot and junk folders and sorts', () async {
      folders({
        '$_music/Library': 5,
        '$_music/.thumbs': 9,
        '/storage/emulated/0/@eaDir/x': 1,
        '/storage/emulated/0/Download': 2,
      });
      final result = await catalog().audioFolders();
      expect(result.map((f) => f.path), [
        '/storage/emulated/0/Download',
        '$_music/Library',
      ]);
      expect(result.last.audioCount, 5);
      final args = calls.single.arguments as Map;
      expect(args['minDurationMs'], 30000);
      expect(args['extensions'], containsAll(['mp3', 'flac', 'opus']));
      expect(args['extensions'], isNot(contains('amr')));
    });

    test('a zero first-run minimum turns the duration filter off', () async {
      folders({'$_music/A': 1});
      await catalog(firstRunMin: 0).audioFolders();
      expect((calls.single.arguments as Map)['minDurationMs'], 0);
    });

    test('audioFolders drops the app-data subtree of a volume', () async {
      folders({
        '/storage/emulated/0/Android/media/wa': 4,
        '/storage/1234-ABCD/Android/media/x': 2,
        '$_music/Android': 1,
        '/storage/1234-ABCD/Music': 3,
      });
      final result = await catalog().audioFolders();
      expect(result.map((f) => f.path), [
        '/storage/1234-ABCD/Music',
        '$_music/Android',
      ]);
    });

    test('a failing folder query gives an empty list, not an exception',
        () async {
      handlers['audioFolders'] = (_) => throw PlatformException(code: 'io');
      expect(await catalog().audioFolders(), isEmpty);
      expect(await catalog().suggestedMusicFolder(), isNull);
    });

    test('the suggestion follows the user primary root', () async {
      handlers['primaryRoot'] = (_) => '/storage/emulated/10';
      folders({'/storage/emulated/10/Music/Library': 3});
      expect(await catalog().suggestedMusicFolder(), '/storage/emulated/10/Music');
    });

    test('Music is suggested when audio lies in its subtree', () async {
      folders({'$_music/Library/a': 3});
      expect(await catalog().suggestedMusicFolder(), _music);
    });

    test('no suggestion without audio under Music', () async {
      folders({'/storage/emulated/0/Download': 3, '$_music Videos': 1});
      expect(await catalog().suggestedMusicFolder(), isNull);
    });

    test('canonicalize only normalises roots that came from the index', () async {
      folders({'$_music/Library': 3});
      final c = catalog();
      await c.audioFolders();
      expect(await c.canonicalize('$_music/Library/'), '$_music/Library');
    });

    test('canonicalize maps /sdcard to the primary root, then resolves links',
        () async {
      final resolved = <String>[];
      final c = catalog(
        resolve: (path) async {
          resolved.add(path);
          return path.replaceFirst('/storage/emulated/0', '/data/media/0');
        },
      );
      expect(await c.canonicalize('/sdcard/Music/'), '/data/media/0/Music');
      expect(resolved, ['/storage/emulated/0/Music']);
    });

    test('canonicalize keeps the mapped path when resolving fails', () async {
      final c = catalog(
        resolve: (_) async => throw const FileSystemException('blocked'),
      );
      expect(
        await c.canonicalize('/storage/self/primary/Music'),
        '/storage/emulated/0/Music',
      );
    });

    test('the catalog reports the sheet choice and refuses the dialog', () {
      final c = catalog();
      expect(c.folderChoice, FolderChoice.mediaStoreSheet);
      expect(() => c.pickFolder(), throwsUnsupportedError);
    });
  });

  test('sdkInt is cached after the first answer', () async {
    handlers['sdkInt'] = (_) => 34;
    final client = MediaStoreChannelClient();
    expect(await client.sdkInt(), 34);
    expect(await client.sdkInt(), 34);
    expect(calls, hasLength(1));
  });
}
