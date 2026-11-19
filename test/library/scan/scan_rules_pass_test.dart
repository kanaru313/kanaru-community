import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline.dart';
import 'package:kanaru/src/library/data/scan/track_gc_runner.dart';
import 'package:kanaru/src/library/domain/scan/scan_rules.dart';
import 'package:kanaru/src/library/domain/scan/tag_read.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';

import '../../database/support/test_db.dart';
import 'support/cover_fixtures.dart';
import 'support/pipeline_fixtures.dart';
import 'support/scan_fixtures.dart';

AudioListing _listing(Map<String, int> sizes) => AudioListing(
  audio: [
    for (final e in sizes.entries)
      LocalAudioFile(
        path: '$scanRoot/${e.key}',
        sizeBytes: e.value,
        mtimeMs: 10,
      ),
  ],
);

TagRead _lasting(int durationMs) => tagged(
  't',
  fields: TagFields(title: 't', durationMs: durationMs),
);

void main() {
  late AppDatabase db;
  late Directory cache;
  late FakeTagReader reader;
  late FakeCoverMaker maker;
  late ScanSession session;
  late int sourceId;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    cache = makeCacheDir();
    writeLayoutMarker(cache);
    addTearDown(() => cache.deleteSync(recursive: true));
    reader = FakeTagReader();
    maker = FakeCoverMaker();
    session = ScanSession();
    sourceId = (await addScanFolder(db)).sourceId;
  });

  Future<ScanOutcome> run(MapCatalog catalog, ScanRules rules) => runScanPass(
    pipelineDeps(
      db,
      catalog: catalog,
      reader: reader,
      maker: maker,
      cache: cache,
      scanRules: rules,
    ),
    session,
    StatusLog().hooks(),
  );

  Future<String> status(String name) async =>
      (await trackAt(db, sourceId, name)).status;

  test('default rules scan exactly what they did before', () async {
    final catalog = MapCatalog({
      scanRoot: _listing({'a.mp3': 100, 'b.flac': 100}),
    });
    final out = await run(catalog, ScanRules.defaults);
    expect(out.added, 2);
    expect(await statusCounts(db, sourceId), {'present': 2});
  });

  test(
    'tightening the minimum then relaxing it revives in one session',
    () async {
      reader.byName['mid.mp3'] = _lasting(45000);
      final catalog = MapCatalog({
        scanRoot: _listing({'mid.mp3': 100, 'long.mp3': 100}),
      });
      await run(catalog, ScanRules(minDurationMs: 30000));
      expect(await status('mid.mp3'), 'present');

      // The file changes on disk, so the tag pass reads it and finds it short.
      final changed = MapCatalog({
        scanRoot: AudioListing(
          audio: [
            LocalAudioFile(
              path: '$scanRoot/mid.mp3',
              sizeBytes: 101,
              mtimeMs: 20,
            ),
            LocalAudioFile(
              path: '$scanRoot/long.mp3',
              sizeBytes: 100,
              mtimeMs: 10,
            ),
          ],
        ),
      });
      await run(changed, ScanRules(minDurationMs: 60000));
      expect(await status('mid.mp3'), 'missing');
      expect(await status('long.mp3'), 'present');

      // Same pass again: the memo skips the read.
      final reads = reader.readCount;
      await run(changed, ScanRules(minDurationMs: 60000));
      expect(reader.readCount, reads);
      expect(await status('mid.mp3'), 'missing');

      // Relaxed: read again without a new session, row comes back.
      await run(changed, ScanRules(minDurationMs: 30000));
      expect(reader.readCount, reads + 1);
      expect(await status('mid.mp3'), 'present');
    },
  );

  test('an unchanged short row is dropped by its stored length', () async {
    reader.byName['mid.mp3'] = _lasting(45000);
    final catalog = MapCatalog({
      scanRoot: _listing({'mid.mp3': 100, 'long.mp3': 100}),
    });
    await run(catalog, ScanRules(minDurationMs: 30000));
    reader.calls.clear();
    final out = await run(catalog, ScanRules(minDurationMs: 60000));
    expect(out.completed, isTrue);
    expect(reader.readCount, 0);
    expect(await status('mid.mp3'), 'missing');
    expect(await status('long.mp3'), 'present');
    // Relaxing lists it again: the missing row is read and revived.
    await run(catalog, ScanRules(minDurationMs: 30000));
    expect(await status('mid.mp3'), 'present');
  });

  test('a minimum of zero keeps short files', () async {
    reader.byName['tiny.mp3'] = _lasting(1000);
    final catalog = MapCatalog({
      scanRoot: _listing({'tiny.mp3': 100}),
    });
    await run(catalog, ScanRules(minDurationMs: 0));
    expect(await status('tiny.mp3'), 'present');
    await run(catalog, ScanRules(minDurationMs: 30000));
    expect(await status('tiny.mp3'), 'missing');
  });

  test('a disabled format goes missing and comes back when enabled', () async {
    final catalog = MapCatalog({
      scanRoot: _listing({'a.mp3': 100, 'b.flac': 100}),
    });
    await run(catalog, ScanRules.defaults);
    await run(catalog, ScanRules(allowedExtensions: {'mp3'}));
    expect(await status('a.mp3'), 'present');
    expect(await status('b.flac'), 'missing');
    await run(catalog, ScanRules.defaults);
    expect(await status('b.flac'), 'present');
  });

  test('size rule on stored rows marks only small files missing', () async {
    final all = MapCatalog({
      scanRoot: _listing({
        'small.mp3': 500,
        'big.mp3': 5000000,
        'nosize.mp3': 0,
      }),
    });
    await run(all, ScanRules.defaults);
    await run(all, ScanRules(minSizeBytes: 1000000));
    expect(await status('small.mp3'), 'missing');
    expect(await status('big.mp3'), 'present');
    expect(await status('nosize.mp3'), 'present');
  });

  test('a root emptied only by format rules keeps its rows', () async {
    final catalog = MapCatalog({
      scanRoot: _listing({'a.flac': 100, 'b.flac': 100}),
    });
    await run(catalog, ScanRules.defaults);
    final out = await run(catalog, ScanRules(allowedExtensions: {'mp3'}));
    expect(out.completed, isTrue);
    expect(await statusCounts(db, sourceId), {'present': 2});
  });

  test('a root emptied only by the size rule keeps its rows', () async {
    final catalog = MapCatalog({
      scanRoot: _listing({'a.mp3': 500}),
    });
    await run(catalog, ScanRules.defaults);
    await run(catalog, ScanRules(minSizeBytes: 1000000));
    expect(await statusCounts(db, sourceId), {'present': 1});
  });

  test('a root whose only folder holds .nomedia keeps its rows', () async {
    final catalog = MapCatalog({
      scanRoot: _listing({'a.mp3': 100}),
    });
    await run(catalog, ScanRules.defaults);
    final hidden = MapCatalog({scanRoot: const AudioListing(nomediaOut: 1)});
    final out = await run(hidden, ScanRules(respectNomedia: true));
    expect(out.completed, isTrue);
    expect(await statusCounts(db, sourceId), {'present': 1});
  });

  test('the rules reach the listing: nomedia flag and short filter', () async {
    final catalog = MapCatalog({
      scanRoot: _listing({'a.mp3': 100}),
    });
    await run(catalog, ScanRules(minDurationMs: 90000, respectNomedia: true));
    expect(catalog.shortFilters, [90000]);
    expect(catalog.nomediaFlags, [true]);
  });

  test('a row in a playlist survives GC after a rule drops it', () async {
    final catalog = MapCatalog({
      scanRoot: _listing({'a.flac': 100, 'b.mp3': 100, 'c.flac': 100}),
    });
    await run(catalog, ScanRules.defaults);
    final inList = await trackAt(db, sourceId, 'a.flac');
    final pl = await addPlaylist(db);
    await db
        .into(db.playlistEntries)
        .insert(
          PlaylistEntriesCompanion.insert(
            uid: 'e1',
            playlistId: pl,
            trackId: inList.id,
            sortKey: 'a0',
            addedAt: 1,
            updatedAt: 1,
          ),
        );
    await run(catalog, ScanRules(allowedExtensions: {'mp3'}));
    expect(await status('a.flac'), 'missing');
    await db.customStatement(
      "UPDATE tracks SET missing_since = 1 WHERE status = 'missing'",
    );
    expect(await runTrackGc(db, now: 1 + 8 * 24 * 3600 * 1000), 1);
    expect(await maybeTrackAt(db, sourceId, 'a.flac'), isNotNull);
    expect(await maybeTrackAt(db, sourceId, 'c.flac'), isNull);
    // Back to all formats: the kept row is present again.
    await run(catalog, ScanRules.defaults);
    expect(await status('a.flac'), 'present');
  });
}
