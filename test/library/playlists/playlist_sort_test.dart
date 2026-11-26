import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_sort.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

PlaylistEntryView e(
  int id,
  String title, {
  String? artist,
  String? album,
  int? duration,
  int plays = 0,
}) => PlaylistEntryView(
  id: 0,
  uid: 'e$id',
  info: TrackInfo(
    id: TrackId(id),
    title: title,
    artist: artist,
    album: album,
    durationMs: duration,
    playCount: plays,
    status: TrackAvailability.present,
    relPath: 'p$id',
  ),
);

PlaylistSummary p(String uid, String name, int updated, {String d = ''}) =>
    PlaylistSummary(
      id: 0,
      uid: uid,
      name: name,
      description: d,
      isFavorites: false,
      trackCount: 0,
      durationMs: 0,
      createdAt: 0,
      updatedAt: updated,
      autoCoverKeys: const [],
    );

List<String> uids(List<PlaylistEntryView> l) => [for (final x in l) x.uid];

void main() {
  final entries = [
    e(1, 'b', artist: 'Y', duration: 30),
    e(2, 'a', artist: 'X', duration: 10),
    e(3, 'c', artist: 'X'),
    e(4, 'a', artist: null, duration: 20),
  ];

  test('playlistOrder keeps input order, descending reverses it', () {
    final asc = SortOrder.by(SortCriterion.playlistOrder);
    expect(uids(sortPlaylistEntries(entries, asc)), ['e1', 'e2', 'e3', 'e4']);
    expect(uids(sortPlaylistEntries(entries, asc.reversed())), [
      'e4',
      'e3',
      'e2',
      'e1',
    ]);
  });

  test('two criteria: artist then title; null artist last', () {
    final s = SortOrder([
      const SortSpec(SortCriterion.artist),
      const SortSpec(SortCriterion.title, descending: true),
    ]);
    expect(uids(sortPlaylistEntries(entries, s)), ['e3', 'e2', 'e1', 'e4']);
  });

  test('nulls stay last in both directions', () {
    expect(
      uids(sortPlaylistEntries(entries, SortOrder.by(SortCriterion.duration))),
      ['e2', 'e4', 'e1', 'e3'],
    );
    expect(
      uids(
        sortPlaylistEntries(
          entries,
          SortOrder.by(SortCriterion.duration, descending: true),
        ),
      ),
      ['e1', 'e4', 'e2', 'e3'],
    );
  });

  test('ties keep playlist order', () {
    // titles: e2 and e4 are both 'a'.
    expect(
      uids(sortPlaylistEntries(entries, SortOrder.by(SortCriterion.title))),
      ['e2', 'e4', 'e1', 'e3'],
    );
    expect(
      uids(
        sortPlaylistEntries(
          entries,
          SortOrder.by(SortCriterion.title, descending: true),
        ),
      ),
      ['e3', 'e1', 'e2', 'e4'],
    );
  });

  test('playCount sorts numerically', () {
    final l = [e(1, 'x', plays: 2), e(2, 'y', plays: 10), e(3, 'z')];
    expect(
      uids(
        sortPlaylistEntries(
          l,
          SortOrder.by(SortCriterion.playCount, descending: true),
        ),
      ),
      ['e2', 'e1', 'e3'],
    );
  });

  test('canReorder only for ascending playlist order and no query', () {
    final asc = SortOrder.by(SortCriterion.playlistOrder);
    expect(canReorder(asc, ''), isTrue);
    expect(canReorder(asc.reversed(), ''), isFalse);
    expect(canReorder(asc, 'x'), isFalse);
    expect(canReorder(SortOrder.by(SortCriterion.title), ''), isFalse);
    expect(
      canReorder(
        SortOrder([
          const SortSpec(SortCriterion.playlistOrder),
          const SortSpec(SortCriterion.title),
        ]),
        '',
      ),
      isTrue,
    );
  });

  test('filter folds Vietnamese diacritics over title, artist, album', () {
    final l = [
      e(1, 'Hà Nội mùa thu', artist: 'A'),
      e(2, 'x', artist: 'B', album: 'Sài Gòn'),
      e(3, 'y', artist: 'Trịnh'),
    ];
    expect(uids(filterPlaylistEntries(l, 'ha noi')), ['e1']);
    expect(uids(filterPlaylistEntries(l, 'sai gon')), ['e2']);
    expect(uids(filterPlaylistEntries(l, 'trinh')), ['e3']);
    expect(filterPlaylistEntries(l, '  '), l);
  });

  test('sortPlaylists: date desc by default order, ties by name then uid', () {
    final l = [p('1', 'B', 5), p('2', 'a', 5), p('3', 'C', 9), p('4', 'a', 5)];
    final r = sortPlaylists(l, defaultSortOf(BrowseList.playlists));
    expect([for (final x in r) x.uid], ['3', '2', '4', '1']);
    final byName = sortPlaylists(l, SortOrder.by(SortCriterion.name));
    expect([for (final x in byName) x.uid], ['2', '4', '1', '3']);
  });

  test('filterPlaylists matches name and description', () {
    final l = [p('1', 'Chill', 0, d: 'Buổi tối'), p('2', 'Rock', 0)];
    expect([for (final x in filterPlaylists(l, 'buoi toi')) x.uid], ['1']);
    expect([for (final x in filterPlaylists(l, 'rock')) x.uid], ['2']);
  });

  test('text values sort last in descending order too', () {
    final l = [e(1, 'b', album: 'x'), e(2, 'a'), e(3, 'c', album: 'y')];
    expect(uids(sortPlaylistEntries(l, SortOrder.by(SortCriterion.album))), [
      'e1',
      'e3',
      'e2',
    ]);
    expect(
      uids(
        sortPlaylistEntries(
          l,
          SortOrder.by(SortCriterion.album, descending: true),
        ),
      ),
      ['e3', 'e1', 'e2'],
    );
  });

  test('a criterion the list does not offer throws', () {
    expect(
      () => sortPlaylistEntries(entries, SortOrder.by(SortCriterion.year)),
      throwsArgumentError,
    );
    expect(
      () => sortPlaylists([
        p('1', 'a', 0),
        p('2', 'b', 0),
      ], SortOrder.by(SortCriterion.year)),
      throwsArgumentError,
    );
  });
}
