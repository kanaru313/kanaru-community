import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

const _day = 24 * 60 * 60 * 1000;
const _now = 100 * _day;

void main() {
  late AppDatabase db;
  late int local;
  late int plugin;

  setUp(() async {
    db = openTestDb();
    local = await addSource(db, name: 'local');
    plugin = await addSource(db, kind: SourceKind.plugin, name: 'plugin');
  });
  tearDown(() => db.close());

  Future<Set<int>> remaining() async => {
    for (final t in await db.select(db.tracks).get()) t.id,
  };

  test('inside the grace period', () async {
    final ids = [
      await addAgedTrack(
        db,
        local,
        'm',
        TrackStatus.missing,
        at: _now - missingGraceMs + 1,
      ),
      await addAgedTrack(
        db,
        local,
        'h',
        TrackStatus.hidden,
        at: _now - hiddenGraceMs + 1,
      ),
      await addAgedTrack(
        db,
        plugin,
        'r',
        TrackStatus.remote,
        at: _now - remoteGraceMs + 1,
      ),
    ];
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(await remaining(), ids.toSet());
  });

  test('present rows, however old', () async {
    await addAgedTrack(db, local, 'p', TrackStatus.present);
    expect(await collectOrphanTracks(db, now: _now), 0);
  });

  test('hidden in a live source with a disabled mount', () async {
    await addMount(db, local, root: '/m');
    final id = await addAgedTrack(db, local, 'h', TrackStatus.present);
    await setMountEnabled(db, local, false, 1000);
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(await remaining(), {id});
  });

  test('the lyrics choice row of a live track stays', () async {
    final id = await addAgedTrack(db, local, 'p', TrackStatus.present);
    await db.customStatement(
      "INSERT INTO track_lyrics_choices (track_id, mode, updated_at) VALUES (?, 'off', 1)",
      [id],
    );
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(await remaining(), {id});
    final rows = await db
        .customSelect('SELECT 1 FROM track_lyrics_choices')
        .get();
    expect(rows, hasLength(1));
  });

  test('the translation language of a live track stays', () async {
    final id = await addAgedTrack(db, local, 'tp', TrackStatus.present);
    await db.customStatement(
      "INSERT INTO track_translation_prefs (track_id, target_lang, updated_at) VALUES (?, 'vi', 1)",
      [id],
    );
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(
      await db.customSelect('SELECT 1 FROM track_translation_prefs').get(),
      hasLength(1),
    );
  });

  test('the kept lyrics and rejects of a live track stay', () async {
    final id = await addAgedTrack(db, local, 'q', TrackStatus.present);
    await db.customStatement(
      'INSERT INTO lyrics_pins (track_id, uid, provider_id, provider_name, '
      "remote_id, plain_text, pinned_at, updated_at) VALUES (?, 'pin:a', 'p', 'P', 'r', 'w', 1, 1)",
      [id],
    );
    await db.customStatement(
      'INSERT INTO lyrics_rejects (track_id, provider_id, remote_id, rejected_at) '
      "VALUES (?, 'p', 'r', 1)",
      [id],
    );
    expect(await collectOrphanTracks(db, now: _now), 0);
    for (final t in ['lyrics_pins', 'lyrics_rejects']) {
      expect(await db.customSelect('SELECT 1 FROM $t').get(), hasLength(1));
    }
  });

  test(
    'a missing track past grace is collected despite its kept lyrics',
    () async {
      final id = await addAgedTrack(db, local, 'g', TrackStatus.missing);
      await db.customStatement(
        'INSERT INTO lyrics_pins (track_id, uid, provider_id, provider_name, '
        "remote_id, plain_text, pinned_at, updated_at) VALUES (?, 'pin:b', 'p', 'P', 'r', 'w', 1, 1)",
        [id],
      );
      expect(await collectOrphanTracks(db, now: _now), 1);
      expect(await remaining(), isEmpty);
      expect(await db.customSelect('SELECT 1 FROM lyrics_pins').get(), isEmpty);
    },
  );

  test('referenced by a playlist, even past grace', () async {
    final pl = await addPlaylist(db);
    final r = await addAgedTrack(db, plugin, 'r', TrackStatus.remote);
    final m = await addAgedTrack(db, local, 'm', TrackStatus.missing);
    await addEntry(db, pl, r, sortKey: 'a');
    await addEntry(db, pl, m, sortKey: 'b');
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(await remaining(), {r, m});
  });

  test('referenced only by a tombstoned play', () async {
    final id = await addAgedTrack(db, local, 'm', TrackStatus.missing);
    await addPlay(db, id, playedAt: 5, deletedAt: 6);
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(await remaining(), {id});
  });

  test('rated or with a lyrics offset', () async {
    final rated = await addAgedTrack(
      db,
      local,
      'm',
      TrackStatus.missing,
      rating: 4,
    );
    final offset = await addAgedTrack(db, local, 'o', TrackStatus.missing);
    await db.customStatement(
      'UPDATE tracks SET lyrics_offset_ms = 250 WHERE id = ?',
      [offset],
    );
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(await remaining(), {rated, offset});
  });

  test('referenced by a table created at run time', () async {
    await db.customStatement(
      'CREATE TABLE pro_like_refs (id INTEGER PRIMARY KEY, '
      'track_id INTEGER NOT NULL REFERENCES tracks(id) ON DELETE RESTRICT)',
    );
    final kept = await addAgedTrack(db, local, 'k', TrackStatus.missing);
    await addAgedTrack(db, local, 'g', TrackStatus.missing);
    await db.customStatement(
      'INSERT INTO pro_like_refs (track_id) VALUES (?)',
      [kept],
    );
    expect(await collectOrphanTracks(db, now: _now), 1);
    expect(await remaining(), {kept});
  });

  test('a temp table of the same name does not hide a reference', () async {
    final pl = await addPlaylist(db);
    final id = await addAgedTrack(db, local, 'm', TrackStatus.missing);
    await addEntry(db, pl, id, sortKey: 'a');
    await db.customStatement(
      'CREATE TEMP TABLE playlist_entries (track_id INTEGER)',
    );
    expect(await collectOrphanTracks(db, now: _now), 0);
    expect(await remaining(), {id});
  });
}
