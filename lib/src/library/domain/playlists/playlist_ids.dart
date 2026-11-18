/// Fixed uids of playlist rows.
abstract final class PlaylistUids {
  /// Uid of the Favorites playlist. Equals the database's
  /// `favoritesPlaylistUid` (domain cannot import `database/`; a test keeps
  /// the two equal).
  static const favorites = 'favorites';
}
