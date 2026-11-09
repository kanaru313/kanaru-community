import 'package:drift/drift.dart';

import 'tables.dart';

/// Ids per statement; keeps each statement short on the UI isolate.
const _chunk = 500;

/// Marks [trackIds] `missing` with `missing_since = now`, only the rows that
/// are still `present` (`hidden`, `remote` and already `missing` rows keep
/// their state and `missing_since`). Returns how many rows changed.
///
/// The caller decides reachability: never call it for a root that could not
/// be listed, or an unplugged drive would empty the library. Runs in one
/// transaction, at most 500 ids per statement.
Future<int> markTracksMissing(
  DatabaseConnectionUser db,
  Iterable<int> trackIds,
  int now,
) async {
  final ids = trackIds.toSet().toList();
  if (ids.isEmpty) return 0;
  final changed = await db.transaction(() async {
    var total = 0;
    for (var i = 0; i < ids.length; i += _chunk) {
      final part = ids.sublist(
        i,
        i + _chunk > ids.length ? ids.length : i + _chunk,
      );
      total += await db.customUpdate(
        "UPDATE tracks SET status = '${TrackStatus.missing}', "
        "missing_since = ?, updated_at = ? "
        "WHERE status = '${TrackStatus.present}' "
        'AND id IN (${List.filled(part.length, '?').join(', ')})',
        variables: [
          Variable.withInt(now),
          Variable.withInt(now),
          for (final id in part) Variable.withInt(id),
        ],
      );
    }
    return total;
  });
  if (changed > 0) db.notifyUpdates({const TableUpdate('tracks')});
  return changed;
}
