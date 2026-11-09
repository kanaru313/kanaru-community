import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';

/// Snapshot of what is loaded. Identity is the queue entry, never the path or
/// track id (the same track can be queued twice). Position and duration are
/// not part of it: they tick, and live on the player's own provider.
class NowPlaying {
  const NowPlaying({
    this.entryId,
    this.trackId,
    this.playing = false,
    this.index,
    this.length = 0,
    this.context,
  });

  /// Nothing loaded.
  static const none = NowPlaying();

  final int? entryId;
  final TrackId? trackId;
  final bool playing;

  /// Zero-based position in the queue; [length] is the queue size ("2/9").
  final int? index;
  final int length;
  final PlayContext? context;

  bool get hasTrack => entryId != null;

  @override
  bool operator ==(Object other) =>
      other is NowPlaying &&
      other.entryId == entryId &&
      other.trackId == trackId &&
      other.playing == playing &&
      other.index == index &&
      other.length == length &&
      other.context == context;

  @override
  int get hashCode =>
      Object.hash(entryId, trackId, playing, index, length, context);

  @override
  String toString() =>
      'NowPlaying(entry: $entryId, track: $trackId, playing: $playing, '
      '$index/$length)';
}
