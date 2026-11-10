import 'dart:io';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';

import '../../database/support/test_db.dart';
import 'support/cover_fixtures.dart';
import 'support/pipeline_fixtures.dart';
import 'support/scan_fixtures.dart';

void main() {
  late AppDatabase db;
  late Directory cache;
  late FakeTagReader reader;
  late FakeCoverMaker maker;
  late ScanSession session;
  late StatusLog log;

  setUp(() {
    db = openTestDb();
    addTearDown(db.close);
    cache = makeCacheDir();
    writeLayoutMarker(cache);
    addTearDown(() => cache.deleteSync(recursive: true));
    reader = FakeTagReader();
    maker = FakeCoverMaker();
    session = ScanSession();
    log = StatusLog();
  });

  Future<ScanOutcome> run(
    MapCatalog catalog, {
    MediaPermissionState permissions = grantedBoth,
    bool full = false,
    Duration tagTimeout = const Duration(seconds: 5),
  }) => runScanPass(
    pipelineDeps(
      db,
      catalog: catalog,
      reader: reader,
      maker: maker,
      cache: cache,
      permissions: permissions,
      tagTimeout: tagTimeout,
    ),
    session,
    log.hooks(),
    full: full,
  );

  test('a scan reads tags, makes covers and reports the counts', () async {
    await addScanFolder(db);
    final out = await run(
      MapCatalog({
        scanRoot: listingOf(scanRoot, ['a.mp3', 'b.mp3']),
      }),
    );
    expect(out.failureKind, isNull);
    expect(out.added, 2);
    expect(out.counts?.tracks, 2);
    expect(reader.readCount, 2);
    expect(maker.extractCalls.expand((c) => c), hasLength(2));
    final phases = log.seen.map((s) => s.phase).toSet();
    expect(phases, containsAll([ScanPhase.listing, ScanPhase.tags]));
    expect(phases, contains(ScanPhase.covers));
    expect(log.seen.where((s) => s.phase == ScanPhase.tags).last.done, 2);
  });

  test('a rescan with no change reads nothing', () async {
    await addScanFolder(db);
    final catalog = MapCatalog({
      scanRoot: listingOf(scanRoot, ['a.mp3']),
    });
    await run(catalog);
    reader.calls.clear();
    final out = await run(catalog);
    expect(reader.readCount, 0);
    expect(out.added, 0);
    expect(out.counts?.tracks, 1);
  });

  test('an unreachable folder is skipped and its rows are untouched', () async {
    final lost = await addScanFolder(db, uid: 'src-lost', root: '/lost');
    await addManyTracks(db, lost.sourceId, 3);
    await addScanFolder(db);
    final out = await run(
      MapCatalog({
        scanRoot: listingOf(scanRoot, ['a.mp3']),
      }),
    );
    expect(out.failureKind, isNull);
    expect(await statusCounts(db, lost.sourceId), {'present': 3});
    expect(out.counts?.tracks, 4);
  });

  test('the audio permission denied fails before any read or write', () async {
    await addScanFolder(db);
    final out = await run(
      MapCatalog({
        scanRoot: listingOf(scanRoot, ['a.mp3']),
      }),
      permissions: const MediaPermissionState(
        audio: MediaPermissionStatus.denied,
        images: MediaPermissionStatus.denied,
      ),
    );
    expect(out.failureKind, 'permission');
    expect(out.counts, isNull);
    expect(reader.readCount, 0);
    expect(await db.select(db.tracks).get(), isEmpty);
  });

  test(
    'without the images permission covers are made without sidecars',
    () async {
      await addScanFolder(db);
      await run(
        MapCatalog({
          scanRoot: listingOf(scanRoot, ['a.mp3']),
        }),
        permissions: const MediaPermissionState(
          audio: MediaPermissionStatus.granted,
          images: MediaPermissionStatus.limited,
        ),
      );
      expect(maker.sidecarFlags, isNotEmpty);
      expect(maker.sidecarFlags.every((s) => !s), isTrue);
    },
  );

  test('a stuck root is skipped alone and the others keep scanning', () async {
    final a = await addScanFolder(db, uid: 'src-a', root: '/a');
    await addScanFolder(db, uid: 'src-b', root: '/b');
    final selective = SelectiveReader(reader)..hangUnder.add('/a/');
    final catalog = MapCatalog({
      '/a': listingOf('/a', ['x.mp3']),
      '/b': listingOf('/b', ['y.mp3']),
    });
    final deps = pipelineDeps(
      db,
      catalog: catalog,
      reader: selective,
      maker: maker,
      cache: cache,
      tagTimeout: const Duration(milliseconds: 30),
    );
    final first = await runScanPass(deps, session, log.hooks());
    expect(first.failureKind, 'native_timeout');
    expect(first.pending.map((p) => p.key), ['/a']);
    expect(session.stuck, {'/a'});
    expect(await db.select(db.tracks).get(), hasLength(1));
    expect(await maybeTrackAt(db, a.sourceId, 'x.mp3'), isNull);

    // While the call is out, root a is not read again; b is looked at.
    final calls = selective.hung.length;
    final second = await runScanPass(deps, session, log.hooks());
    expect(second.failureKind, 'native_timeout');
    expect(selective.hung, hasLength(calls));

    // The call returns; the mark is the controller's to clear.
    selective.hung.first.complete(const []);
    await first.pending.single.future;
    session.stuck.remove('/a');
    selective.hangUnder.clear();
    final third = await runScanPass(deps, session, log.hooks());
    expect(third.failureKind, isNull);
    expect(await db.select(db.tracks).get(), hasLength(2));
  });

  test('a database error ends that folder with io, not the scan', () async {
    final failing = _FailingTrackSelects();
    final broken = AppDatabase(
      NativeDatabase.memory(setup: configureConnection).interceptWith(failing),
    );
    addTearDown(broken.close);
    await addScanFolder(broken, uid: 'src-a', root: '/a');
    await addScanFolder(broken, uid: 'src-b', root: '/b');
    final out = await runScanPass(
      pipelineDeps(
        broken,
        catalog: MapCatalog({
          '/a': listingOf('/a', ['x.mp3']),
          '/b': listingOf('/b', ['y.mp3']),
        }),
        reader: reader,
        maker: maker,
        cache: cache,
      ),
      session,
      log.hooks(),
    );
    expect(out.failureKind, 'io');
    expect(out.counts, isNull);
    // Both folders were tried: one failure did not end the pass.
    expect(failing.failures, 2);
    expect(session.stuck, isEmpty);
  });

  test('a stop request ends the pass without counts', () async {
    await addScanFolder(db);
    final out = await runScanPass(
      pipelineDeps(
        db,
        catalog: MapCatalog({
          scanRoot: listingOf(scanRoot, ['a.mp3']),
        }),
        reader: reader,
        maker: maker,
        cache: cache,
      ),
      session,
      log.hooks(stop: () => true),
    );
    expect(out.stopped, isTrue);
    expect(out.counts, isNull);
    expect(reader.readCount, 0);
  });

  test('the short-file filter follows the setting', () async {
    await addScanFolder(db);
    final catalog = MapCatalog({scanRoot: const AudioListing()});
    await run(catalog);
    expect(catalog.shortFilters, [30000]);
  });

  test('cover misses re-extract quietly and stay out of the status', () async {
    final folder = await addScanFolder(db);
    final catalog = MapCatalog({
      scanRoot: listingOf(scanRoot, ['a.mp3']),
    });
    await run(catalog);
    final key = (await coverRows(db)).single['cover_key']! as String;
    maker.extractCalls.clear();
    final before = log.seen.length;
    final out = await runCoverMisses(
      pipelineDeps(
        db,
        catalog: catalog,
        reader: reader,
        maker: maker,
        cache: cache,
      ),
      session,
      log.hooks(),
      {key},
    );
    expect(out.failureKind, isNull);
    expect(maker.extractCalls, hasLength(1));
    expect(log.seen.length, before);
    expect(folder.sourceId, isPositive);
  });
}

/// Fails the stored-row reads of the tag pass.
class _FailingTrackSelects extends QueryInterceptor {
  int failures = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('MAX(id)') && statement.contains('tracks')) {
      failures++;
      throw StateError('disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}
