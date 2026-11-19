import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/track_duplicates.dart';
import 'package:kanaru/src/library/data/browse/song_ids_query.dart';
import 'package:kanaru/src/library/data/playlists/playlist_reads.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/library/data/scan/library_counts.dart';
import 'package:kanaru/src/library/data/scan/track_row_builder.dart'
    show stemOf;
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/scan/duplicate_hiding.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../library/playlists/support/playlist_fixtures.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int a;
  late int b;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    a = await addSource(db, name: 'a');
    b = await addSource(db, name: 'b');
    await addMount(db, a, root: '/music/a');
    await addMount(db, b, root: '/music/b');
  });

  Future<int> add(
    int source,
    String locator, {
    String? codec,
    int? bitrate,
    String status = TrackStatus.present,
  }) async {
    final id = await addTrack(db, source, locator: locator, status: status);
    await db.customStatement(
      'UPDATE tracks SET codec = ?, bitrate = ?, name_key = ? WHERE id = ?',
      [codec, bitrate, groupKey(stemOf(locator)), id],
    );
    return id;
  }

  Future<void> apply({bool enabled = true}) =>
      applyDuplicateHiding(db, enabled: enabled, rules: libraryDuplicateRules);

  Future<Set<int>> hidden() async => {
    for (final r
        in await db
            .customSelect('SELECT id FROM tracks WHERE dup_hidden = 1')
            .get())
      r.read<int>('id'),
  };

  Future<Set<int>> shown() async => {
    for (final r
        in await db
            .customSelect(
              'SELECT t.id FROM tracks t WHERE ${visibleTrackWhere('t')}',
            )
            .get())
      r.read<int>('id'),
  };

  test(
    'lossless wins over lossy; the extension decides without a codec',
    () async {
      final flac = await add(a, 'x/Song.flac');
      final mp3 = await add(b, 'y/Song.mp3', bitrate: 320000);
      await apply();
      expect(await shown(), {flac});
      expect(await hidden(), {mp3});
    },
  );

  test('a codec beats the extension; .m4a (reported as MP4) is lossy', () async {
    // The tag reader reports `MP4` for every .m4a, AAC and ALAC alike, so an
    // .m4a never counts as lossless: the higher bitrate wins against FLAC-less
    // lossy copies and a FLAC beats it.
    final flac = await add(a, 'One.flac', codec: 'FLAC', bitrate: 100000);
    await add(b, 'One.m4a', codec: 'MP4', bitrate: 900000);
    final m4a = await add(a, 'Two.m4a', codec: 'MP4', bitrate: 256000);
    await add(b, 'Two.mp3', codec: 'MP3', bitrate: 128000);
    await apply();
    expect(await shown(), {flac, m4a});
  });

  test(
    'case, NFC vs NFD and spaces give the same key; accents differ',
    () async {
      final one = await add(a, 'Bài hát.flac');
      await add(b, 'BÀI HÁT.mp3');
      await add(a, 'Bài  hát .m4a');
      // "Bài hát" typed with combining marks (NFD).
      await add(b, 'Ba\u0300i ha\u0301t.ogg');
      final other = await add(a, 'Bai hat.mp3');
      await apply();
      expect(await shown(), {one, other});
    },
  );

  test('FLAC 900, MP3 320 and MP3 128: FLAC is shown', () async {
    final flac = await add(a, 'p/Song.flac', bitrate: 900000);
    await add(a, 'q/Song.mp3', bitrate: 320000);
    await add(b, 'r/Song.mp3', bitrate: 128000);
    await apply();
    expect(await shown(), {flac});
  });

  test(
    'higher bitrate wins among lossy copies; unknown bitrate is last',
    () async {
      await add(a, 'Song.mp3');
      final best = await add(b, 'Song.mp3', bitrate: 128000);
      await apply();
      expect(await shown(), {best});
    },
  );

  test('a tie goes to the folder listed first, then the lower id', () async {
    // Source b has the lower root so it is listed first.
    await db.customStatement(
      "UPDATE source_mounts SET root = '/aaa' WHERE source_id = ?",
      [b],
    );
    final later = await add(a, 'Song.mp3', bitrate: 320000);
    final first = await add(b, 'Song.mp3', bitrate: 320000);
    await apply();
    expect(await shown(), {first});
    expect(await hidden(), {later});

    final lowerId = await add(b, 'dir/Other.mp3', bitrate: 1);
    final higherId = await add(b, 'dir2/Other.mp3', bitrate: 1);
    await apply();
    expect(await hidden(), {later, higherId});
    expect(await shown(), {first, lowerId});
  });

  test('a missing better copy does not hide a present one', () async {
    await add(a, 'Song.flac', status: TrackStatus.missing);
    final mp3 = await add(b, 'Song.mp3');
    await apply();
    expect(await shown(), {mp3});
  });

  test('off shows every copy again; no row is removed', () async {
    final x = await add(a, 'Song.flac');
    final y = await add(b, 'Song.mp3');
    await apply();
    expect(await shown(), {x});
    await apply(enabled: false);
    expect(await shown(), {x, y});
    expect(
      (await db.select(db.tracks).get()).every(
        (t) => t.status == TrackStatus.present,
      ),
      isTrue,
    );
  });

  test('library counts and song lists follow the hiding', () async {
    await add(a, 'Song.flac');
    await add(b, 'Song.mp3');
    await add(b, 'Alone.mp3');
    await apply();
    expect((await countsForFinished(db)).tracks, 2);
    final ids = await songIds(
      db,
      const SongScope.all(),
      SortOrder.single(SortSpec(SortCriterion.title)),
      '',
    );
    expect(ids, hasLength(2));
    await apply(enabled: false);
    expect((await countsForFinished(db)).tracks, 3);
  });

  test('a new copy added later is picked up on the next run', () async {
    final x = await add(a, 'Song.mp3', bitrate: 128000);
    await apply();
    final better = await add(b, 'Song.flac');
    await apply();
    expect(await shown(), {better});
    expect(await hidden(), {x});
  });

  test('a table stream re-emits when hiding changes', () async {
    await add(a, 'Song.flac');
    await add(b, 'Song.mp3');
    final seen = <int>[];
    final sub = db
        .select(db.tracks)
        .watch()
        .listen((rows) => seen.add(rows.where((t) => t.dupHidden == 0).length));
    await pumpEventQueue();
    await apply();
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 2);
    expect(seen.last, 1);
  });

  test(
    'a run that changes nothing does not notify the tracks stream',
    () async {
      await add(a, 'Song.flac');
      await add(b, 'Song.mp3');
      await apply();
      var emits = 0;
      final sub = db.select(db.tracks).watch().listen((_) => emits++);
      await pumpEventQueue();
      final before = emits;
      await apply();
      await apply(enabled: true);
      await pumpEventQueue();
      await sub.cancel();
      expect(emits, before);
    },
  );

  test('a playlist entry of a hidden copy still resolves and counts', () async {
    final f = await PlaylistFixture.open();
    final flac = await f.track('Song');
    final mp3 = TrackId(
      await addTrack(f.db, f.source, locator: 'other/Song.mp3'),
    );
    await f.db.customStatement("UPDATE tracks SET name_key = 'song'");
    final uid = await f.repo.createPlaylist(name: 'P', tracks: [mp3]);
    await applyDuplicateHiding(
      f.db,
      enabled: true,
      rules: libraryDuplicateRules,
    );
    final hidden = await f.db
        .customSelect(
          'SELECT dup_hidden FROM tracks WHERE id = ?',
          variables: [Variable.withInt(mp3.value)],
        )
        .getSingle();
    expect(hidden.read<int>('dup_hidden'), 1);
    final infos = await loadTrackInfos(f.db, [mp3]);
    expect(infos.single.status, TrackAvailability.present);
    final detail = await loadDetail(f.db, uid);
    expect(detail!.entries, hasLength(1));
    expect(
      (await f.repo.watchSummaries().first).playlists.single.trackCount,
      1,
    );
    // The library list shows the other copy only.
    final ids = await songIds(
      f.db,
      const SongScope.all(),
      SortOrder.single(SortSpec(SortCriterion.title)),
      '',
    );
    expect(ids, [flac]);
  });

  /// Inserts 50 000 present rows; each file name (folder-independent) is
  /// shared by [copies] rows, so `copies` 1 = all unique, 2 = all duplicated.
  Future<void> insertMany(int copies) => db.customStatement(
    'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
    'WHERE i < 50000) '
    'INSERT INTO tracks (uid, source_id, locator, rel_path, title, '
    'bitrate, status, added_at, updated_at) '
    "SELECT 'u' || i, CASE WHEN i % 2 = 0 THEN ? ELSE ? END, "
    "'dir' || (i % 7) || '/Bài hát số ' || (i / ?) || '.mp3', "
    "'dir' || (i % 7) || '/Bài hát số ' || (i / ?) || '.mp3', 'T', "
    "128000 + i, 'present', 1, 1 FROM n",
    [a, b, copies, copies],
  );

  /// Writes the keys the scanner writes with each row, as the app does.
  Future<void> keyRows() async {
    final rows = await db.customSelect('SELECT id, locator FROM tracks').get();
    await db.batch((b) {
      for (final r in rows) {
        b.customStatement('UPDATE tracks SET name_key = ? WHERE id = ?', [
          groupKey(stemOf(r.read<String>('locator'))),
          r.read<int>('id'),
        ]);
      }
    });
  }

  Future<void> timedRuns(String label) async {
    await keyRows();
    final sw = Stopwatch()..start();
    await apply();
    final first = sw.elapsedMilliseconds;
    sw
      ..reset()
      ..start();
    await apply();
    final second = sw.elapsedMilliseconds;
    stdout.writeln(
      'dedup 50k $label: first apply $first ms, second (no change) $second ms',
    );
    // Generous bounds: the target is a few hundred ms on a quiet machine.
    expect(first, lessThan(10000));
    expect(second, lessThan(3000));
  }

  test('50k present rows, names unique: one run stays fast', () async {
    await insertMany(1);
    await timedRuns('unique');
    expect(await shown(), hasLength(50000));
  });

  test('50k present rows, every name twice: worst case', () async {
    await insertMany(2);
    await timedRuns('all duplicated');
    expect(await shown(), hasLength(25001));
  });
}
