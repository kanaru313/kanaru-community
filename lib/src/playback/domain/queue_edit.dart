import 'queue_state.dart';
import 'undo_token.dart';

/// New key values of one existing entry. A null field is unchanged.
typedef KeyChange = ({String? sortKey, String? shuffleKey});

/// The result of one queue operation: the next state and exactly what the
/// repository must write to make `queue_entries` match it.
class QueueEdit {
  const QueueEdit({
    required this.next,
    this.inserted = const [],
    this.removedIds = const [],
    this.rekeyed = const {},
    this.clearShuffleKeys = false,
    this.undo,
  });

  /// An edit that changes nothing.
  QueueEdit.none(QueueState state) : this(next: state);

  final QueueState next;

  /// New rows. A negative `entryId` is provisional (the table assigns the
  /// id); a positive one is a restored row that keeps its id.
  final List<QueueItem> inserted;
  final List<int> removedIds;

  /// Key changes of rows that stay (not of [inserted] rows).
  final Map<int, KeyChange> rekeyed;

  /// Every row loses its `shuffle_key` (shuffle turned off).
  final bool clearShuffleKeys;

  /// Set by removals.
  final UndoToken? undo;

  bool get isNoop =>
      inserted.isEmpty &&
      removedIds.isEmpty &&
      rekeyed.isEmpty &&
      !clearShuffleKeys;

  /// The same edit with provisional ids replaced by the ids in [real]
  /// (provisional id to real id).
  QueueEdit withRealIds(Map<int, int> real) {
    if (real.isEmpty) return this;
    QueueItem fix(QueueItem i) =>
        real.containsKey(i.entryId) ? i.withEntryId(real[i.entryId]!) : i;
    final current = next.current;
    return QueueEdit(
      next: QueueState(
        items: [for (final i in next.items) fix(i)],
        current: current,
        shuffled: next.shuffled,
        repeat: next.repeat,
        playNextRun: next.playNextRun,
      ),
      inserted: [for (final i in inserted) fix(i)],
      removedIds: removedIds,
      rekeyed: rekeyed,
      clearShuffleKeys: clearShuffleKeys,
      undo: undo,
    );
  }
}
