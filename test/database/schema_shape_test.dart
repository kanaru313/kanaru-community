import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';

import 'support/pro_like_database.dart';
import 'support/pro_like_database.drift.dart';
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
            "SELECT name FROM sqlite_master WHERE type = '$type'"))
          r['name']! as String,
      };

  test('a fresh database has the six coded tables', () async {
    expect(
      await names('table'),
      containsAll({
        'extension_schema',
        'sources',
        'source_mounts',
        'excluded_folders',
        'tracks',
        'track_details',
      }),
    );
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
      }),
    );
  });

  test('every foreign key into tracks is RESTRICT', () async {
    final into = (await rows(_allForeignKeys)).where((r) => r['parent'] == 'tracks');
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
        fks.any((f) =>
            f['tbl'] == c['tbl'] && f['col'] == c['col'] && f['parent'] == 'tracks'),
        isTrue,
        reason: '${c['tbl']}.${c['col']} has no FK into tracks',
      );
    }
  });

  test('every foreign key column leads an index or is the integer key', () async {
    for (final fk in await rows(_allForeignKeys)) {
      final tbl = fk['tbl']! as String;
      final col = fk['col']! as String;
      final indexed = await rows('''
        SELECT 1 FROM pragma_index_list('$tbl') AS i
        WHERE (SELECT name FROM pragma_index_info(i.name) WHERE seqno = 0) = '$col'
      ''');
      final pk = await rows('''
        SELECT 1 FROM pragma_table_info('$tbl')
        WHERE name = '$col' AND pk = 1 AND type = 'INTEGER'
          AND (SELECT count(*) FROM pragma_table_info('$tbl') WHERE pk > 0) = 1
      ''');
      expect(indexed.isNotEmpty || pk.isNotEmpty, isTrue,
          reason: '$tbl.$col is not indexed');
    }
  });

  group('constraints', () {
    late int sourceId;
    setUp(() async => sourceId = await addSource(db));

    test('status accepts all four values', () async {
      for (final s in TrackStatus.values) {
        await addTrack(db, sourceId, locator: 'a-$s.flac', status: s);
      }
      expect(await db.select(db.tracks).get(), hasLength(4));
    });

    test('status rejects an unknown value', () async {
      expect(addTrack(db, sourceId, locator: 'a.flac', status: 'gone'),
          throwsConstraint('CHECK constraint failed'));
    });

    test('rating accepts 0 and 100, rejects 101', () async {
      await addTrack(db, sourceId, locator: 'a.flac', rating: 0);
      await addTrack(db, sourceId, locator: 'b.flac', rating: 100);
      expect(addTrack(db, sourceId, locator: 'c.flac', rating: 101),
          throwsConstraint('CHECK constraint failed'));
    });

    test('(source_id, locator) is unique', () async {
      await addTrack(db, sourceId, locator: 'a.flac');
      expect(
        addTrack(db, sourceId, locator: 'a.flac', uid: 'other-uid'),
        throwsConstraint('tracks.source_id, tracks.locator'),
      );
    });

    test('a second mount with the same root is rejected', () async {
      await addMount(db, sourceId, root: '/music');
      final other = await addSource(db, name: 'Other');
      expect(addMount(db, other, root: '/music'),
          throwsConstraint('source_mounts.root'));
    });

    test('mounts without a root may repeat', () async {
      await db.into(db.sourceMounts).insert(
          SourceMountsCompanion.insert(sourceId: Value(sourceId), addedAt: 1));
      final other = await addSource(db, name: 'Other');
      await db.into(db.sourceMounts).insert(
          SourceMountsCompanion.insert(sourceId: Value(other), addedAt: 1));
    });

    test('a source with tracks cannot be deleted', () async {
      await addTrack(db, sourceId, locator: 'a.flac');
      expect(db.delete(db.sources).go(), throwsConstraint('FOREIGN KEY'));
    });

    test('deleting a source removes its mount', () async {
      final solo = await addSource(db, name: 'Solo');
      await addMount(db, solo, root: '/solo');
      await (db.delete(db.sources)..where((s) => s.id.equals(solo))).go();
      expect(await db.select(db.sourceMounts).get(), isEmpty);
    });
  });

  test('a Pro-like database joins tracks and RESTRICT blocks the delete', () async {
    final pro = ProLikeDatabase.connect(db.sharedConnection);
    addTearDown(pro.close);
    await db.customSelect('SELECT 1').get(); // public database opens first
    await pro.createOwnTables();

    final source = await addSource(db);
    final track = await addTrack(db, source, locator: 'a.flac');
    await pro.into(pro.proLikeNotes).insert(
        ProLikeNotesCompanion.insert(trackId: track, body: 'note'));
    expect(
      (db.delete(db.tracks)..where((t) => t.id.equals(track))).go(),
      throwsConstraint('FOREIGN KEY'),
    );
    final joined = await (pro.select(pro.tracks)
          ..where((t) => t.id.equals(track)))
        .getSingle();
    expect(joined.locator, 'a.flac');
  });
}
