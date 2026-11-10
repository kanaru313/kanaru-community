import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/scan_writer.dart';
import 'package:kanaru/src/library/data/scan/track_row_builder.dart';
import 'package:kanaru/src/library/domain/scan/scan_folder.dart';
import 'package:kanaru/src/library/domain/scan/tag_read.dart';

import '../../database/support/test_db.dart';
import 'support/scan_fixtures.dart';

SnapshotWrite _snap(ScanFolder folder, String locator, TagRead read) =>
    SnapshotWrite(
      buildTrackRow(
        folder: folder,
        file: listed(locator),
        read: read,
        now: scanNow,
      ),
    );

void main() {
  late AppDatabase db;
  late ScanFolder folder;
  setUp(() async {
    db = openTestDb();
    folder = await addScanFolder(db);
  });
  tearDown(() => db.close());

  test('writes snapshot, artists and details in one go', () async {
    final out = await writeBatch(db, folder.sourceId, [
      _snap(
        folder,
        'a.mp3',
        tagged(
          'A',
          fields: const TagFields(title: 'A', artists: ['X; Y'], comment: 'c'),
        ),
      ),
    ]);
    expect(out.sourceGone, isFalse);
    final t = await trackAt(db, folder.sourceId, 'a.mp3');
    expect(out.snapshotIds, [t.id]);
    expect(await artistKeysOf(db, t.id), ['x', 'y']);
    final d = await (db.select(db.trackDetails)).getSingle();
    expect(d.comment, 'c');
  });

  test('more than 64 items is a programming error', () {
    final items = [
      for (var i = 0; i < 65; i++) _snap(folder, 'f$i.mp3', tagged('x')),
    ];
    expect(() => writeBatch(db, folder.sourceId, items), throwsArgumentError);
  });

  test('a removed source writes nothing', () async {
    await removeSource(db, folder.sourceId, 1);
    final out = await writeBatch(db, folder.sourceId, [
      _snap(folder, 'a.mp3', tagged('A')),
    ]);
    expect(out.sourceGone, isTrue);
    expect(await db.select(db.tracks).get(), isEmpty);
  });

  test('a disabled mount writes nothing', () async {
    await setMountEnabled(db, folder.sourceId, false, 1);
    final out = await writeBatch(db, folder.sourceId, [
      _snap(folder, 'a.mp3', tagged('A')),
    ]);
    expect(out.sourceGone, isTrue);
    expect(await db.select(db.tracks).get(), isEmpty);
  });

  test(
    'a transient error on a new file stores a filename-only row to retry',
    () async {
      await writeBatch(db, folder.sourceId, [
        _snap(folder, 'stem.mp3', failed('timeout', transient: true)),
      ]);
      final t = await trackAt(db, folder.sourceId, 'stem.mp3');
      expect(t.title, 'stem');
      expect(t.tagsVersion, 0);
      expect(t.mtimeMs, isNull);
      expect(t.sizeBytes, isNull);
      expect(t.revision, isNull);
      expect(t.scanError, 'timeout');
    },
  );

  test('a permanent error bumps tags_version and records the file', () async {
    await writeBatch(db, folder.sourceId, [
      _snap(folder, 'bad.mp3', failed('corrupt', transient: false)),
    ]);
    final t = await trackAt(db, folder.sourceId, 'bad.mp3');
    expect(t.tagsVersion, 1);
    expect(t.mtimeMs, 10);
    expect(t.revision, '10:100');
    expect(t.scanError, 'corrupt');
  });

  test('a sidecar is added, changed and removed', () async {
    await writeBatch(db, folder.sourceId, [
      _snap(folder, 'a.mp3', tagged('A')),
    ]);
    final id = (await trackAt(db, folder.sourceId, 'a.mp3')).id;
    Future<TrackDetail?> details() => (db.select(
      db.trackDetails,
    )..where((d) => d.trackId.equals(id))).getSingleOrNull();
    expect(await details(), isNull);

    await writeBatch(db, folder.sourceId, [
      LrcWrite(
        trackId: id,
        details: const DetailsPatch(lrcLocator: 'a.lrc', lrcRevision: '1:2'),
      ),
    ]);
    expect((await details())!.lrcLocator, 'a.lrc');

    await writeBatch(db, folder.sourceId, [
      LrcWrite(
        trackId: id,
        details: const DetailsPatch(lrcLocator: 'a.lrc', lrcRevision: '3:4'),
      ),
    ]);
    expect((await details())!.lrcRevision, '3:4');

    await writeBatch(db, folder.sourceId, [
      LrcWrite(
        trackId: id,
        details: const DetailsPatch(lrcLocator: null, lrcRevision: null),
      ),
    ]);
    final cleared = (await details())!;
    expect(cleared.lrcLocator, isNull);
    expect(cleared.lrcRevision, isNull);
  });

  test('a sidecar update keeps the stored comment', () async {
    await writeBatch(db, folder.sourceId, [
      _snap(
        folder,
        'a.mp3',
        tagged(
          'A',
          fields: const TagFields(title: 'A', comment: 'keep'),
        ),
      ),
    ]);
    final id = (await trackAt(db, folder.sourceId, 'a.mp3')).id;
    await writeBatch(db, folder.sourceId, [
      LrcWrite(
        trackId: id,
        details: const DetailsPatch(lrcLocator: 'a.lrc', lrcRevision: '1:2'),
      ),
    ]);
    final d = await (db.select(db.trackDetails)).getSingle();
    expect(d.comment, 'keep');
    expect(d.lrcLocator, 'a.lrc');
  });

  test(
    'a failing row is isolated: the others are written, the bad one counted',
    () async {
      // Two rows with the same locator but a clashing uid would be one row; a
      // row that breaks a CHECK (language_detected 2) fails on its own.
      final good = _snap(folder, 'good.mp3', tagged('Good'));
      final bad = SnapshotWrite(
        BuiltTrack(
          row: _snap(
            folder,
            'bad.mp3',
            tagged('Bad'),
          ).built.row.copyWith(languageDetected: const Value(2)),
          artists: const [],
        ),
      );
      final out = await writeBatchSafely(db, folder.sourceId, [good, bad]);
      expect(out.failed, 1);
      expect(out.ids.length, 2);
      expect(out.ids.first, isNotNull);
      expect(out.ids.last, isNull);
      expect(await maybeTrackAt(db, folder.sourceId, 'good.mp3'), isNotNull);
      expect(await maybeTrackAt(db, folder.sourceId, 'bad.mp3'), isNull);
    },
  );

  test(
    'a database that refuses rows is reported as systemic after 3 failures',
    () async {
      await db.customStatement(
        'CREATE TRIGGER no_inserts BEFORE INSERT ON tracks '
        "BEGIN SELECT RAISE(ABORT, 'disk'); END",
      );
      final items = [
        for (var i = 0; i < 10; i++) _snap(folder, 'f$i.mp3', tagged('x')),
      ];
      final out = await writeBatchSafely(db, folder.sourceId, items);
      expect(out.systemic, isTrue);
      expect(out.failed, 3);
    },
  );

  test('a programming error is rethrown, not retried', () async {
    final bad = SnapshotWrite(
      BuiltTrack(
        row: _snap(
          folder,
          'a.mp3',
          tagged('A'),
        ).built.row.copyWith(titleSearch: const Value.absent()),
        artists: const [],
      ),
    );
    expect(writeBatchSafely(db, folder.sourceId, [bad]), throwsArgumentError);
  });

  test('one bad row alone is a row failure, not a database failure', () async {
    final bad = SnapshotWrite(
      BuiltTrack(
        row: _snap(
          folder,
          'bad.mp3',
          tagged('Bad'),
        ).built.row.copyWith(languageDetected: const Value(2)),
        artists: const [],
      ),
    );
    final out = await writeBatchSafely(db, folder.sourceId, [bad]);
    expect(out.failed, 1);
    expect(out.systemic, isFalse);
    expect(out.sourceGone, isFalse);
  });
}
