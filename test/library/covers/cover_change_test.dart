import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/custom_cover_store.dart';
import 'package:kanaru/src/library/data/scan/native_cover_import.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/domain/covers/cover_preview.dart';
import 'package:kanaru/src/library/domain/custom_cover_controller.dart';

import '../../database/support/test_db.dart';
import '../../support/fake_cover_importer.dart';

class _Previewer implements CoverPreviewer {
  Object? error;
  String? outDir;

  @override
  Future<CoverPreview> prepare({
    required String path,
    required String outDir,
  }) async {
    this.outDir = outDir;
    if (error != null) throw error!;
    return CoverPreview(file: File('$outDir/p.jpg'), width: 4, height: 3);
  }
}

/// Importer that waits for [hold] while it is set.
class _SlowImporter extends FakeCoverImporter {
  Completer<void>? hold;
  @override
  Future<CoverImportResult> import({
    required String path,
    required String outDir,
    CoverCrop? crop,
  }) async {
    await hold?.future;
    return super.import(path: path, outDir: outDir, crop: crop);
  }
}

void main() {
  late Directory root;
  late AppDatabase db;
  late _Previewer previewer;
  late CustomCoverStore store;
  const kind = CustomCoverKind.playlist;

  CustomCoverStore newStore(CoverImporter importer) => CustomCoverStore(
    db,
    Directory('${root.path}/data'),
    importer: importer,
    previewer: previewer,
    gcMinAge: Duration.zero,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('kanaru_cc_');
    db = openTestDb();
    previewer = _Previewer();
    store = newStore(FakeCoverImporter());
  });
  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  File img(String name) =>
      File('${root.path}/$name')
        ..writeAsBytesSync([1, 2, 3, name.codeUnitAt(0)]);

  Future<CoverChange> pick(String uid, String name) =>
      store.changeCover(kind, uid, CoverChoice.file(img(name)));

  Future<String?> keyOf(String uid) => customCoverKey(db, kind.name, uid);

  bool filesExist(String? key) =>
      key != null &&
      File('${store.directory.path}/covers/full/$key.jpg').existsSync();

  test(
    'undo after an import restores the previous cover and drops the new files',
    () async {
      await addPlaylist(db, uid: 'p');
      final first = await pick('p', 'a');
      await first.release();
      final second = await pick('p', 'b');
      expect(second.previousKey, first.currentKey);
      expect(filesExist(second.previousKey), isTrue, reason: 'pinned');
      expect(await second.undo(), isTrue);
      expect(await keyOf('p'), first.currentKey);
      expect(filesExist(first.currentKey), isTrue);
      expect(filesExist(second.currentKey), isFalse);
    },
  );

  test('undo after the automatic choice brings the cover back', () async {
    await addPlaylist(db, uid: 'p');
    final first = await pick('p', 'a');
    await first.release();
    final auto = await store.changeCover(
      kind,
      'p',
      const CoverChoice.automatic(),
    );
    expect(await keyOf('p'), isNull);
    expect(filesExist(first.currentKey), isTrue);
    expect(await auto.undo(), isTrue);
    expect(await keyOf('p'), first.currentKey);
    expect(filesExist(first.currentKey), isTrue);
  });

  test('undo of a first cover goes back to automatic', () async {
    await addPlaylist(db, uid: 'p');
    final c = await pick('p', 'a');
    expect(c.previousKey, isNull);
    expect(await c.undo(), isTrue);
    expect(await keyOf('p'), isNull);
    expect(filesExist(c.currentKey), isFalse);
  });

  test('undo is false when another change landed', () async {
    await addPlaylist(db, uid: 'p');
    final c1 = await pick('p', 'a');
    final c2 = await pick('p', 'b');
    expect(await c1.undo(), isFalse);
    expect(await keyOf('p'), c2.currentKey);
    expect(filesExist(c2.currentKey), isTrue);
    expect(await c2.undo(), isTrue);
  });

  test('undo twice, or after release, is false', () async {
    await addPlaylist(db, uid: 'p');
    final c = await pick('p', 'a');
    expect(await c.undo(), isTrue);
    expect(await c.undo(), isFalse);
    final d = await pick('p', 'b');
    await d.release();
    expect(await d.undo(), isFalse);
    expect(await keyOf('p'), d.currentKey);
  });

  test('undo of an automatic change on a deleted playlist is false', () async {
    await addPlaylist(db, uid: 'p');
    final first = await pick('p', 'a');
    await first.release();
    final auto = await store.changeCover(
      kind,
      'p',
      const CoverChoice.automatic(),
    );
    await db.delete(db.playlists).go();
    expect(await auto.undo(), isFalse); // the trigger aborts the restore
    expect(await keyOf('p'), isNull);
    expect(filesExist(first.currentKey), isFalse, reason: 'released');
  });

  test('changeCover reports an invalid key through the future', () async {
    final f = store.changeCover(kind, '', const CoverChoice.automatic());
    await expectLater(f, throwsArgumentError);
  });

  test('undo on a deleted playlist is false and does not throw', () async {
    await addPlaylist(db, uid: 'p');
    final first = await pick('p', 'a');
    await first.release();
    final c = await pick('p', 'b');
    await db.delete(db.playlists).go(); // the trigger drops the row
    expect(await c.undo(), isFalse);
    expect(await keyOf('p'), isNull);
    // Pin gone with the undo: nothing references or pins the old files.
    expect(filesExist(first.currentKey), isFalse);
  });

  test(
    'a key shared by two playlists survives a change on the other',
    () async {
      await addPlaylist(db, uid: 'p');
      await addPlaylist(db, uid: 'q');
      final first = await pick('p', 'a');
      await first.release();
      await setCustomCover(db, kind.name, 'q', first.currentKey!); // copied
      final onP = await pick('p', 'b'); // open undo on p
      final onQ = await pick('q', 'c');
      await onQ.release(); // q leaves the key; p's change still pins it
      expect(filesExist(first.currentKey), isTrue);
      expect(await onP.undo(), isTrue);
      expect(await keyOf('p'), first.currentKey);
      expect(filesExist(first.currentKey), isTrue);
    },
  );

  test('release deletes only unreferenced and unpinned files', () async {
    await addPlaylist(db, uid: 'p');
    await addPlaylist(db, uid: 'q');
    final first = await pick('p', 'a');
    await first.release();
    await setCustomCover(db, kind.name, 'q', first.currentKey!);
    final c = await pick('p', 'b');
    await c.release();
    expect(filesExist(first.currentKey), isTrue, reason: 'q still uses it');
    final d = await pick('q', 'c');
    final e = await pick('p', 'd'); // second pin on nothing; p had b
    await d.release();
    expect(filesExist(first.currentKey), isFalse);
    expect(filesExist(c.currentKey), isTrue, reason: 'e pins it');
    await e.release();
    expect(filesExist(c.currentKey), isFalse);
  });

  test('the same key pinned twice stays until both are released', () async {
    await addPlaylist(db, uid: 'p');
    await addPlaylist(db, uid: 'q');
    final first = await pick('p', 'a');
    await first.release();
    await setCustomCover(db, kind.name, 'q', first.currentKey!);
    final onP = await pick('p', 'b');
    final onQ = await pick('q', 'c');
    await onP.release();
    expect(filesExist(first.currentKey), isTrue);
    await onQ.release();
    expect(filesExist(first.currentKey), isFalse);
  });

  test('the GC during an open undo keeps the files', () async {
    await addPlaylist(db, uid: 'p');
    final first = await pick('p', 'a');
    await first.release();
    final c = await pick('p', 'b');
    await store.collectUnreferencedFiles();
    expect(filesExist(first.currentKey), isTrue);
    expect(await c.undo(), isTrue);
    expect(await keyOf('p'), first.currentKey);
    expect(filesExist(first.currentKey), isTrue);
  });

  test('double release is a no-op that keeps another change\'s pin', () async {
    await addPlaylist(db, uid: 'p');
    await addPlaylist(db, uid: 'q');
    final first = await pick('p', 'a');
    await first.release();
    await setCustomCover(db, kind.name, 'q', first.currentKey!);
    final onP = await pick('p', 'b');
    final onQ = await pick('q', 'c');
    await onP.release();
    await onP.release();
    expect(filesExist(first.currentKey), isTrue, reason: 'onQ still pins it');
    await onQ.release();
  });

  group('timed-out import', () {
    late _SlowImporter slow;
    late CustomCoverStore s;
    String keyN(int i) => 'ab/${i.toRadixString(16).padLeft(32, '0')}';

    setUp(() {
      slow = _SlowImporter();
      s = CustomCoverStore(
        db,
        Directory('${root.path}/data'),
        importer: slow,
        importTimeout: const Duration(milliseconds: 50),
        gcMinAge: Duration.zero,
      );
    });

    /// Runs a pick that times out, lets the late import finish, then waits
    /// until the store's queue has handled it.
    Future<void> timeOutAndDrain(String uid, String name) async {
      slow.hold = Completer<void>();
      await expectLater(
        s.changeCover(kind, uid, CoverChoice.file(img(name))),
        throwsA(isA<FileSystemException>()),
      );
      slow.hold!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await s.collectUnreferencedFiles(); // queued after the late drop
    }

    test('its late files are deleted and the old cover stays', () async {
      await addPlaylist(db, uid: 'p');
      final old = await s.changeCover(kind, 'p', CoverChoice.file(img('a')));
      await old.release();
      await timeOutAndDrain('p', 'b');
      expect(await keyOf('p'), keyN(1));
      expect(filesExist(keyN(1)), isTrue);
      expect(filesExist(keyN(2)), isFalse, reason: 'late key dropped');
    });

    test('a late key equal to a pinned one keeps the files', () async {
      await addPlaylist(db, uid: 'p');
      final first = await s.changeCover(kind, 'p', CoverChoice.file(img('a')));
      await first.release();
      final auto = await s.changeCover(
        kind,
        'p',
        const CoverChoice.automatic(),
      );
      slow.n = 0; // the late import yields key 1 again
      await timeOutAndDrain('p', 'b');
      expect(filesExist(keyN(1)), isTrue, reason: 'pinned by the open undo');
      expect(await auto.undo(), isTrue);
      expect(await keyOf('p'), keyN(1));
    });
  });

  test('a failed import leaves the cover and pins nothing', () async {
    await addPlaylist(db, uid: 'p');
    final bad = newStore(FakeCoverImporter(fail: true));
    await expectLater(
      bad.changeCover(kind, 'p', CoverChoice.file(img('a'))),
      throwsA(isA<FormatException>()),
    );
    expect(await keyOf('p'), isNull);
  });

  group('previewCover', () {
    test('passes the file and the store folder, returns the preview', () async {
      final p = await store.previewCover(img('a'));
      expect((p.width, p.height), (4, 3));
      expect(previewer.outDir, store.previewDir.path);
    });

    for (final error in <Object>[
      const FormatException('bad'),
      const FileSystemException('io'),
    ]) {
      test('${error.runtimeType} reaches the caller', () async {
        previewer.error = error;
        await expectLater(store.previewCover(img('a')), throwsA(same(error)));
      });
    }
  });
}
