import 'package:flutter_test/flutter_test.dart';

import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  late String p;
  late List<String> e;

  setUp(() async {
    f = await PlaylistFixture.open();
    p = await f.repo.createPlaylist(name: 'P', tracks: await f.tracks(3));
    e = [for (final x in await f.live(p)) x.uid];
  });

  Future<int> rowCount() async =>
      (await f.db
              .customSelect('SELECT COUNT(*) AS c FROM playlist_entries')
              .getSingle())
          .read<int>('c');

  test('removes and commits in one call', () async {
    final removed = await f.repo.removeEntriesNow(p, [e[0], e[2]]);
    expect(removed.map((v) => v.uid), [e[0], e[2]]);
    expect(removed.map((v) => v.id), everyElement(greaterThan(0)));
    expect(await rowCount(), 1, reason: 'rows deleted, no tombstones left');
    expect([for (final x in await f.live(p)) x.uid], [e[1]]);
  });

  test(
    'returns exactly the removed entries when some ids are already gone',
    () async {
      final removed = await f.repo.removeEntriesNow(p, [e[1], 'ghost', e[1]]);
      expect(removed.map((v) => v.uid), [e[1]]);
      expect(await f.repo.removeEntriesNow(p, [e[1]]), isEmpty);
      expect(await f.repo.removeEntriesNow('nope', [e[0]]), isEmpty);
      expect(await f.repo.removeEntriesNow(p, []), isEmpty);
      expect(await rowCount(), 2);
    },
  );

  test("user's pending undo removal in another call is untouched", () async {
    f.clock = 20000;
    final pending = (await f.repo.removeEntries(p, [e[0]]))!;
    // Same millisecond on purpose: the commit must still not take e[0].
    final removed = await f.repo.removeEntriesNow(p, [e[0], e[1]]);
    expect(removed.map((v) => v.uid), [e[1]]);
    expect(await rowCount(), 2, reason: 'tombstone of e[0] and live e[2]');
    expect(await f.repo.undoRemoval(pending), 1);
    expect([for (final x in await f.live(p)) x.uid], [e[0], e[2]]);
  });
}
