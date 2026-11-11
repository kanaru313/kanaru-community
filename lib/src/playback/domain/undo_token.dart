import 'queue_state.dart';

/// What `undo` needs to put removed entries back: the entries with the keys
/// they had, the entry that was current, and the player facts the controller
/// restores (position, intent). A pure value; the controller expires it.
class UndoToken {
  const UndoToken({
    required this.items,
    required this.previousCurrentEntryId,
    required this.positionMs,
    required this.wasPlaying,
    this.playNextRunIds = const {},
  });

  /// Removed entries in the play order they had.
  final List<QueueItem> items;

  /// Entry that was current before the removal; null when none.
  final int? previousCurrentEntryId;

  /// Playback position of the current entry at removal time.
  final int positionMs;
  final bool wasPlaying;

  /// Entries of the play-next run at removal time.
  final Set<int> playNextRunIds;
}
