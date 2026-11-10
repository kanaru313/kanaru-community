import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/data/custom_cover_store.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
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

const _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const _jpg = [0xFF, 0xD8, 0xFF, 0xE0];
const _webp = [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50];

List<int> _img(int seed, [List<int> magic = _png]) => [
  ...magic,
  ...List.generate(64, (i) => (i * seed) & 0xFF),
];

final _album = AlbumKey('artist', 'title').encode();
final _album2 = AlbumKey('artist', 'other').encode();
final _artist = ArtistKey('artist').encode();

void main() {
  late Directory root;
  late AppDatabase db;
  late CustomCoverStore store;

  CustomCoverStore newStore({
    int maxBytes = maxCustomCoverBytes,
    Duration gcMinAge = Duration.zero,
    Duration readTimeout = const Duration(seconds: 10),
  }) => CustomCoverStore(
    db,
    Directory('${root.path}/data'),
    maxBytes: maxBytes,
    gcMinAge: gcMinAge,
    readTimeout: readTimeout,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('kanaru_ccs_');
    db = openTestDb();
    store = newStore();
  });
  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  File source(String name, List<int> bytes) =>
      File('${root.path}/$name')..writeAsBytesSync(bytes);

  List<String> stored() {
    if (!store.directory.existsSync()) return [];
    return store.directory
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .toList()
      ..sort();
  }

  String keyOf(List<int> bytes) => sha256.convert(bytes).toString();

  test('import copies into the data dir, hashes, sets the row', () async {
    final bytes = _img(3);
    final src = source('cover.bin', bytes); // extension comes from content
    await store.importCover(CustomCoverKind.album, _album, src);

    final key = keyOf(bytes);
    expect(await customCoverKey(db, 'album', _album), key);
    expect(stored(), ['$key.png']);
    expect((await store.fileFor(key))!.readAsBytesSync(), bytes);
    expect(store.directory.path, startsWith('${root.path}/data/'));
    src.deleteSync(); // the source is not needed any more
    expect(await store.fileFor(key), isNotNull);
  });

  test('JPEG and WebP are accepted with their own extension', () async {
    final j = _img(2, _jpg);
    final w = _img(4, _webp);
    await store.importCover(CustomCoverKind.album, _album, source('a', j));
    await store.importCover(CustomCoverKind.artist, _artist, source('b', w));
    expect(stored(), ['${keyOf(j)}.jpg', '${keyOf(w)}.webp']);
    expect(await store.fileFor(keyOf(w)), isNotNull);
  });

  test(
    'replacing removes the old file only when no other row uses it',
    () async {
      final a = _img(3);
      final b = _img(5);
      await store.importCover(
        CustomCoverKind.album,
        _album,
        source('a.png', a),
      );
      await store.importCover(
        CustomCoverKind.artist,
        _artist,
        source('a2.png', a),
      );
      await store.importCover(
        CustomCoverKind.album,
        _album,
        source('b.png', b),
      );
      // A is still used by the artist: kept.
      expect(stored(), ['${keyOf(a)}.png', '${keyOf(b)}.png']..sort());

      await store.importCover(
        CustomCoverKind.artist,
        _artist,
        source('b2.png', b),
      );
      expect(stored(), ['${keyOf(b)}.png']);
      expect(await referencedCustomCoverKeys(db), {keyOf(b)});
    },
  );

  test(
    'importing the same image again is idempotent and repairs the file',
    () async {
      final bytes = _img(7);
      await store.importCover(
        CustomCoverKind.album,
        _album,
        source('1.png', bytes),
      );
      final target = File('${store.directory.path}/${keyOf(bytes)}.png');
      target.writeAsBytesSync([]); // a damaged copy, e.g. after a power loss
      await store.importCover(
        CustomCoverKind.album,
        _album,
        source('2.png', bytes),
      );
      expect(stored(), hasLength(1));
      expect(target.readAsBytesSync(), bytes);
      expect(
        (await db
                .customSelect('SELECT count(*) AS n FROM custom_covers')
                .getSingle())
            .read<int>('n'),
        1,
      );
    },
  );

  test('removeCover clears the row and deletes the unused file', () async {
    await addPlaylist(db, uid: 'p');
    await store.importCover(
      CustomCoverKind.playlist,
      'p',
      source('1.png', _img(2)),
    );
    await store.removeCover(CustomCoverKind.playlist, 'p');
    expect(await referencedCustomCoverKeys(db), isEmpty);
    expect(stored(), isEmpty);
    await store.removeCover(CustomCoverKind.playlist, 'p'); // no-op
  });

  test('rejects non-images, empty files, special files and bad keys', () async {
    final good = source('ok.png', _img(1));
    await expectLater(
      store.importCover(
        CustomCoverKind.album,
        _album,
        source('t.txt', [1, 2, 3, 4]),
      ),
      throwsFormatException,
    );
    await expectLater(
      store.importCover(CustomCoverKind.album, _album, source('e.png', [])),
      throwsFormatException,
    );
    await expectLater(
      store.importCover(CustomCoverKind.album, _album, File(root.path)),
      throwsFormatException, // a directory is not a regular file
    );
    await expectLater(
      store.importCover(
        CustomCoverKind.album,
        _album,
        File('${root.path}/missing.png'),
      ),
      throwsFormatException,
    );
    for (final bad in [
      (CustomCoverKind.album, 'Raw Title'),
      (CustomCoverKind.album, _artist), // no NUL separator
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
    expect(stored(), isEmpty);
    expect(await referencedCustomCoverKeys(db), isEmpty);
  });

  test('the size cap rejects a larger file and leaves nothing', () async {
    final small = newStore(maxBytes: 100);
    await small.importCover(
      CustomCoverKind.album,
      _album,
      source('ok.png', _img(1)),
    ); // 72 bytes
    await expectLater(
      small.importCover(
        CustomCoverKind.album,
        _album2,
        source('big.png', [..._png, ...List.filled(200, 1)]),
      ),
      throwsFormatException,
    );
    expect(stored(), hasLength(1));
    expect(await referencedCustomCoverKeys(db), hasLength(1));
  });

  test('a cover for a deleted playlist leaves no row or file', () async {
    await addPlaylist(db, uid: 'p');
    await db.delete(db.playlists).go();
    await expectLater(
      store.importCover(
        CustomCoverKind.playlist,
        'p',
        source('1.png', _img(2)),
      ),
      throwsA(anything),
    );
    expect(await referencedCustomCoverKeys(db), isEmpty);
    expect(stored(), isEmpty);
  });

  test('a failed row write removes the new unreferenced file', () async {
    await db.customStatement(
      'CREATE TRIGGER boom BEFORE INSERT ON custom_covers '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    await expectLater(
      store.importCover(
        CustomCoverKind.album,
        _album,
        source('1.png', _img(4)),
      ),
      throwsA(anything),
    );
    expect(stored(), isEmpty);
  });

  test('a stalled source times out and later operations still run', () async {
    // A fake stream that never sends data; a real stalled file stream takes
    // the same timeout path, but this test does not prove that end to end.
    final quick = newStore(readTimeout: const Duration(milliseconds: 50));
    final stalled = _StalledFile(source('stalled.png', _img(1)).path);
    await expectLater(
      quick.importCover(CustomCoverKind.album, _album, stalled),
      throwsA(isA<TimeoutException>()),
    );
    await quick.importCover(
      CustomCoverKind.album,
      _album,
      source('ok.png', _img(2)),
    );
    expect(stored(), hasLength(1));
  });

  test('GC deletes unreferenced files and temp files only', () async {
    await store.importCover(
      CustomCoverKind.album,
      _album,
      source('1.png', _img(2)),
    );
    final keep = (await referencedCustomCoverKeys(db)).single;
    File('${store.directory.path}/${'a' * 64}.jpg').writeAsBytesSync([1]);
    File('${store.directory.path}/.tmp-1_0').writeAsBytesSync([1]);
    File('${store.directory.path}/notes.txt').writeAsStringSync('keep me');

    expect(await store.collectUnreferencedFiles(), 2);
    expect(stored(), ['$keep.png', 'notes.txt']..sort());
    expect(await store.collectUnreferencedFiles(), 0);
  });

  test('GC leaves files younger than the minimum age', () async {
    final aging = newStore(gcMinAge: const Duration(hours: 1));
    await Directory(aging.directory.path).create(recursive: true);
    File('${aging.directory.path}/${'b' * 64}.png').writeAsBytesSync([1]);
    File('${aging.directory.path}/.tmp-9_9').writeAsBytesSync([1]);
    expect(await aging.collectUnreferencedFiles(), 0);
    expect(stored(), hasLength(2));
  });

  test('an import racing the GC keeps its file', () async {
    final imports = [
      for (var i = 0; i < 5; i++)
        store.importCover(
          CustomCoverKind.album,
          AlbumKey('artist', 't$i').encode(),
          source('$i.png', _img(i + 1)),
        ),
    ];
    final gcs = [for (var i = 0; i < 5; i++) store.collectUnreferencedFiles()];
    await Future.wait([...imports, ...gcs]);
    expect(stored(), hasLength(5));
    for (final k in await referencedCustomCoverKeys(db)) {
      expect(await store.fileFor(k), isNotNull);
    }
  });

  test('GC with no folder returns 0', () async {
    expect(await store.collectUnreferencedFiles(), 0);
  });

  test(
    'fileFor: malformed key and valid key without a file are null',
    () async {
      expect(await store.fileFor('../etc/passwd'), isNull);
      expect(await store.fileFor('a' * 64), isNull);
    },
  );

  group('customCoverFileProvider', () {
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

    test('follows the row: none, file, other file, none', () async {
      final item = (kind: CustomCoverKind.album, itemKey: _album);
      final seen = <AsyncValue<File?>>[];
      c.listen(
        customCoverFileProvider(item),
        (_, next) => seen.add(next),
        fireImmediately: true,
      );
      final ctl = c.read(customCoverControllerProvider);
      await pumpEventQueue();
      await ctl.importCover(
        CustomCoverKind.album,
        _album,
        source('a.png', _img(3)),
      );
      await pumpEventQueue();
      await ctl.importCover(
        CustomCoverKind.album,
        _album,
        source('b.png', _img(9)),
      );
      await pumpEventQueue();
      await ctl.removeCover(CustomCoverKind.album, _album);
      await pumpEventQueue();

      final names = [
        for (final v in seen.where((v) => v.hasValue))
          v.value?.uri.pathSegments.last,
      ];
      expect(names, [
        null,
        '${keyOf(_img(3))}.png',
        '${keyOf(_img(9))}.png',
        null,
      ]);
    });

    test('a row whose file is missing (restored backup) gives null', () async {
      await db.customStatement(
        "INSERT INTO custom_covers VALUES ('album', '$_album', '${'c' * 64}', 1)",
      );
      final item = (kind: CustomCoverKind.album, itemKey: _album);
      final sub = c.listen(customCoverFileProvider(item), (_, _) {});
      addTearDown(sub.close);
      expect(await c.read(customCoverFileProvider(item).future), isNull);
    });
  });
}

/// A source whose stream never produces a chunk.
class _StalledFile implements File {
  _StalledFile(this.path);
  @override
  final String path;

  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      StreamController<List<int>>().stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
