import 'package:drift/drift.dart';

import '../../database/database.dart' hide CoverColors;
import '../../media/domain/cover_colors.dart';

/// Colours of [coverKey], or null when the scanner has not computed them (or
/// the stored row is malformed).
Future<CoverColors?> loadCoverColors(
  DatabaseConnectionUser db,
  String coverKey,
) async {
  final row = await coverColorsFor(db, coverKey);
  return row == null ? null : CoverColors(seed: row.seed, palette: row.colors);
}

/// Live colours of [coverKey]; re-emits when the row is written, only when
/// the value changed.
Stream<CoverColors?> watchCoverColors(AppDatabase db, String coverKey) => db
    .customSelect('SELECT 1', readsFrom: {db.coverColors})
    .watch()
    .asyncMap((_) => loadCoverColors(db, coverKey))
    .distinct();
