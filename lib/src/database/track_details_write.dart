import 'package:drift/drift.dart';

import 'tables.dart';

/// Columns the scanner owns in `track_details`.
const _scannerColumns = {
  'comment',
  'extra_tags',
  'lrc_locator',
  'lrc_revision',
  'cover_src',
};

/// Inserts the `track_details` row of `row.trackId` or, if it exists,
/// rewrites the columns present in [row] (absent keeps the stored value, an
/// explicit null writes null). `ON CONFLICT DO UPDATE`, never `REPLACE`.
/// Throws [ArgumentError] when `trackId` is absent or [row] carries a column
/// the scanner does not own. Notifies `track_details`.
Future<void> upsertTrackDetails(
  DatabaseConnectionUser db,
  TrackDetailsCompanion row,
) async {
  if (!row.trackId.present) throw ArgumentError('trackId is required');
  final cols = row.toColumns(false);
  final bad = cols.keys
      .where((n) => n != 'track_id' && !_scannerColumns.contains(n))
      .toList();
  if (bad.isNotEmpty) {
    throw ArgumentError.value(bad.join(', '), 'row', 'not a scanner column');
  }
  final names = cols.keys.toList();
  final updates = [
    for (final n in names)
      if (n != 'track_id') '$n = excluded.$n',
  ];
  await db.customInsert(
    'INSERT INTO track_details (${names.join(', ')}) '
    "VALUES (${List.filled(names.length, '?').join(', ')}) "
    'ON CONFLICT (track_id) DO '
    '${updates.isEmpty ? 'NOTHING' : 'UPDATE SET ${updates.join(', ')}'}',
    variables: [for (final n in names) cols[n]! as Variable],
  );
  db.notifyUpdates({const TableUpdate('track_details')});
}
