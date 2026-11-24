import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int source;

  setUp(() async {
    db = openTestDb();
    source = await addSource(db);
    await addTrack(db, source, locator: 'a.flac');
  });
  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> intoTracks() async =>
      (await db.customSelect('''
    SELECT m.name AS tbl, f.on_delete AS action
    FROM sqlite_master AS m, pragma_foreign_key_list(m.name) AS f
    WHERE m.type = 'table' AND lower(f."table") = 'tracks'
  ''').get()).map((r) => r.data).toList();

  test('owned child tables reference tracks with RESTRICT', () async {
    final fks = await intoTracks();
    for (final child in trackOwnedChildTables) {
      final fk = fks.where((r) => r['tbl'] == child);
      expect(fk, hasLength(1), reason: child);
      expect(fk.single['action'], 'RESTRICT', reason: child);
    }
  });

  test('public tables referencing tracks include the owned children', () async {
    final tables = (await intoTracks()).map((r) => r['tbl']).toSet();
    expect(
      tables,
      containsAll({'play_log', 'playlist_entries', 'queue_entries'}),
    );
    expect(tables, containsAll(trackOwnedChildTables));
  });

  test(
    'a referenced track cannot be deleted, whatever references it',
    () async {
      final playlist = await addPlaylist(db);
      final cases = <String, Future<void> Function(int)>{
        'play_log': (id) => addPlay(db, id, playedAt: 1),
        'playlist_entries': (id) => addEntry(db, playlist, id, sortKey: 'a'),
        'track_details': (id) => db.customStatement(
          'INSERT INTO track_details (track_id) VALUES (?)',
          [id],
        ),
        'play_stats': (id) => db.customStatement(
          'INSERT INTO play_stats (track_id, play_count) VALUES (?, 0)',
          [id],
        ),
        'track_lyrics_choices': (id) => db.customStatement(
          "INSERT INTO track_lyrics_choices (track_id, mode, updated_at) VALUES (?, 'off', 1)",
          [id],
        ),
        'lyrics_pins': (id) => db.customStatement(
          'INSERT INTO lyrics_pins (track_id, uid, provider_id, provider_name, '
          "remote_id, plain_text, pinned_at, updated_at) VALUES (?, 'pin:x', 'p', 'P', 'r', 'w', 1, 1)",
          [id],
        ),
        'lyrics_rejects': (id) => db.customStatement(
          'INSERT INTO lyrics_rejects (track_id, provider_id, remote_id, rejected_at) '
          "VALUES (?, 'p', 'r', 1)",
          [id],
        ),
        'track_translation_prefs': (id) => db.customStatement(
          "INSERT INTO track_translation_prefs (track_id, target_lang, updated_at) VALUES (?, 'vi', 1)",
          [id],
        ),
      };
      var n = 0;
      for (final entry in cases.entries) {
        final id = await addTrack(db, source, locator: 'ref-${n++}');
        await entry.value(id);
        await expectLater(
          db.customStatement('DELETE FROM tracks WHERE id = ?', [id]),
          throwsConstraint('FOREIGN KEY'),
          reason: entry.key,
        );
      }
    },
  );

  test('a source with tracks cannot be deleted', () async {
    await expectLater(
      db.customStatement('DELETE FROM sources WHERE id = ?', [source]),
      throwsConstraint('FOREIGN KEY'),
    );
  });

  test('a source without tracks takes its excluded folders along', () async {
    final empty = await addSource(db, name: 'empty');
    await db.customStatement(
      'INSERT INTO excluded_folders (uid, source_id, folder_key, display_path, '
      'added_at, updated_at) VALUES (?, ?, ?, ?, 1, 1)',
      ['ex-1', empty, 'x', 'x'],
    );
    await db.customStatement('DELETE FROM sources WHERE id = ?', [empty]);
    {
      final rows = await db
          .customSelect(
            'SELECT 1 FROM excluded_folders WHERE source_id = ?',
            variables: [Variable.withInt(empty)],
          )
          .get();
      expect(rows, isEmpty);
    }
  });

  test('a plugin with config cannot be deleted, only tombstoned', () async {
    const id = 'plugin-00000000000000000000000000000001';
    await db.customStatement(
      'INSERT INTO plugins (install_id, kind, name, version, api_version, '
      "manifest_json, package_sha256, origin, consented_hosts_json, "
      "installed_at, updated_at) VALUES (?, 'lyrics', 'P', 1, 1, '{}', ?, "
      "'file', '[]', 1, 1)",
      [id, 'a' * 64],
    );
    await db.customStatement(
      'INSERT INTO plugin_data (install_id) VALUES (?)',
      [id],
    );
    await expectLater(
      db.customStatement('DELETE FROM plugins WHERE install_id = ?', [id]),
      throwsConstraint('FOREIGN KEY'),
    );
  });
}
