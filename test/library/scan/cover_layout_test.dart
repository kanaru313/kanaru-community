import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/cover_layout.dart';

import 'support/cover_fixtures.dart';
import 'support/scan_fixtures.dart';

void main() {
  late StatementLog log;
  late AppDatabase db;
  late Directory cache;
  late int sourceId;
  setUp(() async {
    log = StatementLog();
    db = openLoggedDb(log);
    cache = makeCacheDir();
    sourceId = (await addScanFolder(db)).sourceId;
  });
  tearDown(() async {
    await db.close();
    cache.deleteSync(recursive: true);
  });

  Future<int> nonZero() async =>
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM tracks WHERE cover_scan_version <> 0',
              )
              .getSingle())
          .read<int>('n');

  test(
    'a missing marker resets every version and creates the layout',
    () async {
      await addManyTracks(db, sourceId, 450);
      await db.customStatement('UPDATE tracks SET cover_scan_version = 1');
      log.updates.clear();
      final r = await ensureCoverLayout(db, cache.path);
      expect(r.reset, isTrue);
      expect(r.rowsReset, 450);
      expect(r.statements, 3);
      expect(log.updatesMatching('SET cover_scan_version = 0'), 3);
      expect(await nonZero(), 0);
      expect(Directory('${cache.path}/covers/thumb').existsSync(), isTrue);
      expect(Directory('${cache.path}/covers/full').existsSync(), isTrue);
      expect(File('${cache.path}/covers/.layout-v1').existsSync(), isTrue);
    },
  );

  test('rows at version 0 are not touched', () async {
    await addManyTracks(db, sourceId, 3);
    log.updates.clear();
    final r = await ensureCoverLayout(db, cache.path);
    expect(r.reset, isTrue);
    expect(r.statements, 0);
    expect(log.updatesMatching('cover_scan_version'), 0);
  });

  test('a present marker changes nothing', () async {
    await addManyTracks(db, sourceId, 3);
    await db.customStatement('UPDATE tracks SET cover_scan_version = 1');
    writeLayoutMarker(cache);
    log.updates.clear();
    final r = await ensureCoverLayout(db, cache.path);
    expect(r.reset, isFalse);
    expect(await nonZero(), 3);
    expect(log.updates, isEmpty);
  });

  test(
    'a cache folder that cannot be written is logged, then reset again',
    () async {
      await addManyTracks(db, sourceId, 2);
      await db.customStatement('UPDATE tracks SET cover_scan_version = 1');
      // "covers" is a file, so no folder can be made under it.
      File('${cache.path}/covers').writeAsStringSync('not a folder');
      final first = await ensureCoverLayout(db, cache.path);
      expect(first.reset, isTrue);
      expect(first.markerWritten, isFalse);
      expect(await nonZero(), 0);
      await db.customStatement('UPDATE tracks SET cover_scan_version = 1');
      final second = await ensureCoverLayout(db, cache.path);
      expect(second.reset, isTrue);
      expect(second.rowsReset, 2);
    },
  );
}
