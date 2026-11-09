import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/playback_commands.dart';

/// One recorded call of [FakePlaybackCommands].
sealed class PlayCall {
  const PlayCall(this.tracks);
  final List<TrackId> tracks;
}

final class PlayTracksCall extends PlayCall {
  const PlayTracksCall(
    super.tracks, {
    required this.startIndex,
    required this.shuffle,
    required this.context,
  });
  final int startIndex;
  final bool shuffle;
  final PlayContext context;
}

final class PlayNextCall extends PlayCall {
  const PlayNextCall(super.tracks);
}

final class EnqueueCall extends PlayCall {
  const EnqueueCall(super.tracks);
}

/// Records calls and applies the same argument validation as the real
/// player (an empty list or a bad index throws and records nothing).
class FakePlaybackCommands implements PlaybackCommands {
  final List<PlayCall> calls = [];

  @override
  Future<void> playTracks(
    List<TrackId> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContext context,
  }) async {
    if (tracks.isEmpty) throw ArgumentError.value(tracks, 'tracks', 'is empty');
    RangeError.checkValidIndex(startIndex, tracks, 'startIndex');
    calls.add(
      PlayTracksCall(
        List.of(tracks),
        startIndex: startIndex,
        shuffle: shuffle,
        context: context,
      ),
    );
  }

  @override
  Future<void> playNext(List<TrackId> tracks) async =>
      calls.add(PlayNextCall(List.of(tracks)));

  @override
  Future<void> enqueue(List<TrackId> tracks) async =>
      calls.add(EnqueueCall(List.of(tracks)));
}
