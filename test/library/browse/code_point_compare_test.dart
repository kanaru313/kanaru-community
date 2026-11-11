import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/browse/code_point_compare.dart';

import '../../database/support/test_db.dart';

void main() {
  test('orders by code point, not by UTF-16 unit', () {
    // U+E000 (private use) is one unit; U+1F600 is the pair D83D DE00.
    const bmp = 'a\u{E000}';
    const emoji = 'a\u{1F600}';
    expect(emoji.compareTo(bmp), lessThan(0), reason: 'Dart compareTo');
    expect(compareCodePoints(bmp, emoji), lessThan(0));
    expect(compareCodePoints(emoji, bmp), greaterThan(0));
    expect(compareCodePoints('abc', 'abc'), 0);
    expect(compareCodePoints('ab', 'abc'), lessThan(0));
    expect(compareCodePoints('b', 'abc'), greaterThan(0));
    expect(compareCodePoints('\u{1F600}', '\u{1F601}'), lessThan(0));
  });

  test('gives the order SQLite BINARY gives', () async {
    final AppDatabase db = openTestDb();
    addTearDown(db.close);
    final names = ['a\u{1F600}', 'a\u{E000}', 'a～', 'ab', 'a', 'z', 'é'];
    final rows = await db
        .customSelect(
          'SELECT n FROM (${[for (final n in names) "SELECT '$n' AS n"].join(' UNION ALL ')}) ORDER BY n',
        )
        .get();
    final sql = [for (final r in rows) r.read<String>('n')];
    expect([...names]..sort(compareCodePoints), sql);
  });
}
