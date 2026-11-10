import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';

import 'support/test_db.dart';

/// Every foreign key of the database: table, column, parent, on_delete.
const _allForeignKeys = '''
  SELECT m.name AS tbl, f."from" AS col, f."table" AS parent, f.on_delete AS action
  FROM sqlite_master AS m, pragma_foreign_key_list(m.name) AS f
  WHERE m.type = 'table'
''';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> rows(String sql) async =>
      (await db.customSelect(sql).get()).map((r) => r.data).toList();

  Future<Set<String>> names(String type) async => {
    for (final r in await rows(
      "SELECT name FROM sqlite_master WHERE type = '$type'",
    ))
      r['name']! as String,
  };

  test('a fresh database has the coded tables', () async {
    expect(
      await names('table'),
      containsAll({
        'extension_schema',
        'sources',
        'source_mounts',
        'excluded_folders',
        'tracks',
        'track_details',
        'play_log',
        'play_stats',
        'play_stats_ctl',
        'playlists',
        'playlist_entries',
        'saved_items',
        'track_artists',
        'queue_entries',
        'cover_colors',
      }),
    );
  });

  test('play stats triggers and indexes exist', () async {
    expect(
      await names('trigger'),
      containsAll({
        'play_log_stats_insert',
        'play_log_stats_update',
        'play_log_stats_delete',
      }),
    );
    expect(
      await names('index'),
      containsAll({
        'play_log_track_played',
        'play_log_played_at',
        'play_stats_last',
      }),
    );
  });

  test('track_search and its three triggers exist', () async {
    expect(await names('table'), contains('track_search'));
    expect(
      await names('trigger'),
      containsAll({
        'tracks_search_insert',
        'tracks_search_delete',
        'tracks_search_update',
      }),
    );
  });

  test('the update trigger WHEN mentions every indexed column', () async {
    final ftsCols = (await rows(
      "SELECT name FROM pragma_table_info('track_search')",
    )).map((r) => r['name']! as String).toList();
    expect(ftsCols, hasLength(5));
    final sql =
        (await rows(
              "SELECT sql FROM sqlite_master WHERE name = 'tracks_search_update'",
            )).single['sql']!
            as String;
    final when = sql.substring(sql.indexOf('WHEN'), sql.indexOf('BEGIN'));
    for (final c in ftsCols) {
      expect(when, contains('old.$c IS NOT new.$c'), reason: c);
    }
  });

  test('named indexes exist', () async {
    expect(
      await names('index'),
      containsAll({
        'source_mounts_root',
        'excluded_folders_source',
        'tracks_present_title',
        'tracks_status',
        'tracks_added_at',
        'tracks_album_key',
        'tracks_song_key',
        'tracks_rel_path',
        'tracks_language',
        'tracks_tags_version',
        'tracks_keys_version',
        'tracks_cover_version',
        'tracks_genre_key',
        'track_artists_track',
        'queue_entries_track',
        'queue_entries_order',
        'queue_entries_shuffle',
        'playlists_favorites_unique',
        'playlists_mood_name_unique',
        'playlists_origin_unique',
        'playlists_origin_source',
        'playlist_entries_order',
        'playlist_entries_track',
        'saved_items_lookup',
      }),
    );
  });

  test('every foreign key into tracks is RESTRICT', () async {
    final into = (await rows(_allForeignKeys))
        .where((r) => r['parent'] == 'tracks');
    expect(into, isNotEmpty);
    expect(into.map((r) => r['action']), everyElement('RESTRICT'));
  });

  test('mounts and excluded folders cascade from sources', () async {
    final fks = await rows(_allForeignKeys);
    for (final t in ['source_mounts', 'excluded_folders']) {
      final fk = fks.singleWhere((r) => r['tbl'] == t);
      expect(fk['parent'], 'sources');
      expect(fk['action'], 'CASCADE');
    }
  });

  test('collection foreign keys have the documented actions', () async {
    final fks = await rows(_allForeignKeys);
    String action(String tbl, String col) =>
        fks.singleWhere((r) => r['tbl'] == tbl && r['col'] == col)['action']!
            as String;
    expect(action('playlist_entries', 'playlist_id'), 'CASCADE');
    expect(action('playlist_entries', 'track_id'), 'RESTRICT');
    expect(action('playlists', 'origin_source_id'), 'RESTRICT');
    expect(action('saved_items', 'source_id'), 'RESTRICT');
  });

  test('every track_id column has a foreign key into tracks', () async {
    final cols = await rows('''
      SELECT m.name AS tbl, c.name AS col
      FROM sqlite_master AS m, pragma_table_info(m.name) AS c
      WHERE m.type = 'table' AND (c.name = 'track_id' OR c.name LIKE '%\\_track\\_id' ESCAPE '\\')
    ''');
    final fks = await rows(_allForeignKeys);
    expect(cols, isNotEmpty);
    for (final c in cols) {
      expect(
        fks.any(
          (f) =>
              f['tbl'] == c['tbl'] &&
              f['col'] == c['col'] &&
              f['parent'] == 'tracks',
        ),
        isTrue,
        reason: '${c['tbl']}.${c['col']} has no FK into tracks',
      );
    }
  });

  test(
    'every foreign key column leads an index or is the integer key',
    () async {
      for (final fk in await rows(_allForeignKeys)) {
        final tbl = fk['tbl']! as String;
        final col = fk['col']! as String;
        final indexed = await rows('''
        SELECT 1 FROM pragma_index_list('$tbl') AS i
        WHERE i.partial = 0 AND (SELECT name FROM pragma_index_info(i.name) WHERE seqno = 0) = '$col'
      ''');
        final pk = await rows('''
        SELECT 1 FROM pragma_table_info('$tbl')
        WHERE name = '$col' AND pk = 1 AND type = 'INTEGER'
          AND (SELECT count(*) FROM pragma_table_info('$tbl') WHERE pk > 0) = 1
      ''');
        expect(
          indexed.isNotEmpty || pk.isNotEmpty,
          isTrue,
          reason: '$tbl.$col is not indexed',
        );
      }
    },
  );
}
