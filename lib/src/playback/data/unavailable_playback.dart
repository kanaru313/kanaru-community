import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';
import '../domain/playback_commands.dart';

/// Stand-in until the player exists: every call fails loudly instead of
/// silently doing nothing. The player's provider replaces it.
class UnavailablePlaybackCommands implements PlaybackCommands {
  const UnavailablePlaybackCommands();

  static StateError _error() => StateError('playback not built yet');

  @override
  Future<void> playTracks(
    List<TrackId> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContext context,
  }) => Future.error(_error());

  @override
  Future<void> playNext(List<TrackId> tracks) => Future.error(_error());

  @override
  Future<void> enqueue(List<TrackId> tracks) => Future.error(_error());
}
