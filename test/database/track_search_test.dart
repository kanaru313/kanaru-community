import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int sourceId;
  setUp(() async {
    db = openTestDb();
    sourceId = await addSource(db);
  });
  tearDown(() => db.close());

  Future<int> add(String locator, String titleSort, {String? artist}) => db
      .into(db.tracks)
      .insert(
        TracksCompanion.insert(
          uid: 'uid-$locator',
          sourceId: sourceId,
          locator: locator,
          relPath: locator,
          title: titleSort,
          titleSearch: Value(titleSort),
          artistSearch: Value(artist),
          addedAt: 1,
          updatedAt: 1,
        ),
      );

  Future<List<int>> match(String text) async {
    final q = ftsPrefixQuery(text)!;
    final rows = await db
        .customSelect(
          'SELECT rowid FROM track_search WHERE track_search MATCH ?',
          variables: [Variable.withString(q)],
        )
        .get();
    return [for (final r in rows) r.read<int>('rowid')];
  }

  Future<void> integrity() => db.customStatement(
    "INSERT INTO track_search(track_search) VALUES('integrity-check')",
  );

  test('insert is found by prefix', () async {
    final id = await add('a.flac', 'moonlight', artist: 'beethoven');
    expect(await match('moon'), [id]);
    expect(await match('beet'), [id]);
    expect(await match('zzz'), isEmpty);
  });

  test('changing title_search replaces the indexed term', () async {
    final id = await add('a.flac', 'moonlight');
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(titleSearch: Value('sunrise')),
    );
    expect(await match('moon'), isEmpty);
    expect(await match('sun'), [id]);
  });

  test('changing only revision leaves the index alone', () async {
    final id = await add('a.flac', 'moonlight');
    Future<int> changes() async =>
        (await db.customSelect('SELECT total_changes() AS n').getSingle())
            .read<int>('n');
    final before = await changes();
    // The upsert rewrites every snapshot column, but the indexed ones are
    // unchanged, so the WHEN clause must keep the trigger from firing.
    await upsertTrackSnapshot(
      db,
      db.tracks,
      TracksCompanion.insert(
        uid: 'uid-a.flac',
        sourceId: sourceId,
        locator: 'a.flac',
        relPath: 'a.flac',
        title: 'moonlight',
        titleSearch: const Value('moonlight'),
        revision: const Value('r2'),
        addedAt: 1,
        updatedAt: 2,
      ),
    );
    expect(await changes() - before, 1);
    expect(await match('moon'), [id]);
    await integrity();
  });

  test('delete removes the row from the index', () async {
    final id = await add('a.flac', 'moonlight');
    await (db.delete(db.tracks)..where((t) => t.id.equals(id))).go();
    expect(await match('moon'), isEmpty);
  });

  test('integrity check passes after a mixed sequence', () async {
    final a = await add('a.flac', 'alpha', artist: 'x');
    final b = await add('b.flac', 'beta');
    await add('c.flac', 'gamma');
    await (db.update(db.tracks)..where((t) => t.id.equals(a))).write(
      const TracksCompanion(artistSearch: Value('y')),
    );
    await (db.update(db.tracks)..where((t) => t.id.equals(b))).write(
      const TracksCompanion(titleSearch: Value('delta')),
    );
    await (db.delete(db.tracks)..where((t) => t.id.equals(a))).go();
    await integrity();
    expect(await match('delta'), [b]);
  });

  test('accents are kept', () async {
    final id = await add('a.flac', 'đường');
    expect(await match('đườ'), [id]);
    expect(await match('duong'), isEmpty);
  });

  test(
    'search forms of a Vietnamese name are found by an unaccented prefix',
    () async {
      // The scanner stores the search form; the query gets the same form.
      final stored = searchForm('Vũ Cát Tường');
      final id = await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              uid: 'uid-vu',
              sourceId: sourceId,
              locator: 'vu.flac',
              relPath: 'vu.flac',
              title: 'Vũ Cát Tường',
              titleSearch: Value(stored),
              artistSearch: Value(stored),
              addedAt: 1,
              updatedAt: 1,
            ),
          );
      expect(await match(searchForm('vu')), [id]);
      expect(await match(searchForm('VŨ')), [id]);
      // NFD input: u + combining tilde.
      expect(await match(searchForm('vu\u0303')), [id]);
      expect(await match(searchForm('tuong cat')), [id]);
      expect(await match(searchForm('xyz')), isEmpty);
    },
  );

  test('a sort-title change does not change what search finds', () async {
    final id = await add('a.flac', 'moonlight');
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(titleSort: Value('zzz sonata')),
    );
    expect(await match('moon'), [id]);
    expect(await match('zzz'), isEmpty);
  });
}
