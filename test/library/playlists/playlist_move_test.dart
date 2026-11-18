import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';

import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  late String p;
  late List<String> e;
  late List<int> t;

  setUp(() async {
    f = await PlaylistFixture.open();
    final tracks = await f.tracks(4);
    t = [for (final x in tracks) x.value];
    p = await f.repo.createPlaylist(name: 'P', tracks: tracks);
    e = [for (final x in await f.live(p)) x.uid];
  });

  test('to the start', () async {
    expect(
      await f.repo.moveEntry(p, e[2], afterEntryUid: null),
      PlaylistMove.moved,
    );
    expect(await f.liveTracks(p), [t[2], t[0], t[1], t[3]]);
  });

  test('between two entries, writes exactly one entry row', () async {
    f.clock = 20000;
    expect(
      await f.repo.moveEntry(p, e[3], afterEntryUid: e[0]),
      PlaylistMove.moved,
    );
    expect(await f.liveTracks(p), [t[0], t[3], t[1], t[2]]);
    final changed = await f.db
        .customSelect(
          'SELECT uid FROM playlist_entries WHERE updated_at = 20000',
        )
        .get();
    expect(changed, hasLength(1));
    expect(await f.updatedAt(p), 20000);
    f.expectUniqueKeys(await f.allKeys(p));
  });

  test('to the end', () async {
    await f.repo.moveEntry(p, e[0], afterEntryUid: e[3]);
    expect(await f.liveTracks(p), [t[1], t[2], t[3], t[0]]);
  });

  test('already there is unchanged and writes nothing', () async {
    f.clock = 20000;
    expect(
      await f.repo.moveEntry(p, e[0], afterEntryUid: null),
      PlaylistMove.unchanged,
    );
    expect(
      await f.repo.moveEntry(p, e[2], afterEntryUid: e[1]),
      PlaylistMove.unchanged,
    );
    expect(
      await f.repo.moveEntry(p, e[2], afterEntryUid: e[2]),
      PlaylistMove.unchanged,
    );
    expect(await f.updatedAt(p), 10000);
  });

  test('gone playlist, entry or after entry', () async {
    expect(
      await f.repo.moveEntry('nope', e[0], afterEntryUid: null),
      PlaylistMove.gone,
    );
    expect(
      await f.repo.moveEntry(p, 'nope', afterEntryUid: null),
      PlaylistMove.gone,
    );
    expect(
      await f.repo.moveEntry(p, e[0], afterEntryUid: 'nope'),
      PlaylistMove.gone,
    );
    await f.repo.removeEntries(p, [e[1]]);
    expect(
      await f.repo.moveEntry(p, e[0], afterEntryUid: e[1]),
      PlaylistMove.gone,
    );
  });

  test('repeated moves keep keys unique', () async {
    for (var i = 0; i < 30; i++) {
      await f.repo.moveEntry(p, e[3], afterEntryUid: e[0]);
      await f.repo.moveEntry(p, e[2], afterEntryUid: null);
    }
    f.expectUniqueKeys(await f.allKeys(p));
    expect((await f.liveTracks(p)).length, 4);
  });
}
