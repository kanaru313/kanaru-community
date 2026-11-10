import '../../foundation/ordering/fractional_keys.dart';
import 'queue_state.dart';

/// Source of fractional keys. A class so a test can force the unusual cases
/// (equal neighbours) without depending on the generator's output.
class KeyGen {
  const KeyGen();

  String between(String? a, String? b) => generateKeyBetween(a, b);

  List<String> betweenN(String? a, String? b, int n) =>
      generateNKeysBetween(a, b, n);
}

/// Keys for new entries and the key changes of existing ones.
class KeySlot {
  const KeySlot(this.keys, this.rekeyed);

  /// One key per new entry, ascending.
  final List<String> keys;

  /// New keys of existing entries that had to move to make room.
  final Map<int, String> rekeyed;
}

/// Keys for [n] new entries placed at [pos] of [order] (between
/// `order[pos - 1]` and `order[pos]`), by the key [keyOf] reads.
///
/// The neighbours of a healthy list have strictly increasing keys. When the
/// entries from [pos] on have keys that are not above the left key (equal
/// keys: a restored row, a duplicate from another writer), the generator would
/// throw. They are given fresh keys right after the new ones instead, in their
/// present order, so the result is always strictly ordered.
KeySlot placeKeys(
  List<QueueItem> order,
  int pos,
  int n,
  String? Function(QueueItem) keyOf,
  KeyGen gen,
) {
  if (n == 0) return const KeySlot([], {});
  final left = pos > 0 ? keyOf(order[pos - 1]) : null;
  var j = pos;
  if (left != null) {
    while (j < order.length) {
      final k = keyOf(order[j]);
      if (k == null || k.compareTo(left) > 0) break;
      j++;
    }
  }
  final right = j < order.length ? keyOf(order[j]) : null;
  final all = gen.betweenN(left, right, n + (j - pos));
  return KeySlot(all.sublist(0, n), {
    for (var i = pos; i < j; i++) order[i].entryId: all[n + (i - pos)],
  });
}
