import 'browse_items.dart';

/// Artists and albums inside a genre or language, for the shelves of its
/// detail page. The page shows a shelf only from two items up and caps it.
class GroupShelves {
  const GroupShelves({required this.artists, required this.albums});

  /// Most tracks in the group first.
  final List<ArtistSummary> artists;

  /// Newest first.
  final List<AlbumSummary> albums;

  @override
  bool operator ==(Object other) =>
      other is GroupShelves &&
      _same(other.artists, artists) &&
      _same(other.albums, albums);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(artists), Object.hashAll(albums));
}

/// Totals of a scope (genre, language) for its banner.
class GroupTotals {
  const GroupTotals({
    required this.tracks,
    required this.artists,
    required this.durationMs,
    required this.detected,
  });

  final int tracks;
  final int artists;
  final int durationMs;

  /// Tracks whose language came from detection.
  final int detected;

  @override
  bool operator ==(Object other) =>
      other is GroupTotals &&
      other.tracks == tracks &&
      other.artists == artists &&
      other.durationMs == durationMs &&
      other.detected == detected;

  @override
  int get hashCode => Object.hash(tracks, artists, durationMs, detected);
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
