import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media/domain/track_id.dart';
import '../../playback/state/playback_position_provider.dart';
import '../../playback/state/playback_providers.dart';
import '../../playback/state/player_ready.dart';
import '../domain/lyrics_status.dart';
import 'track_lyrics_providers.dart';

/// The lyrics of the loaded queue entry, with the entry they belong to so a
/// consumer never pairs another entry's position with these lines.
class PlayingLyrics {
  const PlayingLyrics({this.entryId, this.trackId, required this.lyrics});

  /// Nothing loaded.
  static const none = PlayingLyrics(lyrics: LyricsNone());

  final int? entryId;
  final TrackId? trackId;
  final TrackLyrics lyrics;

  @override
  bool operator ==(Object other) =>
      other is PlayingLyrics &&
      other.entryId == entryId &&
      other.trackId == trackId &&
      other.lyrics == lyrics;

  @override
  int get hashCode => Object.hash(entryId, trackId, lyrics);
}

/// The lyrics of the loaded entry. Loading right after an entry change until
/// the new track's read lands (never the previous track's lines). Before the
/// player exists nothing is read.
final playingLyricsProvider = Provider<PlayingLyrics>((ref) {
  if (!ref.watch(playerCreatedProvider)) return PlayingLyrics.none;
  final (entryId, trackId) = ref.watch(
    nowPlayingProvider.select((n) => (n.value?.entryId, n.value?.trackId)),
  );
  if (entryId == null || trackId == null) return PlayingLyrics.none;
  return PlayingLyrics(
    entryId: entryId,
    trackId: trackId,
    lyrics: ref.watch(trackLyricsProvider(trackId)),
  );
}, isAutoDispose: true);

/// Index of the line being sung, `-1` for none. The position is watched only
/// for shown synced lyrics, and only a change of the index notifies (not every
/// tick). A position that belongs to another entry is `-1`.
final playingLyricsLineProvider = Provider<int>((ref) {
  final playing = ref.watch(playingLyricsProvider);
  final shown = playing.lyrics;
  if (shown is! LyricsShown || !shown.lyrics.synced) return -1;
  final lyrics = shown.lyrics;
  final entryId = playing.entryId;
  return ref.watch(
    playbackPositionProvider.select((p) {
      final position = p.value;
      if (position == null || position.entryId != entryId) return -1;
      return lyrics.lineAt(position.position);
    }),
  );
}, isAutoDispose: true);
