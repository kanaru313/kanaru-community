import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/cover_pass.dart';
import 'package:kanaru/src/library/data/scan/cover_reextract.dart';
import 'package:kanaru/src/library/data/scan/cover_work.dart';
import 'package:kanaru/src/library/domain/scan/cover_read.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';

import '../../database/support/test_db.dart';
import 'support/cover_fixtures.dart';
import 'support/scan_fixtures.dart';

void main() {
  late StatementLog log;
  late AppDatabase db;
  late Directory cache;
  late int sourceId;
  late FakeCoverMaker maker;
  setUp(() async {
    log = StatementLog();
    db = openLoggedDb(log);
    cache = makeCacheDir();
    writeLayoutMarker(cache);
    sourceId = (await addScanFolder(db)).sourceId;
    maker = FakeCoverMaker();
  });
  tearDown(() async {
    await db.close();
    cache.deleteSync(recursive: true);
  });

  Future<Map<String, Object?>> row(String locator) async =>
      (await coverRows(db)).singleWhere((r) => r['locator'] == locator);

  Future<List<int>> ids() async => [
    for (final r in await coverRows(db)) r['id']! as int,
  ];

  Future<CoverPassResult> run({bool sidecars = true, Set<int>? skip}) =>
      runCoverPass(coverDeps(db, maker, cache, sidecars: sidecars, skip: skip));

  group('results', () {
    test(
      'found, no cover, transient and permanent write the right columns',
      () async {
        await addManyTracks(db, sourceId, 4);
        final all = await ids();
        await db.customStatement(
          "UPDATE tracks SET cover_key = '${keyFor(99)}' WHERE id > ${all[0]}",
        );
        maker.respond = (id, _) {
          if (id == all[0]) return found(id, keyFor(1));
          if (id == all[1]) return noCover(id);
          if (id == all[2]) {
            return coverFailed(id, transient: true, kind: 'timeout');
          }
          return coverFailed(id, transient: false, kind: 'corrupt');
        };
        final r = await run();
        expect(r.found, 1);
        expect(r.noCover, 1);
        expect(r.transientFailed, 1);
        expect(r.permanentFailed, 1);
        expect(r.finished, isTrue);

        final a = await row('f00000.mp3');
        expect(a['cover_key'], keyFor(1));
        expect(a['cover_scan_version'], 1);
        expect(a['scan_error'], isNull);
        final b = await row('f00001.mp3');
        expect(b['cover_key'], isNull);
        expect(b['cover_scan_version'], 1);
        final c = await row('f00002.mp3');
        expect(c['cover_key'], keyFor(99));
        expect(c['cover_scan_version'], 0);
        expect(c['scan_error'], 'timeout');
        final d = await row('f00003.mp3');
        expect(d['cover_key'], isNull);
        expect(d['cover_scan_version'], 1);
        expect(d['scan_error'], 'corrupt');
      },
    );

    test('a cache write failure keeps key and version on the whole batch and ends the pass', () async {
      await addManyTracks(db, sourceId, 40);
      await db.customStatement(
        "UPDATE tracks SET cover_key = '${keyFor(5)}', cover_scan_version = 0",
      );
      maker.respond = (id, _) => coverFailed(id, transient: true, cache: true);
      final r = await run();
      expect(r.cacheFailed, isTrue);
      expect(r.finished, isFalse);
      expect(maker.extractCalls, hasLength(1));
      for (final x in await coverRows(db)) {
        expect(x['cover_key'], keyFor(5));
        expect(x['cover_scan_version'], 0);
      }
    });

    test('without sidecars a NoCover keeps key and version', () async {
      await addManyTracks(db, sourceId, 2);
      await db.customStatement("UPDATE tracks SET cover_key = '${keyFor(7)}'");
      maker.respond = (id, _) => noCover(id);
      final skip = <int>{};
      final r = await run(sidecars: false, skip: skip);
      expect(maker.sidecarFlags, [false]);
      expect(r.deferred, 2);
      expect(r.noCover, 0);
      for (final x in await coverRows(db)) {
        expect(x['cover_key'], keyFor(7));
        expect(x['cover_scan_version'], 0);
      }
      expect(skip, hasLength(2));
    });

    test('paths that differ from the layout are a transient failure', () async {
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) => CoverRead(
        trackId: id,
        status: CoverStatus.found,
        key: keyFor(1),
        made: true,
        thumbRel: 'covers/thumb/other.jpg',
        fullRel: 'covers/full/${keyFor(1)}.jpg',
      );
      final skip = <int>{};
      final r = await run(skip: skip);
      expect(r.transientFailed, 1);
      expect(r.found, 0);
      final x = (await coverRows(db)).single;
      expect(x['cover_key'], isNull);
      expect(x['cover_scan_version'], 0);
      expect(x['scan_error'], 'coverLayout');
      expect(skip, hasLength(1));
    });

    test('only present rows of enabled mounts are visited', () async {
      await addManyTracks(db, sourceId, 2);
      await db.customStatement(
        "UPDATE tracks SET status = 'missing', missing_since = 1 "
        "WHERE locator = 'f00001.mp3'",
      );
      final other = await addScanFolder(db, uid: 'src-off', root: '/off');
      await addTrack(db, other.sourceId, locator: 'o.mp3');
      await setMountEnabled(db, other.sourceId, false, 1);
      final r = await run();
      expect(r.total, 1);
    });

    test('a source filter limits the work', () async {
      await addManyTracks(db, sourceId, 2);
      final other = await addScanFolder(db, uid: 'src-b', root: '/b');
      await addTrack(db, other.sourceId, locator: 'b.mp3');
      final r = await runCoverPass(
        coverDeps(db, maker, cache),
        sourceIds: {other.sourceId},
      );
      expect(r.total, 1);
      expect(maker.extractCalls.single, hasLength(1));
    });
  });

  group('colours', () {
    test('colours that came with new files are stored once', () async {
      await addManyTracks(db, sourceId, 2);
      maker.respond = (id, _) => found(id, keyFor(1));
      final r = await run();
      expect(r.colorsWritten, 2);
      final stored = await coverColorsFor(db, keyFor(1));
      expect(stored!.seed, sampleColors.seed);
      expect(stored.version, coverColorsVersion);
      expect(maker.colorCalls, isEmpty);
    });

    test('an existing cover without colours asks Rust once per key', () async {
      await addManyTracks(db, sourceId, 3);
      maker.respond = (id, _) =>
          found(id, keyFor(1), made: false, colors: null);
      maker.colors = {keyFor(1): sampleColors};
      await run();
      expect(maker.colorCalls, [
        [keyFor(1)],
      ]);
      expect(await coverColorsFor(db, keyFor(1)), isNotNull);
    });

    test('colours of an older version are computed again', () async {
      await upsertCoverColors(
        db,
        coverKey: keyFor(1),
        seed: 1,
        colors: [1],
        version: 0,
        now: 1,
      );
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) =>
          found(id, keyFor(1), made: false, colors: null);
      maker.colors = {keyFor(1): sampleColors};
      await run();
      expect(maker.colorCalls, hasLength(1));
      expect(
        (await coverColorsFor(db, keyFor(1)))!.version,
        coverColorsVersion,
      );
    });

    test('current colours are not computed again', () async {
      await upsertCoverColors(
        db,
        coverKey: keyFor(1),
        seed: 1,
        colors: [1],
        version: coverColorsVersion,
        now: 1,
      );
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) =>
          found(id, keyFor(1), made: false, colors: null);
      await run();
      expect(maker.colorCalls, isEmpty);
    });

    test('a near-gray cover gets a key and no colour row', () async {
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) => found(id, keyFor(2), colors: null);
      final r = await run();
      expect(r.found, 1);
      expect(r.colorsWritten, 0);
      expect(maker.colorCalls, isEmpty);
      expect(await coverColorsFor(db, keyFor(2)), isNull);
      expect((await coverRows(db)).single['cover_key'], keyFor(2));
    });
  });

  group('re-extract and layout', () {
    test('reExtract resets only present rows with that key and re-runs them', () async {
      await addManyTracks(db, sourceId, 3);
      final all = await ids();
      await db.customStatement(
        "UPDATE tracks SET cover_key = '${keyFor(1)}', cover_scan_version = 1 "
        'WHERE id IN (${all[0]}, ${all[1]})',
      );
      await db.customStatement(
        "UPDATE tracks SET cover_key = '${keyFor(2)}', cover_scan_version = 1 "
        'WHERE id = ${all[2]}',
      );
      await db.customStatement(
        "UPDATE tracks SET status = 'missing', missing_since = 1 "
        'WHERE id = ${all[1]}',
      );
      final r = await reExtractCovers(coverDeps(db, maker, cache), [keyFor(1)]);
      expect(maker.extractCalls.single, [all[0]]);
      expect(r.found, 1);
      expect((await row('f00001.mp3'))['cover_scan_version'], 1);
      expect((await row('f00002.mp3'))['cover_scan_version'], 1);
    });

    test('reExtract ignores malformed keys', () async {
      await addManyTracks(db, sourceId, 1);
      final r = await reExtractCovers(coverDeps(db, maker, cache), [
        '../evil',
        'nope',
      ]);
      expect(r.finished, isTrue);
      expect(maker.extractCalls, isEmpty);
    });

    test('reExtract with the marker gone prepares the layout first', () async {
      await addManyTracks(db, sourceId, 2);
      await db.customStatement(
        "UPDATE tracks SET cover_key = '${keyFor(1)}', cover_scan_version = 1",
      );
      File('${cache.path}/covers/.layout-v1').deleteSync();
      Directory('${cache.path}/covers/thumb').deleteSync(recursive: true);
      await reExtractCovers(coverDeps(db, maker, cache), [keyFor(1)]);
      expect(File('${cache.path}/covers/.layout-v1').existsSync(), isTrue);
      expect(Directory('${cache.path}/covers/thumb').existsSync(), isTrue);
      expect(maker.extractCalls.single, hasLength(2));
    });

    test('a pass with the marker gone re-does every cover', () async {
      await addManyTracks(db, sourceId, 3);
      await db.customStatement(
        "UPDATE tracks SET cover_key = '${keyFor(1)}', cover_scan_version = 1",
      );
      File('${cache.path}/covers/.layout-v1').deleteSync();
      final r = await run();
      expect(r.total, 3);
      expect(File('${cache.path}/covers/.layout-v1').existsSync(), isTrue);
    });
  });

  group('safety', () {
    test('a panic keeps a good cover key and moves the version on', () async {
      await addManyTracks(db, sourceId, 1);
      await db.customStatement("UPDATE tracks SET cover_key = '${keyFor(3)}'");
      maker.respond = (id, _) =>
          coverFailed(id, transient: false, kind: 'panic');
      await run();
      final x = (await coverRows(db)).single;
      expect(x['cover_key'], keyFor(3));
      expect(x['cover_scan_version'], 1);
      expect(x['scan_error'], 'panic');
    });

    test('a panic id joins the session skip set', () async {
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) =>
          coverFailed(id, transient: false, kind: 'panic');
      final skip = <int>{};
      await run(skip: skip);
      expect(skip, hasLength(1));
    });

    test('colours are not written after a stop', () async {
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) =>
          found(id, keyFor(1), made: false, colors: null);
      maker.colors = {keyFor(1): sampleColors};
      var stop = false;
      maker.onColors = () => stop = true;
      final r = await runCoverPass(
        coverDeps(db, maker, cache, shouldStop: () => stop),
      );
      expect(r.colorsWritten, 0);
      expect(await coverColorsFor(db, keyFor(1)), isNull);
      expect(r.stopped, isTrue);
      expect(r.finished, isFalse);
    });

    test(
      'a stop between the native call and the write writes nothing',
      () async {
        await addManyTracks(db, sourceId, 3);
        var stop = false;
        maker.onExtract = () => stop = true;
        final r = await runCoverPass(
          coverDeps(db, maker, cache, shouldStop: () => stop),
        );
        expect(r.stopped, isTrue);
        for (final x in await coverRows(db)) {
          expect(x['cover_scan_version'], 0);
          expect(x['cover_key'], isNull);
        }
      },
    );

    test('a colours call past its timeout reports stuck', () async {
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) =>
          found(id, keyFor(1), made: false, colors: null);
      maker.colorHang = Completer<List<CoverColorsRead>>();
      final r = await runCoverPass(
        coverDeps(db, maker, cache, timeout: const Duration(milliseconds: 30)),
      );
      expect(r.stuck, isTrue);
      expect(r.finished, isFalse);
      maker.colorHang!.complete(const []);
      await r.pendingNative;
    });

    test('a near-gray key is not asked again in the session', () async {
      await addManyTracks(db, sourceId, 1);
      maker.respond = (id, _) =>
          found(id, keyFor(1), made: false, colors: null);
      final noColors = <String>{};
      await runCoverPass(coverDeps(db, maker, cache, noColors: noColors));
      expect(maker.colorCalls, hasLength(1));
      expect(noColors, {keyFor(1)});
      await db.customStatement('UPDATE tracks SET cover_scan_version = 0');
      await runCoverPass(coverDeps(db, maker, cache, noColors: noColors));
      expect(maker.colorCalls, hasLength(1));
    });

    test('a miss storm of 450 keys is read in chunks of at most 200', () async {
      await addManyTracks(db, sourceId, 3);
      await db.customStatement(
        "UPDATE tracks SET cover_key = '${keyFor(1)}', cover_scan_version = 0",
      );
      final keys = {for (var i = 0; i < 450; i++) keyFor(i)};
      log.selects.clear();
      final ids = await coverWorkSet(db, null, keys);
      expect(ids, hasLength(3));
      final queries = log.selects.where((q) => q.contains('cover_key IN'));
      expect(queries, hasLength(3));
      for (final q in queries) {
        expect('?'.allMatches(q).length, lessThanOrEqualTo(201));
      }
    });
  });

  group('control', () {
    test(
      'a call past its timeout leaves the rows alone and reports stuck',
      () async {
        await addManyTracks(db, sourceId, 2);
        maker.hang = Completer<List<CoverRead>>();
        final r = await runCoverPass(
          coverDeps(
            db,
            maker,
            cache,
            timeout: const Duration(milliseconds: 30),
          ),
        );
        expect(r.stuck, isTrue);
        expect(r.finished, isFalse);
        for (final x in await coverRows(db)) {
          expect(x['cover_scan_version'], 0);
        }
        maker.hang!.complete(const []);
        await r.pendingNative;
      },
    );

    test('a pass that stopped resumes where the version says', () async {
      await addManyTracks(db, sourceId, 40);
      var calls = 0;
      final first = await runCoverPass(
        coverDeps(db, maker, cache, shouldStop: () => ++calls > 2),
      );
      expect(first.stopped, isTrue);
      expect(maker.extractCalls.single, hasLength(32));
      final second = await run();
      expect(second.finished, isTrue);
      expect(maker.extractCalls.last, hasLength(8));
      expect(second.total, 8);
    });

    test(
      'the session skip set keeps failed tracks out of the next pass',
      () async {
        await addManyTracks(db, sourceId, 2);
        final all = await ids();
        maker.respond = (id, _) => id == all[0]
            ? coverFailed(id, transient: true)
            : found(id, keyFor(1));
        final skip = <int>{};
        await run(skip: skip);
        expect(skip, {all[0]});
        maker.extractCalls.clear();
        final again = await run(skip: skip);
        expect(again.total, 0);
        expect(maker.extractCalls, isEmpty);
      },
    );

    test('progress is reported per batch', () async {
      await addManyTracks(db, sourceId, 40);
      final seen = <(int, int)>[];
      await runCoverPass(
        coverDeps(db, maker, cache, onProgress: (d, t) => seen.add((d, t))),
      );
      expect(seen, [(0, 40), (32, 40), (40, 40)]);
    });

    test('a relative cache folder writes nothing', () async {
      await addManyTracks(db, sourceId, 1);
      final r = await runCoverPass(
        CoverPassDeps(
          db: db,
          maker: maker,
          cacheDir: 'relative/cache',
          sidecars: true,
          now: () => 1,
        ),
      );
      expect(r.failureKind, 'io');
      expect(maker.extractCalls, isEmpty);
    });

    test('a maker that throws ends the pass as unavailable', () async {
      await addManyTracks(db, sourceId, 1);
      maker.throwWith = StateError('no library');
      final r = await run();
      expect(r.failureKind, 'native_unavailable');
      expect((await coverRows(db)).single['cover_scan_version'], 0);
    });

    test('a track the maker did not answer is a transient failure', () async {
      await addManyTracks(db, sourceId, 1);
      maker = _SilentMaker();
      final r = await run();
      expect(r.transientFailed, 1);
      expect((await coverRows(db)).single['scan_error'], 'io');
    });

    test('covers are updated in one notification per transaction', () async {
      await addManyTracks(db, sourceId, 5);
      var events = 0;
      final sub = db
          .tableUpdates(TableUpdateQuery.onTableName('tracks'))
          .listen((_) => events++);
      await run();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, 1);
    });
  });
}

class _SilentMaker extends FakeCoverMaker {
  @override
  Future<List<CoverRead>> extract({
    required String cacheDir,
    required List<({int trackId, String path})> items,
    required bool sidecars,
  }) async => const [];
}
