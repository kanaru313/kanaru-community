import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/chip_scope_adapter.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/variables/chip_resolver.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/search/track_hit.dart';
import 'package:kanaru/src/library/domain/search/track_lookup.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';

/// Every id below [visibleBelow] is a visible track.
class _Lookup implements TrackLookup {
  _Lookup(this.visibleBelow);

  final int visibleBelow;
  final asked = <List<int>>[];

  @override
  Future<({List<TrackHit> visible, List<int> absent})> visibleOf(
    List<int> ids,
  ) async {
    asked.add(ids);
    return (
      visible: [
        for (final id in ids)
          if (id < visibleBelow)
            TrackHit(id: TrackId(id), title: 'T$id', artist: 'A', year: 2000),
      ],
      absent: [
        for (final id in ids)
          if (id >= visibleBelow) id,
      ],
    );
  }
}

void main() {
  final db = openTestDb();
  final repo = PlaylistRepository(db);
  tearDownAll(db.close);

  late List<SongScope> scopesAsked;
  late _Lookup lookup;
  var ids = <int>[];

  ChipScopeAdapter adapter() => ChipScopeAdapter(
    scopeIds: (scope) async {
      scopesAsked.add(scope);
      return ids;
    },
    lookup: lookup,
    playlists: repo,
  );

  setUp(() {
    scopesAsked = [];
    lookup = _Lookup(1000);
    ids = [1, 2, 3];
  });

  test('album, artist, genre and language keys become song scopes', () async {
    final a = adapter();
    await a.scopeTracks(ChipKind.album, AlbumKey('ha', 'moi').encode());
    await a.scopeTracks(ChipKind.artist, ArtistKey('ha').encode());
    await a.scopeTracks(ChipKind.genre, 'pop');
    await a.scopeTracks(ChipKind.language, 'vie');
    await a.scopeTracks(ChipKind.language, '');

    expect(scopesAsked, [
      SongScope.album(AlbumKey('ha', 'moi')),
      SongScope.artist(ArtistKey('ha')),
      const SongScope.genre('pop'),
      const SongScope.language('vie'),
      const SongScope.language(null),
    ]);
  });

  test('a key that is not valid reads nothing', () async {
    final a = adapter();
    expect(await a.scopeTracks(ChipKind.album, '***'), isNull);
    expect(await a.scopeTracks(ChipKind.artist, '***'), isNull);
    expect(await a.scopeTracks(ChipKind.genre, ''), isNull);
    expect(await a.scopeTracks(ChipKind.song, 'x'), isNull);
    expect(scopesAsked, isEmpty);
  });

  test('rows come from the visible tracks, in scope order', () async {
    lookup = _Lookup(3);
    ids = [3, 2, 1];

    final r = (await adapter().scopeTracks(ChipKind.genre, 'pop'))!;

    expect(r.total, 3);
    expect([for (final t in r.rows) t.id], [2, 1], reason: '3 is hidden');
    expect(r.rows.first.title, 'T2');
  });

  test('only the first rows are read, the total stays whole', () async {
    ids = List.generate(chipMaxRows + 50, (i) => i + 1);

    final r = (await adapter().scopeTracks(ChipKind.genre, 'pop'))!;

    expect(r.rows, hasLength(chipMaxRows));
    expect(r.total, chipMaxRows + 50);
    expect(lookup.asked.single, hasLength(chipMaxRows));
  });

  test('an empty scope gives no rows', () async {
    ids = [];
    final r = (await adapter().scopeTracks(ChipKind.genre, 'pop'))!;
    expect(r.rows, isEmpty);
    expect(r.total, 0);
  });

  test('a playlist uid maps to its model id; Favorites is 0', () async {
    final uid = await repo.createPlaylist(name: 'Road');

    final id = await adapter().playlistModelId(uid);

    expect(id, isNotNull);
    expect(id, isNot(0));
    expect(await adapter().playlistModelId(PlaylistUids.favorites), 0);
    expect(await adapter().playlistModelId('missing'), isNull);
  });
}
