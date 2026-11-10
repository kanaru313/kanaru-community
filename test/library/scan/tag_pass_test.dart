import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/stored_rows.dart';
import 'package:kanaru/src/library/data/scan/tag_pass.dart';
import 'package:kanaru/src/library/domain/scan/scan_folder.dart';
import 'package:kanaru/src/library/domain/scan/tag_read.dart';
import 'package:kanaru/src/storage/domain/local_folder_listing.dart';

import '../../database/support/test_db.dart';
import 'support/scan_fixtures.dart';

SourceListing _listing(
  List<ListedFile> files, {
  Map<String, List<ListedLyrics>> lyrics = const {},
  int excludedOut = 0,
  int shortOut = 0,
  List<String> uncertain = const [],
}) => SourceListing(
  files: files,
  lyrics: lyrics,
  excludedOut: excludedOut,
  shortOut: shortOut,
  uncertainPrefixes: uncertain,
);

List<ListedFile> _files(int n, {int mtime = 10}) => [
  for (var i = 0; i < n; i++)
    listed('f${i.toString().padLeft(5, '0')}.mp3', mtime: mtime),
];

void main() {
  late AppDatabase db;
  late ScanFolder folder;
  late FakeTagReader reader;
  setUp(() async {
    db = openTestDb();
    folder = await addScanFolder(db);
    reader = FakeTagReader();
  });
  tearDown(() => db.close());

  Future<FolderTagResult> run(
    SourceListing listing, {
    bool full = false,
    TagPassDeps? deps,
  }) => runTagPass(folder, listing, deps ?? passDeps(db, reader), full: full);

  Future<int?> lastScanAt() async =>
      (await (db.select(db.sourceMounts)).getSingle()).lastScanAt;

  group('first scan and rescan', () {
    test(
      'inserts every file, counts added and records the scan time',
      () async {
        final r = await run(_listing(_files(5)));
        expect(r.finished, isTrue);
        expect(r.report.added, 5);
        expect(r.report.updated, 0);
        expect(r.report.read, 5);
        expect(await statusCounts(db, folder.sourceId), {'present': 5});
        expect(await lastScanAt(), scanNow);
        final t = await trackAt(db, folder.sourceId, 'f00000.mp3');
        expect(t.title, 'f00000');
        expect(t.revision, '10:100');
        expect(t.addedAt, scanNow);
      },
    );

    test('a rescan with nothing changed reads no file', () async {
      await run(_listing(_files(5)));
      final before = reader.readCount;
      final r = await run(_listing(_files(5)));
      expect(reader.readCount, before);
      expect(r.report.unchanged, 5);
      expect(r.report.added, 0);
      expect(r.finished, isTrue);
    });

    test('a changed file is re-read; id and added_at stay', () async {
      await run(_listing(_files(3)));
      final first = await trackAt(db, folder.sourceId, 'f00001.mp3');
      reader.byName['f00001.mp3'] = tagged('Renamed');
      final r = await run(
        _listing([
          listed('f00000.mp3'),
          listed('f00001.mp3', mtime: 99),
          listed('f00002.mp3'),
        ]),
        deps: passDeps(db, reader, now: 9000),
      );
      expect(r.report.read, 1);
      expect(r.report.updated, 1);
      expect(r.report.added, 0);
      final again = await trackAt(db, folder.sourceId, 'f00001.mp3');
      expect(again.id, first.id);
      expect(again.addedAt, scanNow);
      expect(again.updatedAt, 9000);
      expect(again.title, 'Renamed');
      expect(again.revision, '99:100');
    });

    test('an old keys_version re-reads the row and keeps its covers', () async {
      await run(_listing(_files(1)));
      await db.customStatement(
        'UPDATE tracks SET keys_version = 0, cover_scan_version = 1',
      );
      final r = await run(_listing(_files(1)));
      expect(r.report.read, 1);
      final t = await trackAt(db, folder.sourceId, 'f00000.mp3');
      expect(t.keysVersion, 1);
      expect(t.coverScanVersion, 1);
    });

    test('a changed file resets cover_scan_version', () async {
      await run(_listing(_files(1)));
      await db.customStatement('UPDATE tracks SET cover_scan_version = 1');
      await run(_listing(_files(1, mtime: 55)));
      final t = await trackAt(db, folder.sourceId, 'f00000.mp3');
      expect(t.coverScanVersion, 0);
    });

    test('150 files are written in transactions of at most 64 rows', () async {
      final r = await run(_listing(_files(150)));
      expect(r.report.added, 150);
      expect(r.report.writeBatches, 3);
      expect(reader.calls.every((c) => c.length <= 256), isTrue);
    });

    test('progress is reported after each batch', () async {
      final seen = <(int, int)>[];
      final deps = TagPassDeps(
        db: db,
        reader: reader,
        now: () => scanNow,
        rootStillThere: () async => const RootPresence(present: true),
        onProgress: (d, t) => seen.add((d, t)),
      );
      await run(_listing(_files(70)), deps: deps);
      expect(seen.first, (0, 70));
      expect(seen.last, (70, 70));
      expect(seen.length, 4);
    });

    test('full re-reads files that did not change', () async {
      await run(_listing(_files(3)));
      final before = reader.readCount;
      final r = await run(_listing(_files(3)), full: true);
      expect(reader.readCount, before + 3);
      expect(r.report.updated, 3);
      expect(r.report.added, 0);
    });

    test('names that are not valid UTF-8 are counted in the report', () async {
      await addManyTracks(db, folder.sourceId, 2);
      final r = await run(
        SourceListing(
          files: _files(2),
          undecodableNames: 3,
          undecodableSampleDirs: const ['/music/odd'],
        ),
      );
      expect(r.report.undecodable, 3);
      expect(r.report.undecodableSampleDirs, ['/music/odd']);
    });

    test('the batch size follows the file count', () {
      expect(tagBatchSize(10), 32);
      expect(tagBatchSize(1000), 50);
      expect(tagBatchSize(100000), 256);
    });
  });

  group('missing marks', () {
    test(
      'a file that is no longer listed becomes missing with missing_since',
      () async {
        await run(_listing(_files(3)));
        final r = await run(
          _listing(_files(2)),
          deps: passDeps(db, reader, now: 8000),
        );
        expect(r.report.missingMarked, 1);
        final t = await trackAt(db, folder.sourceId, 'f00002.mp3');
        expect(t.status, 'missing');
        expect(t.missingSince, 8000);
      },
    );

    test('only present rows are marked', () async {
      await addTrack(db, folder.sourceId, locator: 'h.mp3', status: 'hidden');
      await addTrack(db, folder.sourceId, locator: 'm.mp3', status: 'missing');
      final r = await run(_listing([listed('keep.mp3')]));
      expect(r.report.missingMarked, 0);
      expect((await trackAt(db, folder.sourceId, 'h.mp3')).status, 'hidden');
      expect((await trackAt(db, folder.sourceId, 'm.mp3')).missingSince, 1000);
    });

    test('a listed file whose row is missing comes back present', () async {
      await run(_listing(_files(1)));
      await run(_listing([listed('other.mp3')]));
      expect(
        (await trackAt(db, folder.sourceId, 'f00000.mp3')).status,
        'missing',
      );
      final revive = await run(_listing([...(_files(1)), listed('other.mp3')]));
      expect(revive.report.added, 0);
      expect(revive.report.updated, 1);
      final t = await trackAt(db, folder.sourceId, 'f00000.mp3');
      expect(t.status, 'present');
      expect(t.missingSince, isNull);
    });

    test('450 candidates are marked in calls of at most 200 ids', () async {
      final log = StatementLog();
      final loggedDb = openLoggedDb(log);
      addTearDown(loggedDb.close);
      final f = await addScanFolder(loggedDb);
      await addManyTracks(loggedDb, f.sourceId, 450);
      log.updates.clear();
      final r = await runTagPass(
        f,
        _listing(const [], excludedOut: 1),
        passDeps(loggedDb, reader),
      );
      expect(r.report.missingMarked, 450);
      expect(log.updatesMatching("SET status = 'missing'"), 3);
    });

    test('an unreachable folder marks nothing and records no scan', () async {
      await addManyTracks(db, folder.sourceId, 3);
      final r = await run(const SourceListing.unreachable());
      expect(r.finished, isFalse);
      expect(r.report.unreachable, isTrue);
      expect(await statusCounts(db, folder.sourceId), {'present': 3});
      expect(await lastScanAt(), isNull);
    });

    test('0 files with stored rows is suspect: nothing is marked', () async {
      await addManyTracks(db, folder.sourceId, 3);
      final r = await run(_listing(const []));
      expect(r.report.rootSuspect, isTrue);
      expect(r.report.missingMarked, 0);
      expect(await statusCounts(db, folder.sourceId), {'present': 3});
    });

    test('skippedOut alone never lifts the guard', () async {
      await addManyTracks(db, folder.sourceId, 2);
      final r = await run(const SourceListing(skippedOut: 9));
      expect(r.report.rootSuspect, isTrue);
      expect(await statusCounts(db, folder.sourceId), {'present': 2});
    });

    test('0 files with a user filter marks the rows', () async {
      await addManyTracks(db, folder.sourceId, 2);
      final r = await run(_listing(const [], shortOut: 2));
      expect(r.report.missingMarked, 2);
    });

    test('rows under an uncertain folder are kept', () async {
      await addTrack(db, folder.sourceId, locator: 'usb/a.mp3');
      await addTrack(db, folder.sourceId, locator: 'gone.mp3');
      await run(_listing([listed('keep.mp3')], uncertain: ['usb/']));
      expect(
        (await trackAt(db, folder.sourceId, 'usb/a.mp3')).status,
        'present',
      );
      expect(
        (await trackAt(db, folder.sourceId, 'gone.mp3')).status,
        'missing',
      );
    });

    test('a stopped pass marks nothing', () async {
      await addManyTracks(db, folder.sourceId, 2);
      var calls = 0;
      final r = await run(
        _listing([listed('new.mp3')]),
        deps: passDeps(db, reader, shouldStop: () => ++calls > 1),
      );
      expect(r.stopped, isTrue);
      expect(r.finished, isFalse);
      expect((await statusCounts(db, folder.sourceId))['missing'], isNull);
    });
  });

  group('tag errors', () {
    test(
      'NotFound is not listed: no row, an existing row goes missing',
      () async {
        await run(_listing([listed('gone.mp3')]));
        reader.byName['gone.mp3'] = failed('notFound', transient: false);
        reader.byName['ghost.mp3'] = failed('notFound', transient: false);
        final r = await run(
          _listing([listed('gone.mp3', mtime: 2), listed('ghost.mp3')]),
        );
        expect(r.report.staleListing, 2);
        expect(await maybeTrackAt(db, folder.sourceId, 'ghost.mp3'), isNull);
        expect(
          (await trackAt(db, folder.sourceId, 'gone.mp3')).status,
          'missing',
        );
        expect(r.report.missingMarked, 1);
      },
    );

    test('a transient error on an existing row writes nothing', () async {
      reader.byName['a.mp3'] = tagged(
        'Good Title',
        fields: const TagFields(title: 'Good Title', artists: ['Artist One']),
      );
      await run(_listing([listed('a.mp3')]));
      final before = await trackAt(db, folder.sourceId, 'a.mp3');
      reader.byName['a.mp3'] = failed('timeout', transient: true);
      final r = await run(
        _listing([listed('a.mp3', mtime: 77)]),
        deps: passDeps(db, reader, now: 9999),
      );
      expect(r.report.transientSkipped, 1);
      final after = await trackAt(db, folder.sourceId, 'a.mp3');
      expect(after.title, 'Good Title');
      expect(after.titleSearch, 'good title');
      expect(after.mtimeMs, before.mtimeMs);
      expect(after.tagsVersion, before.tagsVersion);
      expect(after.scanError, isNull);
      expect(after.updatedAt, before.updatedAt);
      expect(await artistKeysOf(db, after.id), ['artist one']);
      // The next scan reads it again.
      reader.byName['a.mp3'] = tagged('Fixed');
      await run(_listing([listed('a.mp3', mtime: 77)]));
      expect((await trackAt(db, folder.sourceId, 'a.mp3')).title, 'Fixed');
    });

    test('a transient error leaves a missing row missing', () async {
      await run(_listing([listed('a.mp3')]));
      await run(_listing([listed('other.mp3')]));
      reader.byName['a.mp3'] = failed('io', transient: true);
      await run(_listing([listed('a.mp3'), listed('other.mp3')]));
      expect((await trackAt(db, folder.sourceId, 'a.mp3')).status, 'missing');
    });

    test('a transient error on a new file gives a filename-only row read again later', () async {
      reader.byName['new.mp3'] = failed('timeout', transient: true);
      await run(_listing([listed('new.mp3')]));
      final t = await trackAt(db, folder.sourceId, 'new.mp3');
      expect(t.title, 'new');
      expect(t.tagsVersion, 0);
      expect(t.mtimeMs, isNull);
      expect(t.scanError, 'timeout');
      reader.byName['new.mp3'] = tagged('Real');
      final r = await run(_listing([listed('new.mp3')]));
      expect(r.report.read, 1);
      final again = await trackAt(db, folder.sourceId, 'new.mp3');
      expect(again.id, t.id);
      expect(again.title, 'Real');
      expect(again.tagsVersion, 1);
      expect(again.scanError, isNull);
    });

    test(
      'a permanent error on a new file is stored once and not re-read',
      () async {
        reader.byName['bad.mp3'] = failed('corrupt', transient: false);
        await run(_listing([listed('bad.mp3')]));
        final before = reader.readCount;
        final r = await run(_listing([listed('bad.mp3')]));
        expect(reader.readCount, before);
        expect(r.report.unchanged, 1);
        expect(
          (await trackAt(db, folder.sourceId, 'bad.mp3')).scanError,
          'corrupt',
        );
      },
    );

    test('a reader that throws stops the pass without marks', () async {
      await addManyTracks(db, folder.sourceId, 2);
      reader.throwWith = StateError('no native library');
      final r = await run(_listing([listed('new.mp3')]));
      expect(r.failureKind, 'native_unavailable');
      expect(r.finished, isFalse);
      expect(await statusCounts(db, folder.sourceId), {'present': 2});
    });

    test('a timed-out tag call sets nativeStuck and marks nothing', () async {
      await addManyTracks(db, folder.sourceId, 2);
      reader.hang = Completer<List<TagRead>>();
      final r = await run(
        _listing([listed('new.mp3')]),
        deps: passDeps(db, reader, timeout: const Duration(milliseconds: 30)),
      );
      expect(r.nativeStuck, isTrue);
      expect(r.stopped, isTrue);
      expect(r.finished, isFalse);
      expect(await statusCounts(db, folder.sourceId), {'present': 2});
      var returned = false;
      unawaited(r.pendingNative!.then((_) => returned = true));
      await Future<void>.delayed(Duration.zero);
      expect(returned, isFalse);
      reader.hang!.complete(const []);
      await r.pendingNative;
      expect(returned, isTrue);
    });
  });

  group('short files', () {
    ListedFile short(String locator, {int mtime = 10}) =>
        listed(locator, mtime: mtime);

    TagRead shortRead() =>
        tagged('t', fields: const TagFields(title: 't', durationMs: 5000));

    test(
      'a short file is not stored and not read again in the session',
      () async {
        final memo = ShortFileMemo();
        reader.byName['clip.mp3'] = shortRead();
        final deps = passDeps(db, reader, skipShorterThanMs: 30000, memo: memo);
        final r = await run(
          _listing([short('clip.mp3'), listed('song.mp3')]),
          deps: deps,
        );
        expect(r.report.filteredOut, 1);
        expect(await maybeTrackAt(db, folder.sourceId, 'clip.mp3'), isNull);
        expect(await maybeTrackAt(db, folder.sourceId, 'song.mp3'), isNotNull);
        final reads = reader.readCount;
        final second = await run(
          _listing([short('clip.mp3'), listed('song.mp3')]),
          deps: deps,
        );
        expect(reader.readCount, reads);
        expect(second.report.filteredOut, 1);
      },
    );

    test('an existing row that is now short goes missing', () async {
      await run(_listing([listed('song.mp3')]));
      reader.byName['song.mp3'] = shortRead();
      final r = await run(
        _listing([listed('song.mp3', mtime: 50)]),
        deps: passDeps(db, reader, skipShorterThanMs: 30000),
      );
      expect(r.report.filteredOut, 1);
      expect(r.report.missingMarked, 1);
      expect(
        (await trackAt(db, folder.sourceId, 'song.mp3')).status,
        'missing',
      );
    });

    test('the filter is off when the setting is off', () async {
      reader.byName['clip.mp3'] = shortRead();
      await run(_listing([short('clip.mp3')]));
      expect(await maybeTrackAt(db, folder.sourceId, 'clip.mp3'), isNotNull);
    });
  });

  group('races', () {
    test('an exclusion applied during the read hides old and new rows; added counts ids above the pre-scan max', () async {
      await run(_listing([listed('ex/old.mp3'), listed('top.mp3')]));
      reader.onRead = (_) => applyFolderExclusion(
        db,
        sourceId: folder.sourceId,
        folderKey: 'ex',
        displayPath: 'ex',
        now: 6000,
      );
      final r = await run(
        _listing([
          listed('ex/old.mp3', mtime: 77),
          listed('ex/new.mp3'),
          listed('top.mp3'),
          listed('top2.mp3'),
        ]),
      );
      // ex/new.mp3 was inserted hidden, so only top2.mp3 is a new track.
      expect(r.report.added, 1);
      expect(r.report.updated, 1);
      expect(
        (await trackAt(db, folder.sourceId, 'ex/old.mp3')).status,
        'hidden',
      );
      expect(
        (await trackAt(db, folder.sourceId, 'ex/new.mp3')).status,
        'hidden',
      );
      expect(
        (await trackAt(db, folder.sourceId, 'top2.mp3')).status,
        'present',
      );
    });

    test(
      'an exclusion removed during the read leaves its rows missing',
      () async {
        await run(_listing([listed('ex/a.mp3'), listed('top.mp3')]));
        await applyFolderExclusion(
          db,
          sourceId: folder.sourceId,
          folderKey: 'ex',
          displayPath: 'ex',
          now: 2000,
        );
        reader.onRead = (_) => removeFolderExclusion(
          db,
          sourceId: folder.sourceId,
          folderKey: 'ex',
          now: 6000,
        );
        final r = await run(
          _listing([listed('top.mp3', mtime: 77)], excludedOut: 1),
        );
        expect(r.report.missingMarked, 0);
        final t = await trackAt(db, folder.sourceId, 'ex/a.mp3');
        expect(t.status, 'missing');
        expect(t.missingSince, 6000);
      },
    );

    test('a source removed during the read stops the pass', () async {
      reader.onRead = (_) => removeSource(db, folder.sourceId, 7000);
      final r = await run(_listing(_files(150)));
      expect(r.sourceGone, isTrue);
      expect(r.stopped, isTrue);
      expect(r.finished, isFalse);
      expect((await statusCounts(db, folder.sourceId))['present'], isNull);
    });
  });

  group('sidecars', () {
    ListedLyrics lrc(String locator, {int mtime = 5}) =>
        ListedLyrics(locator: locator, sizeBytes: 7, mtimeMs: mtime);

    test(
      'a sidecar is stored, changed and cleared without re-reading the file',
      () async {
        Future<TrackDetail?> details() async {
          final id = (await trackAt(db, folder.sourceId, 'a.mp3')).id;
          return (db.select(
            db.trackDetails,
          )..where((d) => d.trackId.equals(id))).getSingleOrNull();
        }

        await run(_listing([listed('a.mp3')]));
        expect(await details(), isNull);
        final reads = reader.readCount;

        await run(
          _listing(
            [listed('a.mp3')],
            lyrics: {
              '': [lrc('A.LRC')],
            },
          ),
        );
        expect((await details())!.lrcLocator, 'A.LRC');
        expect((await details())!.lrcRevision, '5:7');

        await run(
          _listing(
            [listed('a.mp3')],
            lyrics: {
              '': [lrc('a.lrc', mtime: 6)],
            },
          ),
        );
        expect((await details())!.lrcRevision, '6:7');

        await run(_listing([listed('a.mp3')]));
        expect((await details())!.lrcLocator, isNull);
        expect(reader.readCount, reads);
      },
    );
  });

  group('data safety', () {
    test('NotFound everywhere while the root is gone marks nothing', () async {
      await run(_listing(_files(3)));
      for (final n in ['f00000.mp3', 'f00001.mp3', 'f00002.mp3']) {
        reader.byName[n] = failed('notFound', transient: false);
      }
      final r = await run(
        _listing(_files(3, mtime: 55)),
        deps: TagPassDeps(
          db: db,
          reader: reader,
          now: () => scanNow,
          rootStillThere: () async => const RootPresence(present: false),
        ),
      );
      expect(r.rootVanished, isTrue);
      expect(r.finished, isFalse);
      expect(r.report.unreachable, isTrue);
      expect(r.report.missingMarked, 0);
      expect(await statusCounts(db, folder.sourceId), {'present': 3});
    });

    test('NotFound rows are marked when the root is still there', () async {
      await run(_listing(_files(3)));
      reader.byName['f00001.mp3'] = failed('notFound', transient: false);
      final r = await run(
        _listing(_files(3, mtime: 55)),
        deps: TagPassDeps(
          db: db,
          reader: reader,
          now: () => scanNow,
          rootStillThere: () async => const RootPresence(present: true),
        ),
      );
      expect(r.finished, isTrue);
      expect(r.report.missingMarked, 1);
      expect(
        (await trackAt(db, folder.sourceId, 'f00001.mp3')).status,
        'missing',
      );
    });

    test('files under a nested mount that vanished are kept', () async {
      await run(
        _listing([listed('nas/a.mp3'), listed('b.mp3'), listed('keep.mp3')]),
      );
      reader.byName['a.mp3'] = failed('notFound', transient: false);
      reader.byName['b.mp3'] = failed('notFound', transient: false);
      final r = await run(
        _listing([
          listed('nas/a.mp3', mtime: 5),
          listed('b.mp3', mtime: 5),
          listed('keep.mp3'),
        ]),
        deps: passDeps(
          db,
          reader,
          presence: () async =>
              const RootPresence(present: true, lostPrefixes: ['nas/']),
        ),
      );
      expect(r.report.keptUnderLostMount, 1);
      expect(r.report.missingMarked, 1);
      expect(
        (await trackAt(db, folder.sourceId, 'nas/a.mp3')).status,
        'present',
      );
      expect((await trackAt(db, folder.sourceId, 'b.mp3')).status, 'missing');
    });

    test('the report notes an unreadable mount table', () async {
      await run(_listing([listed('a.mp3')]));
      reader.byName['a.mp3'] = failed('notFound', transient: false);
      final r = await run(
        _listing([listed('a.mp3', mtime: 9)]),
        deps: passDeps(
          db,
          reader,
          presence: () async =>
              const RootPresence(present: true, mountsUnreadable: true),
        ),
      );
      expect(r.report.mountsUnreadable, isTrue);
      expect(r.report.toString(), contains('MOUNTS UNREADABLE'));
    });

    test('a permanent error on an unchanged file keeps the tags', () async {
      reader.byName['a.mp3'] = tagged(
        'Good',
        fields: const TagFields(title: 'Good', artists: ['Someone']),
      );
      await run(_listing([listed('a.mp3')]));
      // A tag version bump (or full) makes the unchanged file be read again.
      await db.customStatement('UPDATE tracks SET tags_version = 0');
      reader.byName['a.mp3'] = failed('permissionDenied', transient: false);
      final r = await run(_listing([listed('a.mp3')]));
      expect(r.report.permanentKept, 1);
      final t = await trackAt(db, folder.sourceId, 'a.mp3');
      expect(t.title, 'Good');
      expect(t.tagsVersion, 0);
      expect(await artistKeysOf(db, t.id), ['someone']);
      final full = await run(_listing([listed('a.mp3')]), full: true);
      expect(full.report.permanentKept, 1);
      expect((await trackAt(db, folder.sourceId, 'a.mp3')).title, 'Good');
    });

    test(
      'a permanent error on a changed file rewrites it filename-only',
      () async {
        await run(_listing([listed('a.mp3')]));
        reader.byName['a.mp3'] = failed('corrupt', transient: false);
        await run(_listing([listed('a.mp3', mtime: 77)]));
        final t = await trackAt(db, folder.sourceId, 'a.mp3');
        expect(t.scanError, 'corrupt');
        expect(t.revision, '77:100');
      },
    );

    test('a database that refuses every row ends the pass as failed', () async {
      await db.customStatement(
        'CREATE TRIGGER no_inserts BEFORE INSERT ON tracks '
        "BEGIN SELECT RAISE(ABORT, 'disk'); END",
      );
      final r = await run(_listing(_files(150)));
      expect(r.failureKind, 'io');
      expect(r.stopped, isTrue);
      expect(r.finished, isFalse);
      expect(r.report.writeFailed, 3);
      expect(r.report.added, 0);
      expect(await lastScanAt(), isNull);
    });

    test('a stop requested during the native call writes nothing', () async {
      var stop = false;
      reader.onRead = (_) async => stop = true;
      final r = await run(
        _listing(_files(5)),
        deps: passDeps(db, reader, shouldStop: () => stop),
      );
      expect(r.stopped, isTrue);
      expect(await db.select(db.tracks).get(), isEmpty);
    });
  });

  group('stored rows', () {
    test('2500 rows are read in 3 pages', () async {
      await addManyTracks(db, folder.sourceId, 2500);
      var pages = 0;
      final rows = await storedRowsOf(
        db,
        folder.sourceId,
        onPage: () => pages++,
      );
      expect(rows.length, 2500);
      expect(pages, 3);
      expect(rows.first.locator, 'f00000.mp3');
      expect(rows.last.locator, 'f02499.mp3');
    });

    test('hidden and remote rows are not read', () async {
      await addTrack(db, folder.sourceId, locator: 'a.mp3');
      await addTrack(db, folder.sourceId, locator: 'b.mp3', status: 'hidden');
      await addTrack(db, folder.sourceId, locator: 'c.mp3', status: 'missing');
      final rows = await storedRowsOf(db, folder.sourceId);
      expect(rows.map((r) => r.locator), ['a.mp3', 'c.mp3']);
    });

    test('a source over the threshold takes the isolate path and gives the same result', () async {
      await addManyTracks(db, folder.sourceId, 30);
      final listing = _listing(_files(20));
      final r = await run(
        listing,
        deps: passDeps(db, reader, isolateAbove: 10),
      );
      expect(r.report.unchanged, 20);
      expect(r.report.missingMarked, 10);
    });
  });
}
