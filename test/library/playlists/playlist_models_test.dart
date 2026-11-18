import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

PlaylistSummary summary({List<String> covers = const ['a']}) => PlaylistSummary(
  uid: 'u',
  name: 'n',
  description: '',
  isFavorites: false,
  trackCount: 1,
  durationMs: 10,
  createdAt: 1,
  updatedAt: 2,
  autoCoverKeys: covers,
);

PlaylistEntryView entry(String uid, int id, TrackAvailability s) =>
    PlaylistEntryView(
      uid: uid,
      info: TrackInfo(id: TrackId(id), title: 't$id', status: s, relPath: 'p'),
    );

void main() {
  test('summaries compare element-wise', () {
    expect(summary(), summary());
    expect(summary().hashCode, summary().hashCode);
    expect(summary(), isNot(summary(covers: ['b'])));
    expect(
      PlaylistSummaries(playlists: [summary()], favorites: summary()),
      PlaylistSummaries(playlists: [summary()], favorites: summary()),
    );
  });

  test('availability: missing and hidden are not available, remote is', () {
    expect(entry('a', 1, TrackAvailability.present).available, isTrue);
    expect(entry('a', 1, TrackAvailability.remote).available, isTrue);
    expect(entry('a', 1, TrackAvailability.missing).available, isFalse);
    expect(entry('a', 1, TrackAvailability.hidden).available, isFalse);
  });

  test('detail counts unavailable and duplicates, lists playable ids', () {
    final d = PlaylistDetail(
      summary: summary(),
      entries: [
        entry('a', 1, TrackAvailability.present),
        entry('b', 1, TrackAvailability.present),
        entry('c', 2, TrackAvailability.missing),
        entry('d', 3, TrackAvailability.present),
      ],
    );
    expect(d.unavailableCount, 1);
    expect(d.duplicateCount, 1);
    expect(d.playableIds, [TrackId(1), TrackId(1), TrackId(3)]);
    expect(d, PlaylistDetail(summary: summary(), entries: List.of(d.entries)));
  });

  test('add result and removal have value equality', () {
    const o = PlaylistAddOutcome(
      uid: 'u',
      created: false,
      added: 1,
      skipped: 0,
      movedToEnd: 0,
    );
    AddToPlaylistsResult r() => AddToPlaylistsResult(
      outcomes: [o],
      goneUids: ['x'],
      addedTrackCount: 1,
      skippedTrackCount: 0,
    );
    expect(r(), r());
    expect(
      PlaylistRemoval(playlistUid: 'p', entryUids: ['a'], removedAt: 1),
      PlaylistRemoval(playlistUid: 'p', entryUids: ['a'], removedAt: 1),
    );
  });

  test('detail differs on reorder and on a different track', () {
    final a = entry('a', 1, TrackAvailability.present);
    final b = entry('b', 2, TrackAvailability.present);
    PlaylistDetail d(List<PlaylistEntryView> l) =>
        PlaylistDetail(summary: summary(), entries: l);
    expect(d([a, b]), isNot(d([b, a])));
    expect(d([a, b]), isNot(d([a, entry('b', 3, TrackAvailability.present)])));
    expect(a, isNot(entry('a', 2, TrackAvailability.present)));
    expect(a, isNot(entry('z', 1, TrackAvailability.present)));
  });
}
