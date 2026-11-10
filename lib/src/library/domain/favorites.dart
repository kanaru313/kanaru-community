import '../../media/domain/track_id.dart';

/// Marks tracks as favorite. Favorites is one playlist (`favorites`); an
/// unfavorite is a hard delete of the entry.
abstract interface class FavoritesController {
  /// Favorites or unfavorites all [tracks] in one transaction. Idempotent:
  /// an already favorite track keeps its place. Throws [ArgumentError] (and
  /// changes nothing) when a track does not exist and [favorite] is true.
  Future<void> setFavorite(List<TrackId> tracks, bool favorite);

  Future<void> toggle(TrackId track);
}
