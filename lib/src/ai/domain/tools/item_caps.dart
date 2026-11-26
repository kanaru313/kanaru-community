import '../conversation/parts.dart';

/// Most queue and playlist items the assistant may remove in one user turn.
const int maxRemovedItemsPerTurn = 50;

/// Most items it may add (play, queue, create or add to a playlist) in one
/// user turn.
const int maxAddedItemsPerTurn = 200;

/// What the assistant already changed since the user's last message, counted
/// from the persisted `DonePart`s of that turn so a retry or a restart never
/// resets it.
class TurnItemUsage {
  const TurnItemUsage({this.added = 0, this.removed = 0});

  static const none = TurnItemUsage();

  /// Counts the `DonePart`s among [parts] (the parts of every message of the
  /// turn); other parts are ignored.
  factory TurnItemUsage.fromParts(Iterable<AiPart> parts) {
    var added = 0;
    var removed = 0;
    for (final p in parts) {
      if (p is DonePart) {
        added += p.added.length;
        removed += p.removed.length;
      }
    }
    return TurnItemUsage(added: added, removed: removed);
  }

  final int added;
  final int removed;

  /// Whether [count] more items can be added within the turn's limit.
  bool canAdd(int count) => added + count <= maxAddedItemsPerTurn;

  /// Whether [count] more items can be removed within the turn's limit.
  bool canRemove(int count) => removed + count <= maxRemovedItemsPerTurn;
}
