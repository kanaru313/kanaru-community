import '../../lyrics/domain/lyrics_status.dart';
import '../../media/domain/track_id.dart';
import '../../playback/domain/now_playing.dart';
import '../../playback/domain/playback_views.dart';
import '../domain/tools/tool_env.dart';

/// [PlaybackPort] over readers of the player's state. The readers hide
/// whether the state comes from a provider or a controller.
class PlaybackPortImpl implements PlaybackPort {
  PlaybackPortImpl({
    required this.readNowPlaying,
    required this.readPosition,
    required this.readQueue,
  });

  final Future<NowPlaying> Function() readNowPlaying;
  final Future<PlaybackPosition> Function() readPosition;
  final Future<QueueView> Function() readQueue;

  @override
  Future<NowPlayingSnapshot> nowPlaying() async {
    final now = await readNowPlaying();
    if (!now.hasTrack) return NowPlayingSnapshot.none;
    final position = await readPosition();
    // The position belongs to the loaded entry; a stale one counts as 0.
    final fresh = position.entryId == now.entryId;
    return NowPlayingSnapshot(
      trackId: now.trackId?.value,
      playing: now.playing,
      index: now.index,
      length: now.length,
      positionMs: fresh ? position.position.inMilliseconds : 0,
      durationMs: fresh ? position.duration?.inMilliseconds : null,
    );
  }

  @override
  Future<QueueSnapshot> queue() async {
    final view = await readQueue();
    return QueueSnapshot(
      items: [
        for (final i in view.items)
          QueueEntryRef(entryId: i.entryId, trackId: i.trackId.value),
      ],
      current: view.current,
    );
  }
}

/// [LyricsPort] over a reader that returns what is stored or local for a
/// track and never starts an online lookup.
class LyricsPortImpl implements LyricsPort {
  LyricsPortImpl(this._read);

  final Future<TrackLyrics> Function(TrackId id) _read;

  @override
  Future<LyricsRead> read(int trackId) async {
    final state = await _read(TrackId(trackId));
    return switch (state) {
      LyricsShown(:final lyrics) => LyricsFound(
        lines: [for (final l in lyrics.lines) l.text],
        synced: lyrics.synced,
      ),
      LyricsLoading() || LyricsSearching() => const LyricsAbsent(
        'lyrics are still being read, try again in a moment',
      ),
      LyricsOff() => const LyricsAbsent('lyrics are turned off for this song'),
      LyricsInstrumental() => const LyricsAbsent('this song is instrumental'),
      _ => const LyricsAbsent('no lyrics available for this song'),
    };
  }
}
