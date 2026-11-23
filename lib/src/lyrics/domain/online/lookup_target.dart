import '../../../media/domain/track_id.dart';
import 'lyrics_candidate.dart';
import 'lyrics_match.dart';
import 'lyrics_match_keys.dart';

/// What an automatic lookup is for: one track and its tags.
class LookupTarget {
  LookupTarget({
    required this.trackId,
    required this.query,
    this.artists = const [],
  }) : cacheKey = onlineLyricsCacheKey(query);

  final TrackId trackId;
  final LyricsQuery query;

  /// The artists in tag order (the plugin gets them as `artists`).
  final List<String> artists;

  /// Tracks of the same song share it, and so one lookup and one cache row.
  final String cacheKey;

  /// Whether the tags are enough for an automatic lookup.
  bool get searchable => isAutoSearchable(query);

  @override
  bool operator ==(Object other) =>
      other is LookupTarget &&
      other.trackId == trackId &&
      other.cacheKey == cacheKey &&
      other.query.title == query.title &&
      other.query.artist == query.artist &&
      other.query.album == query.album &&
      other.query.duration == query.duration &&
      other.artists.length == artists.length &&
      [for (var i = 0; i < artists.length; i++) other.artists[i] == artists[i]]
          .every((same) => same);

  @override
  int get hashCode => Object.hash(
    trackId,
    cacheKey,
    query.title,
    query.artist,
    query.album,
    query.duration,
    Object.hashAll(artists),
  );
}
