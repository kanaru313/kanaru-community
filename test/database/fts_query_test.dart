import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  group('ftsPrefixQuery', () {
    test('quotes each token as a prefix term', () {
      expect(ftsPrefixQuery('moon  light'), '"moon"* "light"*');
    });

    test('doubles inner quotes', () {
      expect(ftsPrefixQuery('a"b'), '"a""b"*');
    });

    test('control characters act as whitespace', () {
      expect(ftsPrefixQuery('\u0000'), isNull);
      expect(ftsPrefixQuery('a\u0000b'), '"a"* "b"*');
    });

    test('blank input gives null', () {
      expect(ftsPrefixQuery(''), isNull);
      expect(ftsPrefixQuery(' \t\n '), isNull);
    });
  });

  test('adversarial input never raises an FTS syntax error', () async {
    final db = openTestDb();
    addTearDown(db.close);
    const inputs = [
      '"',
      '""',
      '-',
      '-a',
      ':',
      'a:b',
      'artist_search:x',
      'NEAR(',
      'NEAR(a b)',
      '*',
      '**',
      'a*',
      '(',
      ')',
      'AND',
      'OR',
      'NOT',
      'a OR',
      '^a',
      '"a b"',
      "it's",
      r'\',
      '{',
      '+',
      ',',
      'title_sort : x',
      '\u0000',
      'a\u0000b',
      'foo \u0000',
      '\u0001\u007f',
    ];
    for (final input in inputs) {
      final q = ftsPrefixQuery(input);
      if (q == null) continue;
      await db
          .customSelect(
            'SELECT rowid FROM track_search WHERE track_search MATCH ?',
            variables: [Variable.withString(q)],
          )
          .get();
    }
  });

  test('Vietnamese text round-trips through the index', () async {
    final db = openTestDb();
    addTearDown(db.close);
    final source = await addSource(db);
    final id = await addTrack(db, source, locator: 'a.flac');
    await db.customStatement(
      "UPDATE tracks SET title_sort = 'Nắng ấm xa dần', artist_search = 'Sơn Tùng' WHERE id = ?",
      [id],
    );
    for (final text in ['nắng', 'ấm xa', 'sơn tù']) {
      final rows = await db
          .customSelect(
            'SELECT rowid FROM track_search WHERE track_search MATCH ?',
            variables: [Variable.withString(ftsPrefixQuery(text)!)],
          )
          .get();
      expect(rows.map((r) => r.read<int>('rowid')), [id], reason: text);
    }
  });
}
