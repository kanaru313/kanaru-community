import '../../../../media/domain/track_id.dart';
import '../../../domain/browse/sort_order.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../domain/playlists/playlist_sort.dart';

/// What a playlist page lists: the entries in the page's sort, narrowed by
/// the filter, with what the rows and the play buttons need worked out once.
class ShownEntries {
  ShownEntries._(
    this.rows,
    this.playable,
    this.playableIndex,
    this.firstOfTrack,
    this.distinctCount,
  );

  factory ShownEntries.of(PlaylistDetail detail, SortOrder sort, String query) {
    final rows = filterPlaylistEntries(
      sortPlaylistEntries(detail.entries, sort),
      query,
    );
    final playable = <TrackId>[];
    final index = <int>[];
    final seen = <TrackId>{};
    final first = <String>{};
    final distinct = <TrackId>{for (final e in rows) e.info.id};
    for (final e in rows) {
      if (!e.available) {
        index.add(-1);
        continue;
      }
      index.add(playable.length);
      playable.add(e.info.id);
      if (seen.add(e.info.id)) first.add(e.uid);
    }
    return ShownEntries._(
      rows,
      List.unmodifiable(playable),
      List.unmodifiable(index),
      first,
      distinct.length,
    );
  }

  /// Entries to draw, missing ones included.
  final List<PlaylistEntryView> rows;

  /// Ids of the available rows in row order (repeats kept): the queue a tap
  /// or select-all works on. Missing rows never enter it.
  final List<TrackId> playable;

  /// Per row: its place in [playable], or -1 for a missing row.
  final List<int> playableIndex;

  /// Entry uids that are the first row of their track (only that row is
  /// marked as the playing one).
  final Set<String> firstOfTrack;

  /// Distinct songs among [rows], missing ones included.
  final int distinctCount;
}

/// Keeps the last [ShownEntries]: the same detail instance, an equal sort and
/// the same query give back the same object, so a rebuild that changed none
/// of them re-sorts nothing and hands the rows the same id list.
class ShownEntriesMemo {
  PlaylistDetail? _detail;
  SortOrder? _sort;
  String? _query;
  ShownEntries? _value;

  ShownEntries of(PlaylistDetail detail, SortOrder sort, String query) {
    final cached = _value;
    if (cached != null &&
        identical(_detail, detail) &&
        _sort == sort &&
        _query == query) {
      return cached;
    }
    _detail = detail;
    _sort = sort;
    _query = query;
    return _value = ShownEntries.of(detail, sort, query);
  }
}

/// The one song count of a playlist page: distinct songs of the entries
/// shown (missing ones included, so it matches the stored summary and an
/// optimistic removal shows at once) and the total length of the distinct
/// available ones.
({int count, int durationMs}) playlistTotals(PlaylistDetail detail) {
  final seen = <TrackId>{};
  final playable = <TrackId>{};
  var duration = 0;
  for (final e in detail.entries) {
    seen.add(e.info.id);
    if (e.available && playable.add(e.info.id)) {
      duration += e.info.durationMs ?? 0;
    }
  }
  return (count: seen.length, durationMs: duration);
}
