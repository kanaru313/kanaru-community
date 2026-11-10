import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/storage/data/local_folder_source.dart';
import 'package:kanaru/src/storage/domain/local_folder_listing.dart';

class _FakeCatalog implements LocalAudioCatalog {
  _FakeCatalog(this.listing);

  AudioListing listing;
  Object? error;
  String? lastRoot;
  Set<String>? lastExcluded;
  int? lastShort;

  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  }) async {
    lastRoot = root;
    lastExcluded = excludedKeys;
    lastShort = skipShorterThanMs;
    if (error != null) throw error!;
    return listing;
  }

  @override
  Future<List<AudioFolderSummary>> audioFolders() async => const [];
  @override
  Future<String?> suggestedMusicFolder() async => null;
  @override
  Future<String> canonicalize(String path) async => path;
  @override
  FolderChoice get folderChoice => FolderChoice.systemDialog;
  @override
  Future<String?> pickFolder({String? initialDirectory}) async => null;
}

LocalAudioFile _audio(String path, {int? durationMs}) => LocalAudioFile(
  path: path,
  sizeBytes: 10,
  mtimeMs: 20,
  durationMs: durationMs,
);

void main() {
  const root = (root: '/music');

  test('toLocator maps paths below the root and rejects the rest', () {
    expect(toLocator('/a/b', '/a/b/c/d.mp3'), 'c/d.mp3');
    expect(toLocator('/a/b/', '/a/b/c.mp3'), 'c.mp3');
    expect(toLocator('/', '/c.mp3'), 'c.mp3');
    expect(toLocator('/a/b', '/a/bc/d.mp3'), isNull);
    expect(toLocator('/a/b', '/a/b'), isNull);
    expect(toLocator('/a/b', '/a/b/'), isNull);
    expect(toLocator('/a/b', '/a/b/../x.mp3'), isNull);
    expect(toLocator('/a/b', '/a/b//x.mp3'), isNull);
    expect(folderKeyOf('c/d.mp3'), 'c');
    expect(folderKeyOf('d.mp3'), '');
    expect(isUnderFolderKey('c/d.mp3', 'c'), isTrue);
    expect(isUnderFolderKey('cc/d.mp3', 'c'), isFalse);
    expect(isUnderFolderKey('d.mp3', ''), isTrue);
  });

  test('maps audio and lyrics to locators and passes the options on', () async {
    final catalog = _FakeCatalog(
      AudioListing(
        audio: [_audio('/music/a/one.mp3', durationMs: 5)],
        lyrics: const [
          LocalSidecarFile(path: '/music/a/one.lrc', sizeBytes: 1, mtimeMs: 2),
          LocalSidecarFile(path: '/music/top.lrc', sizeBytes: 1, mtimeMs: 2),
        ],
      ),
    );
    final listing = await LocalFolderSource(catalog)
        .list(root, excludedKeys: {'x'}, skipShorterThanMs: 30000);
    expect(catalog.lastRoot, '/music');
    expect(catalog.lastExcluded, {'x'});
    expect(catalog.lastShort, 30000);
    expect(listing.files.single.locator, 'a/one.mp3');
    expect(listing.files.single.durationMs, 5);
    expect(listing.lyrics.keys, unorderedEquals(['a', '']));
    expect(listing.lyrics['a']!.single.locator, 'a/one.lrc');
  });

  test(
    'a path outside the root is dropped and counted, never thrown',
    () async {
      final catalog = _FakeCatalog(
        AudioListing(
          audio: [_audio('/music/ok.mp3'), _audio('/sdcard/Library/x.mp3')],
          unstattable: const ['/elsewhere/y.mp3'],
          emptyDirs: const ['/other/dir'],
        ),
      );
      final listing = await LocalFolderSource(catalog).list(root);
      expect(listing.files.map((f) => f.locator), ['ok.mp3']);
      expect(listing.droppedOutsideRoot, 3);
      expect(listing.unstattable, isEmpty);
      expect(listing.uncertainPrefixes, isEmpty);
    },
  );

  test(
    'unreadable and empty dirs become prefixes with a trailing slash',
    () async {
      final catalog = _FakeCatalog(
        const AudioListing(
          unreadableDirs: ['/music/locked'],
          emptyDirs: ['/music/usb/', '/music'],
          unstattable: ['/music/b/dead.mp3'],
        ),
      );
      final listing = await LocalFolderSource(catalog).list(root);
      expect(listing.uncertainPrefixes, ['locked/', 'usb/', '']);
      expect(listing.unstattable, {'b/dead.mp3'});
    },
  );

  test('counts are carried and filteredOut is excluded plus short', () async {
    final catalog = _FakeCatalog(
      const AudioListing(
        excludedOut: 2,
        skippedOut: 7,
        shortOut: 3,
        skippedLinks: 1,
        undecodableNames: 4,
        undecodableSampleDirs: ['/music/x'],
      ),
    );
    final listing = await LocalFolderSource(catalog).list(root);
    expect(listing.filteredOut, 5);
    expect(listing.skippedOut, 7);
    expect(listing.undecodableNames, 4);
    expect(listing.undecodableSampleDirs, ['/music/x']);
    expect(listing.skippedLinks, 1);
  });

  test('an unreachable root keeps its reason', () async {
    final catalog = _FakeCatalog(
      const AudioListing.unreachable(UnreachableReason.timedOut),
    );
    final listing = await LocalFolderSource(catalog).list(root);
    expect(listing.reachable, isFalse);
    expect(listing.unreachableReason, UnreachableReason.timedOut);
  });

  test('a catalog that throws is read as unreachable, not as empty', () async {
    final catalog = _FakeCatalog(const AudioListing())..error = StateError('x');
    final listing = await LocalFolderSource(catalog).list(root);
    expect(listing.reachable, isFalse);
    expect(listing.unreachableReason, UnreachableReason.failed);
  });

  test('an unreadable mount table is warned about once per scan', () async {
    final source = LocalFolderSource(
      _FakeCatalog(const AudioListing()),
      readMounts: () => <String>{},
    );
    final warnings = <LogRecord>[];
    final sub = Logger.root.onRecord
        .where((r) => r.level >= Level.WARNING)
        .listen(warnings.add);
    addTearDown(sub.cancel);

    source.beginScan();
    source.presenceCheck((root: '/a'));
    source.presenceCheck((root: '/b'));
    await Future<void>.delayed(Duration.zero);
    expect(
      warnings.where((r) => r.message.contains('unreadable')),
      hasLength(1),
    );

    source.beginScan();
    source.presenceCheck((root: '/a'));
    await Future<void>.delayed(Duration.zero);
    expect(
      warnings.where((r) => r.message.contains('unreadable')),
      hasLength(2),
    );
  });
}
