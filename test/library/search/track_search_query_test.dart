import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/library/data/search/track_search_query.dart';

import '../../database/support/test_db.dart';
import 'search_test_support.dart';

void main() {
  late AppDatabase db;
  late int src;
  late TrackSearchQuery search;

  setUp(() async {
    db = openTestDb();
    src = await addSource(db, root: '/music');
    search = TrackSearchQuery(db);
  });
  tearDown(() => db.close());

  Future<List<String>> titles(String q) async => [
    for (final r in (await search.searchTracks(q)).rows) r.title,
  ];

  test('accented query matches folded title', () async {
    await addSearchTrack(
      db,
      src,
      locator: 'a',
      title: 'Đừng Làm Trái Tim Anh Đau',
    );
    await addSearchTrack(db, src, locator: 'b', title: 'Other');
    expect(await titles('đừng làm'), ['Đừng Làm Trái Tim Anh Đau']);
    expect(await titles('ĐỪNG'), ['Đừng Làm Trái Tim Anh Đau']);
  });

  test('mixed-case Vietnamese artist matches', () async {
    await addSearchTrack(
      db,
      src,
      locator: 'a',
      title: 'Song',
      artist: 'Sơn Tùng M-TP',
    );
    expect(await titles('SƠN tùng'), ['Song']);
  });

  test('hidden and missing tracks excluded', () async {
    await addSearchTrack(db, src, locator: 'a', title: 'Love one');
    await addSearchTrack(
      db,
      src,
      locator: 'b',
      title: 'Love two',
      status: TrackStatus.hidden,
    );
    await addSearchTrack(
      db,
      src,
      locator: 'c',
      title: 'Love three',
      status: TrackStatus.missing,
    );
    final dup = await addSearchTrack(db, src, locator: 'd', title: 'Love four');
    await db.customStatement(
      'UPDATE tracks SET dup_hidden = 1 WHERE id = $dup',
    );
    final r = await search.searchTracks('love');
    expect([for (final t in r.rows) t.title], ['Love one']);
    expect(r.total, 1);
  });

  test('offset and total', () async {
    for (var i = 0; i < 5; i++) {
      await addSearchTrack(db, src, locator: 'a$i', title: 'Rock $i');
    }
    final page = await search.searchTracks('rock', offset: 3, limit: 2);
    expect(page.total, 5);
    expect(page.rows, hasLength(2));
    final all = await search.searchTracks('rock');
    expect(
      [for (final t in page.rows) t.id],
      [for (final t in all.rows.skip(3)) t.id],
    );
    final past = await search.searchTracks('rock', offset: 10);
    expect(past.rows, isEmpty);
    expect(past.total, 5);
  });

  test('FTS operators in the query are escaped', () async {
    await addSearchTrack(db, src, locator: 'a', title: 'Hello world');
    for (final q in [
      'hello AND',
      'NEAR(',
      '"unbalanced',
      'title_search:hello',
      '-hello',
      '*',
      '(hello',
      'a\u0000b',
    ]) {
      await expectLater(search.searchTracks(q), completes, reason: q);
    }
    expect(await titles('hello OR'), isEmpty);
    expect(await titles('title_search:hello'), isEmpty);
  });

  test('blank query gives an empty result', () async {
    await addSearchTrack(db, src, locator: 'a', title: 'Hello');
    for (final q in ['', '   ', '\n\t']) {
      final r = await search.searchTracks(q);
      expect(r.rows, isEmpty, reason: q);
      expect(r.total, 0, reason: q);
    }
  });

  test('limit capped at 50', () async {
    for (var i = 0; i < 60; i++) {
      await addSearchTrack(db, src, locator: 'a$i', title: 'Pop $i');
    }
    final r = await search.searchTracks('pop', limit: 500);
    expect(r.rows, hasLength(50));
    expect(r.total, 60);
    final one = await search.searchTracks('pop', limit: 0);
    expect(one.rows, hasLength(1));
  });
}
