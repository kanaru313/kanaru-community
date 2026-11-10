import '../../media/domain/track_id.dart';
import 'queue_state.dart';
import 'repeat_mode.dart';

/// Where the loaded entry is. Ticks often, so it has its own provider and is
/// not part of `NowPlaying`.
class PlaybackPosition {
  const PlaybackPosition({
    required this.entryId,
    required this.position,
    this.duration,
  });

  static const none = PlaybackPosition(entryId: null, position: Duration.zero);

  final int? entryId;
  final Duration position;
  final Duration? duration;

  @override
  bool operator ==(Object other) =>
      other is PlaybackPosition &&
      other.entryId == entryId &&
      other.position == position &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(entryId, position, duration);
}

/// The queue as the UI lists it (play order). Equal while the list object and
/// the flags are the same.
class QueueView {
  const QueueView({
    this.items = const [],
    this.current,
    this.shuffled = false,
    this.repeat = RepeatMode.off,
  });

  final List<QueueItem> items;
  final int? current;
  final bool shuffled;
  final RepeatMode repeat;

  int get length => items.length;

  TrackId? get currentTrack => current == null ? null : items[current!].trackId;

  @override
  bool operator ==(Object other) =>
      other is QueueView &&
      identical(other.items, items) &&
      other.current == current &&
      other.shuffled == shuffled &&
      other.repeat == repeat;

  @override
  int get hashCode =>
      Object.hash(identityHashCode(items), current, shuffled, repeat);
}
