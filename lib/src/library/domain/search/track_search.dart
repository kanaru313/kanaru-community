import 'track_hit.dart';

/// Largest page [TrackSearch.searchTracks] returns; a bigger `limit` is cut
/// to it.
const int trackSearchMaxLimit = 50;

/// A query is cut to its first [trackSearchMaxWords] words and
/// [trackSearchMaxChars] characters before matching.
const int trackSearchMaxWords = 16;
const int trackSearchMaxChars = 200;

/// The shared track search backend: full-text search over the library's
/// search forms with the visibility rules of the library lists. The AI tools
/// and the search screen use this one API, so both fold and rank alike.
abstract interface class TrackSearch {
  /// Visible tracks matching [query] (every word a prefix; accents, case and
  /// spacing folded like the indexed columns through `searchForm`, so `dung`
  /// finds `Đừng`), best match first. Only the first [trackSearchMaxWords]
  /// words (and [trackSearchMaxChars] characters) of [query] count; the rest
  /// is ignored.
  /// [limit] is clamped to 1..[trackSearchMaxLimit], a negative [offset]
  /// counts as 0. `total` counts all matches, not just this page. A blank
  /// query, or one with no searchable word, gives an empty result. Operators
  /// in [query] are plain text.
  Future<({List<TrackHit> rows, int total})> searchTracks(
    String query, {
    int offset = 0,
    int limit = trackSearchMaxLimit,
  });
}
