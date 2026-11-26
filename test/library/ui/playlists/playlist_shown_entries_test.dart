import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/playlists/page/playlist_shown_entries.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

PlaylistEntryView _e(
  String uid,
  int track,
  String title, {
  String? artist,
  int? duration,
  bool missing = false,
}) => PlaylistEntryView(
  id: 0,
  uid: uid,
  info: TrackInfo(
    id: TrackId(track),
    title: title,
    artist: artist,
    durationMs: duration,
    status: missing ? TrackAvailability.missing : TrackAvailability.present,
    relPath: 'p$track',
  ),
);

PlaylistDetail _detail(List<PlaylistEntryView> entries) => PlaylistDetail(
  summary: PlaylistSummary(
    id: 0,
    uid: 'u',
    name: 'N',
    description: '',
    isFavorites: false,
    trackCount: 0,
    durationMs: 0,
    createdAt: 0,
    updatedAt: 0,
    autoCoverKeys: const [],
  ),
  entries: entries,
);

List<String> _uids(ShownEntries s) => [for (final e in s.rows) e.uid];

void main() {
  final order = SortOrder.by(SortCriterion.playlistOrder);
  final byTitle = SortOrder.by(SortCriterion.title);

  test('sorting is stable: equal keys keep playlist order', () {
    final d = _detail([
      _e('a', 1, 'Same'),
      _e('b', 2, 'Same'),
      _e('c', 3, 'Alpha'),
    ]);
    expect(_uids(ShownEntries.of(d, byTitle, '')), ['c', 'a', 'b']);
    expect(_uids(ShownEntries.of(d, order, '')), ['a', 'b', 'c']);
  });

  test('the filter folds case and diacritics and keeps the sort', () {
    final d = _detail([
      _e('a', 1, 'Café del Mar'),
      _e('b', 2, 'Rock'),
      _e('c', 3, 'CAFE noir'),
    ]);
    expect(_uids(ShownEntries.of(d, byTitle, 'cafe')), ['a', 'c']);
    expect(_uids(ShownEntries.of(d, byTitle, 'zzz')), isEmpty);
  });

  test('only the first row of a repeated track is marked', () {
    final d = _detail([_e('a', 1, 'X'), _e('b', 2, 'Y'), _e('c', 1, 'X')]);
    final s = ShownEntries.of(d, order, '');
    expect(s.firstOfTrack, {'a', 'b'});
    expect(s.playable, [TrackId(1), TrackId(2), TrackId(1)]);
  });

  test('missing rows are drawn but never playable, indexes skip them', () {
    final d = _detail([
      _e('a', 1, 'A'),
      _e('b', 2, 'B', missing: true),
      _e('c', 3, 'C'),
    ]);
    final s = ShownEntries.of(d, order, '');
    expect(s.rows, hasLength(3));
    expect(s.playable, [TrackId(1), TrackId(3)]);
    expect(s.playableIndex, [0, -1, 1]);
    expect(s.firstOfTrack, isNot(contains('b')));
  });

  test('the memo returns the same instance for the same inputs', () {
    final memo = ShownEntriesMemo();
    final d = _detail([_e('a', 1, 'A'), _e('b', 2, 'B')]);
    final first = memo.of(d, byTitle, 'a');
    // An equal but distinct sort (value equality) keeps the result.
    expect(
      identical(first, memo.of(d, SortOrder.by(SortCriterion.title), 'a')),
      isTrue,
    );
    expect(identical(first, memo.of(d, byTitle, 'b')), isFalse);
    // A new detail instance (even an equal one) is a new answer.
    final again = memo.of(_detail(d.entries), byTitle, 'b');
    expect(
      identical(again, memo.of(_detail(d.entries), byTitle, 'b')),
      isFalse,
    );
  });

  test('5000 entries sort and filter correctly', () {
    final d = _detail([
      for (var i = 0; i < 5000; i++) _e('e$i', i, 'Song ${5000 - i}'),
    ]);
    final s = ShownEntries.of(d, byTitle, '');
    expect(s.rows.first.info.title, 'Song 1');
    expect(s.rows.last.info.title, 'Song 5000');
    expect(ShownEntries.of(d, byTitle, 'song 4999').rows, hasLength(1));
  });

  test('totals: distinct songs, missing included; length of the available '
      'ones', () {
    final d = _detail([
      _e('a', 1, 'A', duration: 1000),
      _e('b', 1, 'A', duration: 1000),
      _e('c', 2, 'B', duration: 2000),
      _e('d', 3, 'C', duration: 5000, missing: true),
    ]);
    expect(playlistTotals(d), (count: 3, durationMs: 3000));
    expect(ShownEntries.of(d, order, '').distinctCount, 3);
    expect(ShownEntries.of(d, order, 'B').distinctCount, 1);
  });

  test('an all-missing playlist still counts its songs', () {
    final d = _detail([
      _e('a', 1, 'A', missing: true),
      _e('b', 2, 'B', missing: true),
    ]);
    expect(playlistTotals(d), (count: 2, durationMs: 0));
  });
}
