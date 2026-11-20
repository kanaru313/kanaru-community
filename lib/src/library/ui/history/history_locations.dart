import '../library_locations.dart';

/// Paths of the History and Most played pages, nested under the Playlist tab.
abstract final class HistoryLocations {
  static const String history = '${LibraryLocations.playlists}/history';
  static String track(int id) => '$history/track/$id';

  static const String mostPlayed = '${LibraryLocations.playlists}/most-played';
  static String mostPlayedTrack(int id) => '$mostPlayed/track/$id';
}
