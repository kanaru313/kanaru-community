import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/library/data/search/track_lookup_query.dart';

import '../../database/support/test_db.dart';
import 'search_test_support.dart';

void main() {
  late AppDatabase db;
  late int src;
  late TrackLookupQuery lookup;

  setUp(() async {
    db = openTestDb();
    src = await addSource(db, root: '/music');
    lookup = TrackLookupQuery(db);
  });
  tearDown(() => db.close());

  test('hidden, missing, remote and dup-hidden ids are absent', () async {
    final ok = await addSearchTrack(db, src, locator: 'a', title: 'A');
    final hidden = await addSearchTrack(
      db,
      src,
      locator: 'b',
      title: 'B',
      status: TrackStatus.hidden,
    );
    final missing = await addSearchTrack(
      db,
      src,
      locator: 'c',
      title: 'C',
      status: TrackStatus.missing,
    );
    final remote = await addSearchTrack(
      db,
      src,
      locator: 'd',
      title: 'D',
      status: TrackStatus.remote,
    );
    final dup = await addSearchTrack(db, src, locator: 'e', title: 'E');
    await db.customStatement(
      'UPDATE tracks SET dup_hidden = 1 WHERE id = $dup',
    );

    final r = await lookup.visibleOf([ok, hidden, missing, remote, dup, 9999]);
    expect([for (final t in r.visible) t.id.value], [ok]);
    expect(r.absent, [hidden, missing, remote, dup, 9999]);
  });

  test('visible ids keep input order', () async {
    final a = await addSearchTrack(
      db,
      src,
      locator: 'a',
      title: 'A',
      artist: 'X',
      album: 'Y',
      year: 1999,
    );
    final b = await addSearchTrack(db, src, locator: 'b', title: 'B');
    final c = await addSearchTrack(db, src, locator: 'c', title: 'C');
    final r = await lookup.visibleOf([c, a, b, a]);
    expect([for (final t in r.visible) t.id.value], [c, a, b]);
    final hit = r.visible[1];
    expect((hit.title, hit.artist, hit.album, hit.year), ('A', 'X', 'Y', 1999));
    expect(r.absent, isEmpty);
  });

  test('empty input gives empty result', () async {
    final r = await lookup.visibleOf(const []);
    expect(r.visible, isEmpty);
    expect(r.absent, isEmpty);
  });

  test('over 999 ids chunked', () async {
    final real = await addSearchTrack(db, src, locator: 'a', title: 'A');
    final ids = [for (var i = 0; i < 2500; i++) 100000 + i, real];
    final r = await lookup.visibleOf(ids);
    expect([for (final t in r.visible) t.id.value], [real]);
    expect(r.absent, hasLength(2500));
    expect(r.absent.first, 100000);
  });
}
