import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart' hide CoverColors;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/data/custom_cover_store.dart';
import 'package:kanaru/src/library/data/scan/native_cover_import.dart';
import 'package:kanaru/src/library/domain/scan/native_failure.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/cover_files.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';

import '../database/support/test_db.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => throw UnimplementedError();
  @override
  Directory get configDir => throw UnimplementedError();
}

/// Stands in for the Rust import: the key comes from the bytes, both JPEGs are
/// written again on every call (like the real one), a file that is not
/// `GOOD`-prefixed fails. The real call is covered by the Rust tests of
/// `import_cover_file`; `flutter test` cannot load the native library.
class _FakeImporter implements CoverImporter {
  NativeFailure? forced;

  /// When set, the call waits for it (a stalled source).
  Completer<void>? hang;
  CoverColors? colors = const CoverColors(
    seed: 0xFFAA0000,
    palette: [0xFFAA0000],
  );
  int calls = 0;

  static String keyOf(List<int> bytes) {
    final h = Object.hashAll(bytes).toRadixString(16).padLeft(32, '0');
    return '${h.substring(0, 2)}/${h.substring(0, 32)}';
  }

  @override
  Future<CoverImportResult> import({
    required String path,
    required String outDir,
  }) async {
    calls++;
    await hang?.future;
    final f = forced;
    if (f != null) return CoverImportResult.failed(f);
    final file = File(path);
    if (!file.existsSync()) {
      return const CoverImportResult.failed(
        NativeFailure(kind: 'notFound', transient: false),
      );
    }
    final bytes = file.readAsBytesSync();
    if (bytes.isEmpty || bytes.first != 0x47) {
      return const CoverImportResult.failed(
        NativeFailure(kind: 'unsupported', transient: false),
      );
    }
    final key = keyOf(bytes);
    for (final size in ['thumb', 'full']) {
      final out = File('$outDir/covers/$size/$key.jpg')
        ..createSync(recursive: true);
      out.writeAsBytesSync(bytes);
    }
    return CoverImportResult.done(key: key, colors: colors);
  }
}

List<int> _img(int seed) => [
  0x47,
  ...List.generate(64, (i) => (i * seed) & 0xFF),
];

final _album = AlbumKey('artist', 'title').encode();
final _artist = ArtistKey('artist').encode();

void main() {
  late Directory root;
  late AppDatabase db;
  late _FakeImporter importer;
  late CustomCoverStore store;

  CustomCoverStore newStore({Duration gcMinAge = Duration.zero}) =>
      CustomCoverStore(
        db,
        Directory('${root.path}/data'),
        importer: importer,
        gcMinAge: gcMinAge,
      );

  setUp(() {
    root = Directory.systemTemp.createTempSync('kanaru_ccs_');
    db = openTestDb();
    importer = _FakeImporter();
    store = newStore();
  });
  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  File source(String name, List<int> bytes) =>
      File('${root.path}/$name')..writeAsBytesSync(bytes);

  /// Relative paths of every file under the store folder.
  List<String> stored() {
    if (!store.directory.existsSync()) return [];
    final base = store.directory.path.length + 1;
    return store.directory
        .listSync(recursive: true)
        .whereType<File>()
        .map((e) => e.path.substring(base))
        .toList()
      ..sort();
  }

  List<String> filesOf(List<int> bytes) {
    final k = _FakeImporter.keyOf(bytes);
    return ['covers/full/$k.jpg', 'covers/thumb/$k.jpg'];
  }

  test('import writes thumb and full, the row and the colours', () async {
    final bytes = _img(3);
    final src = source('cover.bin', bytes);
    await store.importCover(CustomCoverKind.album, _album, src);

    final key = _FakeImporter.keyOf(bytes);
    expect(await customCoverKey(db, 'album', _album), key);
    expect(stored(), filesOf(bytes));
    expect(store.directory.path, startsWith('${root.path}/data/'));
    expect((await store.fileFor(key))!.path, endsWith('covers/full/$key.jpg'));
    expect(
      (await store.fileFor(key, size: CoverSize.thumb))!.path,
      endsWith('covers/thumb/$key.jpg'),
    );
    final row = await coverColorsFor(db, key);
    expect(row?.seed, 0xFFAA0000);
    expect(row?.colors, [0xFFAA0000]);
    src.deleteSync(); // the source is not needed any more
    expect(await store.fileFor(key), isNotNull);
  });

  test('a near-gray image has a row and no colours', () async {
    importer.colors = null;
    await store.importCover(
      CustomCoverKind.album,
      _album,
      source('a', _img(2)),
    );
    final key = (await referencedCustomCoverKeys(db)).single;
    expect(await coverColorsFor(db, key), isNull);
  });

  test(
    'replacing removes old files only when no other row uses them',
    () async {
      final a = _img(3);
      final b = _img(5);
      await store.importCover(CustomCoverKind.album, _album, source('a', a));
      await store.importCover(CustomCoverKind.artist, _artist, source('a2', a));
      await store.importCover(CustomCoverKind.album, _album, source('b', b));
      expect(stored(), [...filesOf(a), ...filesOf(b)]..sort());

      await store.importCover(CustomCoverKind.artist, _artist, source('b2', b));
      expect(stored(), filesOf(b));
      expect(await referencedCustomCoverKeys(db), {_FakeImporter.keyOf(b)});
    },
  );

  test('importing the same image again repairs the files', () async {
    final bytes = _img(7);
    await store.importCover(CustomCoverKind.album, _album, source('1', bytes));
    final full = File('${store.directory.path}/${filesOf(bytes).first}');
    full.writeAsBytesSync([]); // damaged, e.g. after a power loss
    await store.importCover(CustomCoverKind.album, _album, source('2', bytes));
    expect(stored(), filesOf(bytes));
    expect(full.readAsBytesSync(), bytes);
    expect(
      (await db
              .customSelect('SELECT count(*) AS n FROM custom_covers')
              .getSingle())
          .read<int>('n'),
      1,
    );
  });

  test('removeCover clears the row and deletes the unused files', () async {
    await addPlaylist(db, uid: 'p');
    await store.importCover(
      CustomCoverKind.playlist,
      'p',
      source('1', _img(2)),
    );
    await store.removeCover(CustomCoverKind.playlist, 'p');
    expect(await referencedCustomCoverKeys(db), isEmpty);
    expect(stored(), isEmpty);
    await store.removeCover(CustomCoverKind.playlist, 'p'); // no-op
  });

  group('failures', () {
    test('permanent native failures are FormatException', () async {
      await expectLater(
        store.importCover(CustomCoverKind.album, _album, source('t', [1, 2])),
        throwsFormatException,
      );
      await expectLater(
        store.importCover(
          CustomCoverKind.album,
          _album,
          File('${root.path}/missing.png'),
        ),
        throwsFormatException,
      );
      for (final kind in ['corrupt', 'unsupported', 'tooLarge', 'notFound']) {
        importer.forced = NativeFailure(kind: kind, transient: false);
        await expectLater(
          store.importCover(
            CustomCoverKind.album,
            _album,
            source('g', _img(1)),
          ),
          throwsFormatException,
          reason: kind,
        );
      }
    });

    test('transient native failures are FileSystemException', () async {
      importer.forced = const NativeFailure(kind: 'io', transient: true);
      await expectLater(
        store.importCover(CustomCoverKind.album, _album, source('g', _img(1))),
        throwsA(isA<FileSystemException>()),
      );
    });

    test(
      'permissionDenied is a FileSystemException, panic a FormatException',
      () async {
        importer.forced = const NativeFailure(
          kind: 'permissionDenied',
          transient: false,
        );
        await expectLater(
          store.importCover(
            CustomCoverKind.album,
            _album,
            source('g', _img(1)),
          ),
          throwsA(isA<FileSystemException>()),
        );
        importer.forced = const NativeFailure(kind: 'panic', transient: false);
        await expectLater(
          store.importCover(
            CustomCoverKind.album,
            _album,
            source('g', _img(1)),
          ),
          throwsFormatException,
        );
      },
    );

    CustomCoverStore stalledStore() => CustomCoverStore(
      db,
      Directory('${root.path}/data'),
      importer: importer,
      gcMinAge: const Duration(hours: 1), // the GC cannot be what cleans up
      importTimeout: const Duration(milliseconds: 50),
    );

    test(
      'a stalled import times out, the queue runs on, late files go',
      () async {
        final quick = stalledStore();
        importer.hang = Completer<void>();
        await expectLater(
          quick.importCover(
            CustomCoverKind.album,
            _album,
            source('s', _img(1)),
          ),
          throwsA(isA<FileSystemException>()),
        );
        importer.hang!.complete(); // the stalled call finishes late
        // Real file I/O finishes outside the event queue: wait for the cleanup.
        for (var i = 0; i < 100 && stored().isNotEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(stored(), isEmpty); // removed by the late-finish cleanup
        expect(await referencedCustomCoverKeys(db), isEmpty);
        importer.hang = null;
        await quick.importCover(
          CustomCoverKind.album,
          _album,
          source('o', _img(2)),
        );
        expect(stored(), filesOf(_img(2)));
      },
    );

    test(
      'a late finish keeps files a new import of the same image uses',
      () async {
        final quick = stalledStore();
        final hang = importer.hang = Completer<void>();
        await expectLater(
          quick.importCover(
            CustomCoverKind.album,
            _album,
            source('s', _img(1)),
          ),
          throwsA(isA<FileSystemException>()),
        );
        importer.hang = null;
        await quick.importCover(
          CustomCoverKind.artist,
          _artist,
          source('n', _img(1)),
        );
        hang.complete();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        // A no-op queued behind the late cleanup: it has run when this returns.
        await quick.removeCover(CustomCoverKind.playlist, 'none');
        expect(stored(), filesOf(_img(1)));
        final key = _FakeImporter.keyOf(_img(1));
        expect(await customCoverKey(db, 'artist', _artist), key);
        expect(await quick.fileFor(key), isNotNull);
      },
    );

    test('a failure keeps the old cover and leaves nothing new', () async {
      final a = _img(2);
      await store.importCover(CustomCoverKind.album, _album, source('a', a));
      importer.forced = const NativeFailure(kind: 'corrupt', transient: false);
      await expectLater(
        store.importCover(CustomCoverKind.album, _album, source('b', _img(4))),
        throwsFormatException,
      );
      expect(await customCoverKey(db, 'album', _album), _FakeImporter.keyOf(a));
      expect(stored(), filesOf(a));
    });

    test('bad item keys are rejected before the importer runs', () async {
      final good = source('ok', _img(1));
      for (final bad in [
        (CustomCoverKind.album, 'Raw Title'),
        (CustomCoverKind.album, _artist),
        (CustomCoverKind.artist, 'Raw Name'),
        (CustomCoverKind.playlist, ''),
        (CustomCoverKind.playlist, favoritesPlaylistUid),
      ]) {
        await expectLater(
          store.importCover(bad.$1, bad.$2, good),
          throwsArgumentError,
          reason: '$bad',
        );
      }
      expect(importer.calls, 0);
      expect(stored(), isEmpty);
    });

    test('a cover for a deleted playlist leaves no row or file', () async {
      await addPlaylist(db, uid: 'p');
      await db.delete(db.playlists).go();
      await expectLater(
        store.importCover(CustomCoverKind.playlist, 'p', source('1', _img(2))),
        throwsA(isA<SqliteException>()),
      );
      expect(await referencedCustomCoverKeys(db), isEmpty);
      expect(stored(), isEmpty);
    });

    test('a failed row write removes the new unreferenced files', () async {
      await db.customStatement(
        'CREATE TRIGGER boom BEFORE INSERT ON custom_covers '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      await expectLater(
        store.importCover(CustomCoverKind.album, _album, source('1', _img(4))),
        throwsA(isA<SqliteException>()),
      );
      expect(stored(), isEmpty);
    });
  });

  group('GC', () {
    String keyFile(String size, String key) =>
        '${store.directory.path}/covers/$size/$key.jpg';

    test('deletes unreferenced thumb/full and old temp files only', () async {
      await store.importCover(
        CustomCoverKind.album,
        _album,
        source('1', _img(2)),
      );
      final keep = filesOf(_img(2));
      final orphan = 'cd/${'1' * 32}';
      for (final size in ['thumb', 'full']) {
        File(keyFile(size, orphan))
          ..createSync(recursive: true)
          ..writeAsBytesSync([1]);
      }
      File('${store.directory.path}/covers/thumb/cd/.kanaru-tmp-abc')
          .writeAsBytesSync([1]);
      File('${store.directory.path}/covers/full/cd/notes.txt')
          .writeAsStringSync('keep me');

      expect(await store.collectUnreferencedFiles(), 3);
      expect(stored(), [...keep, 'covers/full/cd/notes.txt']..sort());
      expect(await store.collectUnreferencedFiles(), 0);
    });

    test('keeps temp files younger than the minimum age', () async {
      final aging = newStore(gcMinAge: const Duration(hours: 1));
      final tmp = File('${aging.directory.path}/covers/thumb/cd/.kanaru-tmp-1')
        ..createSync(recursive: true);
      expect(await aging.collectUnreferencedFiles(), 0);
      expect(tmp.existsSync(), isTrue);
    });

    test('a brand-new unreferenced file is kept, an old one goes', () async {
      final aging = newStore(gcMinAge: const Duration(hours: 1));
      final fresh = File(keyFile('full', 'ab/${'2' * 32}'))
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      final old = File(keyFile('full', 'ab/${'3' * 32}'))
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      old.setLastModifiedSync(
        DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(await aging.collectUnreferencedFiles(), 1);
      expect(fresh.existsSync(), isTrue);
      expect(old.existsSync(), isFalse);
    });

    test('an import racing the GC keeps its files', () async {
      final imports = [
        for (var i = 0; i < 5; i++)
          store.importCover(
            CustomCoverKind.album,
            AlbumKey('artist', 't$i').encode(),
            source('$i', _img(i + 1)),
          ),
      ];
      final gcs = [
        for (var i = 0; i < 5; i++) store.collectUnreferencedFiles(),
      ];
      await Future.wait([...imports, ...gcs]);
      expect(stored(), hasLength(10));
      for (final k in await referencedCustomCoverKeys(db)) {
        expect(await store.fileFor(k), isNotNull);
        expect(await store.fileFor(k, size: CoverSize.thumb), isNotNull);
      }
    });

    test(
      'a GC queued between two imports of one key keeps the files',
      () async {
        final bytes = _img(6);
        final first = store.importCover(
          CustomCoverKind.album,
          _album,
          source('1', bytes),
        );
        final gc = store.collectUnreferencedFiles();
        final second = store.importCover(
          CustomCoverKind.artist,
          _artist,
          source('2', bytes),
        );
        await Future.wait([first, gc, second]);
        expect(stored(), filesOf(bytes));
      },
    );

    test('with no folder returns 0', () async {
      expect(await store.collectUnreferencedFiles(), 0);
    });
  });

  test('isCustomCoverKey takes the song cover form only', () {
    expect(isCustomCoverKey('ab/${'0' * 32}'), isTrue);
    expect(isCustomCoverKey('a' * 64), isFalse); // the removed SHA-256 form
    expect(isCustomCoverKey('../etc/passwd'), isFalse);
  });

  test('fileFor: an empty file is null', () async {
    await store.importCover(
      CustomCoverKind.album,
      _album,
      source('a', _img(3)),
    );
    final key = (await referencedCustomCoverKeys(db)).single;
    File('${store.directory.path}/${filesOf(_img(3)).first}')
        .writeAsBytesSync([]);
    expect(await store.fileFor(key), isNull);
    expect(await store.fileFor(key, size: CoverSize.thumb), isNotNull);
  });

  test(
    'fileFor: malformed key and valid key without a file are null',
    () async {
      expect(await store.fileFor('../etc/passwd'), isNull);
      expect(await store.fileFor('ab/${'a' * 32}'), isNull);
    },
  );

  group('providers', () {
    late ProviderContainer c;
    setUp(() {
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appPathsProvider.overrideWithValue(
            _Paths(Directory('${root.path}/data')),
          ),
        ],
      );
      addTearDown(c.dispose);
    });

    test('file provider follows the row: none, file, other, none', () async {
      final item = (kind: CustomCoverKind.album, itemKey: _album);
      final seen = <AsyncValue<File?>>[];
      c.listen(
        customCoverFileProvider(item),
        (_, next) => seen.add(next),
        fireImmediately: true,
      );
      final ctl = c.read(customCoverControllerProvider);
      // The container's store uses the real importer; swap in by writing rows
      // through a store with the fake one on the same folder.
      Future<void> pick(List<int> bytes, String name) =>
          store.importCover(CustomCoverKind.album, _album, source(name, bytes));
      await pumpEventQueue();
      await pick(_img(3), 'a');
      await pumpEventQueue();
      await pick(_img(9), 'b');
      await pumpEventQueue();
      await ctl.removeCover(CustomCoverKind.album, _album);
      await pumpEventQueue();

      final names = [
        for (final v in seen.where((v) => v.hasValue))
          v.value?.path.split('/covers/').last,
      ];
      expect(names, [
        null,
        'full/${_FakeImporter.keyOf(_img(3))}.jpg',
        'full/${_FakeImporter.keyOf(_img(9))}.jpg',
        null,
      ]);
    });

    test('thumb and key providers follow the same row', () async {
      final item = (kind: CustomCoverKind.album, itemKey: _album);
      c.listen(customCoverThumbProvider(item), (_, _) {});
      c.listen(customCoverKeyProvider(item), (_, _) {});
      await store.importCover(
        CustomCoverKind.album,
        _album,
        source('a', _img(3)),
      );
      await pumpEventQueue();
      final key = _FakeImporter.keyOf(_img(3));
      expect(c.read(customCoverKeyProvider(item)).value, key);
      expect(
        c.read(customCoverThumbProvider(item)).value?.path,
        endsWith('covers/thumb/$key.jpg'),
      );
    });

    test('stays loaded for a while after the last listener', () async {
      final short = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appPathsProvider.overrideWithValue(
            _Paths(Directory('${root.path}/data')),
          ),
          customCoverKeepAliveProvider.overrideWithValue(
            const Duration(milliseconds: 200),
          ),
        ],
      );
      addTearDown(short.dispose);
      final item = (kind: CustomCoverKind.album, itemKey: _album);
      short.listen(customCoverFileProvider(item), (_, _) {}).close();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // `exists` is deprecated for an experimental `.exist`; fine in a test.
      // ignore: deprecated_member_use
      expect(short.exists(customCoverFileProvider(item)), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // ignore: deprecated_member_use
      expect(short.exists(customCoverFileProvider(item)), isFalse);
    });

    test('a row whose file is missing (restored backup) gives null', () async {
      await db.customStatement(
        "INSERT INTO custom_covers VALUES ('album', '$_album', 'ab/${'c' * 32}', 1)",
      );
      final item = (kind: CustomCoverKind.album, itemKey: _album);
      final sub = c.listen(customCoverFileProvider(item), (_, _) {});
      addTearDown(sub.close);
      expect(await c.read(customCoverFileProvider(item).future), isNull);
    });
  });
}
