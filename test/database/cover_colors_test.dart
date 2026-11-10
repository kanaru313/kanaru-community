import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  test('round trip, then a newer version replaces the row', () async {
    expect(await coverColorsFor(db, 'k'), isNull);
    await upsertCoverColors(
      db,
      coverKey: 'k',
      seed: 0xFF112233,
      colors: [0xFF112233, 0xFF445566],
      version: 1,
      now: 10,
    );
    var r = (await coverColorsFor(db, 'k'))!;
    expect(r.seed, 0xFF112233);
    expect(r.colors, [0xFF112233, 0xFF445566]);
    expect(r.version, 1);

    await upsertCoverColors(
      db,
      coverKey: 'k',
      seed: 1,
      colors: [1, 2],
      version: 2,
      now: 20,
    );
    r = (await coverColorsFor(db, 'k'))!;
    expect((r.seed, r.version), (1, 2));
    expect(await db.select(db.coverColors).get(), hasLength(1));
  });

  test('an older version does not overwrite a newer one', () async {
    await upsertCoverColors(
      db,
      coverKey: 'k',
      seed: 1,
      colors: [1],
      version: 3,
      now: 1,
    );
    await upsertCoverColors(
      db,
      coverKey: 'k',
      seed: 9,
      colors: [9],
      version: 2,
      now: 2,
    );
    expect((await coverColorsFor(db, 'k'))!.seed, 1);
  });

  test('malformed colors JSON reads as null', () async {
    await db.customStatement(
      "INSERT INTO cover_colors VALUES ('k', 1, 'not json', 1, 1)",
    );
    expect(await coverColorsFor(db, 'k'), isNull);
  });

  test('empty key or palette throws', () async {
    await expectLater(
      upsertCoverColors(
        db,
        coverKey: '',
        seed: 1,
        colors: [1],
        version: 1,
        now: 1,
      ),
      throwsArgumentError,
    );
    await expectLater(
      upsertCoverColors(
        db,
        coverKey: 'k',
        seed: 1,
        colors: [],
        version: 1,
        now: 1,
      ),
      throwsArgumentError,
    );
  });

  test('a stream on cover_colors re-emits', () async {
    final sizes = <int>[];
    final sub = db
        .select(db.coverColors)
        .watch()
        .listen((r) => sizes.add(r.length));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await upsertCoverColors(
      db,
      coverKey: 'k',
      seed: 1,
      colors: [1, 2],
      version: 1,
      now: 1,
    );
    await pumpEventQueue();
    expect(sizes.last, 1);
  });
}
