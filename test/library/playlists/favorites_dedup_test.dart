import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/track_duplicates.dart';
import 'package:kanaru/src/library/data/playlists/playlist_reads.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/scan/duplicate_hiding.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';
import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  late TrackId shown;
  late TrackId hidden;

  Future<void> apply({bool enabled = true}) => applyDuplicateHiding(
    f.db,
    enabled: enabled,
    rules: libraryDuplicateRules,
  );

  Future<List<TrackId>> favoriteIds() async {
    final d = await loadDetail(f.db, PlaylistUids.favorites);
    return [for (final e in d!.entries) e.info.id];
  }

  Future<PlaylistSummary> favSummary() async =>
      (await f.repo.watchSummaries().first).favorites;

  setUp(() async {
    f = await PlaylistFixture.open();
    shown = await f.track('Song');
    hidden = TrackId(await addTrack(f.db, f.source, locator: 'other/Song.mp3'));
    await f.db.customStatement("UPDATE tracks SET name_key = 'song'");
    await f.db.customStatement(
      "UPDATE tracks SET duration_ms = 1000, cover_key = 'cover-shown' "
      'WHERE id = ${shown.value}',
    );
    await f.db.customStatement(
      "UPDATE tracks SET duration_ms = 5000, cover_key = 'cover-hidden' "
      'WHERE id = ${hidden.value}',
    );
    await apply();
  });

  test('favourited hidden copy is not listed, counted, timed or used as cover; '
      'off restores', () async {
    await f.repo.addToPlaylists(
      tracks: [hidden],
      playlistUids: [PlaylistUids.favorites],
    );
    expect(await favoriteIds(), isEmpty);
    var s = await favSummary();
    expect(s.trackCount, 0);
    expect(s.durationMs, 0);
    expect(s.autoCoverKeys, isEmpty);

    await apply(enabled: false);
    expect(await favoriteIds(), [hidden]);
    s = await favSummary();
    expect(s.trackCount, 1);
    expect(s.durationMs, 5000);
    expect(s.autoCoverKeys, ['cover-hidden']);
  });

  test('shown copy is listed when favourited', () async {
    await f.repo.addToPlaylists(
      tracks: [shown],
      playlistUids: [PlaylistUids.favorites],
    );
    expect(await favoriteIds(), [shown]);
    final s = await favSummary();
    expect(s.trackCount, 1);
    expect(s.durationMs, 1000);
    expect(s.autoCoverKeys, ['cover-shown']);
  });

  test('both copies favourited: only the shown one counts', () async {
    await f.repo.addToPlaylists(
      tracks: [shown, hidden],
      playlistUids: [PlaylistUids.favorites],
    );
    expect(await favoriteIds(), [shown]);
    final s = await favSummary();
    expect(s.trackCount, 1);
    expect(s.durationMs, 1000);
    expect(s.autoCoverKeys, ['cover-shown']);
  });

  test('a regular playlist still lists the hidden copy', () async {
    final uid = await f.repo.createPlaylist(name: 'P', tracks: [hidden]);
    final d = await loadDetail(f.db, uid);
    expect(d!.entries.map((e) => e.info.id), [hidden]);
    expect(
      (await f.repo.watchSummaries().first).playlists.single.trackCount,
      1,
    );
  });

  test('Favorites streams re-emit when the setting toggles', () async {
    await f.repo.addToPlaylists(
      tracks: [hidden],
      playlistUids: [PlaylistUids.favorites],
    );
    final counts = <int>[];
    final summaries = f.repo
        .watchSummaries()
        .map((s) => s.favorites.trackCount)
        .asBroadcastStream();
    final sub = summaries.listen(counts.add);
    final lists = <int>[];
    final details = f.repo
        .watchPlaylist(PlaylistUids.favorites)
        .map((d) => d!.entries.length)
        .asBroadcastStream();
    final sub2 = details.listen(lists.add);
    await pumpEventQueue(times: 50);
    await apply(enabled: false);
    await Future.wait([
      summaries.firstWhere((n) => n == 1),
      details.firstWhere((n) => n == 1),
    ]).timeout(const Duration(seconds: 5));
    await sub.cancel();
    await sub2.cancel();
    expect(counts.last, 1);
    expect(lists.last, 1);
    expect(counts.first, 0);
    expect(lists.first, 0);
  });
}
