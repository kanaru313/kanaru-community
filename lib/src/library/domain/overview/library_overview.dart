/// Totals of the visible local library.
class LibraryOverview {
  const LibraryOverview({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.playlists,
    required this.totalDurationMs,
  });

  /// Visible songs (not hidden, missing or duplicate-hidden).
  final int songs;
  final int albums;
  final int artists;

  /// User playlists: Favorites, saved queues and mood playlists not counted.
  final int playlists;

  /// Sum of the visible songs' lengths; songs without a length add nothing.
  final int totalDurationMs;
}

/// Reads [LibraryOverview] with SQL aggregates, never loading the tracks.
abstract interface class LibraryOverviewReader {
  Future<LibraryOverview> read();
}
