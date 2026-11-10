import 'package:logging/logging.dart';

import '../../../database/database.dart';

final _log = Logger('library.scan.gc');

/// Runs the track GC and never throws: a failed GC must not fail a scan.
/// Returns how many tracks were deleted, null when the GC did not run (its
/// fail-closed checks refused, or the database failed).
Future<int?> runTrackGc(AppDatabase db, {required int now}) async {
  try {
    final deleted = await collectOrphanTracks(db, now: now);
    if (deleted > 0) _log.info('track GC deleted $deleted rows');
    return deleted;
  } on StateError catch (e) {
    // The helper refuses to run when a foreign key is not RESTRICT or
    // enforcement is off. Nothing was deleted.
    _log.warning('track GC refused to run: ${e.message}');
    return null;
  } on Object catch (e, st) {
    _log.severe('track GC failed', e, st);
    return null;
  }
}
