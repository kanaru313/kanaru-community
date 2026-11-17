import 'queue_logic.dart';

/// What lies on one side of the current entry, for a surface that shows it
/// before the user commits to it.
sealed class Neighbour {
  const Neighbour();
}

/// Nothing to go to: the command only restarts the entry or reports the end.
class NoNeighbour extends Neighbour {
  const NoNeighbour();
}

/// The entry a Next or Previous goes to.
class KnownNeighbour extends Neighbour {
  const KnownNeighbour(this.item);

  final QueueItem item;
}

/// There is somewhere to go, but not yet which entry: the last entry of a
/// reshuffled pass goes to the first of a new random order.
class UnknownNeighbour extends Neighbour {
  const UnknownNeighbour();
}

/// The entries a manual Previous and Next lead to.
class QueueNeighbours {
  const QueueNeighbours({required this.previous, required this.next});

  static const none = QueueNeighbours(
    previous: NoNeighbour(),
    next: NoNeighbour(),
  );

  final Neighbour previous;
  final Neighbour next;
}

/// Where Previous and Next from [current] go, from the same rules the
/// controller uses ([previousIndex], [nextIndex] with `auto: false`), so what
/// a surface shows is what the command does. Fewer than two entries, or
/// nothing current: no neighbours (the commands still run: they restart the
/// entry or report the end).
QueueNeighbours neighboursOf(
  List<QueueItem> items,
  int? current,
  RepeatMode repeat,
) {
  if (current == null || current < 0 || current >= items.length) {
    return QueueNeighbours.none;
  }
  if (items.length < 2) return QueueNeighbours.none;
  final s = QueueState(items: items, current: current, repeat: repeat);
  Neighbour at(int? i) => i == null || i == current
      ? const NoNeighbour()
      : KnownNeighbour(items[i]);
  final endsPass =
      repeat == RepeatMode.allShuffled && current == items.length - 1;
  return QueueNeighbours(
    previous: at(previousIndex(s)),
    next: endsPass ? const UnknownNeighbour() : at(nextIndex(s, auto: false)),
  );
}
