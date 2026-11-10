import 'package:drift/drift.dart';

import '../domain/queue_state.dart';

/// Sum of `duration_ms` of the entries after [current] in play order, one
/// query. Tracks without a duration count as zero.
Future<int> remainingDurationMs(
  DatabaseConnectionUser db, {
  required QueueItem current,
  required bool shuffled,
}) async {
  final key = shuffled ? current.shuffleKey : current.sortKey;
  if (key == null) return 0;
  final column = shuffled ? 'q.shuffle_key' : 'q.sort_key';
  final row = await db
      .customSelect(
        'SELECT COALESCE(SUM(t.duration_ms), 0) AS ms '
        'FROM queue_entries q JOIN tracks t ON t.id = q.track_id '
        'WHERE ($column, q.id) > (?, ?)',
        variables: [
          Variable.withString(key),
          Variable.withInt(current.entryId),
        ],
      )
      .getSingle();
  return row.read<int>('ms');
}
