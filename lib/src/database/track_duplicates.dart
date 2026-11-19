import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

/// What `applyDuplicateHiding` needs from the layers above the database.
class DuplicateRules {
  const DuplicateRules({
    required this.losslessCodecs,
    required this.losslessExtensions,
  });

  /// Lower-case `tracks.codec` values that are lossless.
  final Set<String> losslessCodecs;

  /// Lower-case extensions of `rel_path` that are lossless, used when the
  /// codec is unknown (NULL).
  final Set<String> losslessExtensions;
}

/// SQL extension of `t.rel_path` (text after the last dot, lower case).
const _extension =
    "lower(replace(t.rel_path, rtrim(t.rel_path, replace(t.rel_path, '.', '')), ''))";

String _marks(int n) => List.filled(n, '?').join(', ');

/// Recomputes which present tracks are hidden as duplicates, in one
/// transaction. When [enabled], hides all but one present copy per `name_key`
/// (written with the row by the scanner): lossless first, then higher
/// bitrate (unknown last), then the music folder listed first (`m.root`, then
/// source id, as the scan lists them), then the lower track id. Rows with no
/// key never merge. When disabled, every hidden row is shown again.
///
/// Only rows whose `dup_hidden` differs from the result are written, and
/// `tracks` streams re-emit only when at least one row changed. Only
/// `present` rows take part, so a missing better copy never hides a present
/// one. Rows are never deleted or marked missing.
Future<void> applyDuplicateHiding(
  AppDatabase db, {
  required bool enabled,
  required DuplicateRules rules,
}) {
  final codecs = rules.losslessCodecs.toList();
  final extensions = rules.losslessExtensions.toList();
  return db.transaction(() async {
    final int changed;
    if (!enabled) {
      changed = await db.customUpdate(
        'UPDATE tracks SET dup_hidden = 0 WHERE dup_hidden = 1',
      );
    } else {
      changed = await db.customUpdate(
        'WITH losers AS (SELECT id FROM ('
        'SELECT t.id AS id, ROW_NUMBER() OVER (PARTITION BY t.name_key '
        'ORDER BY '
        'CASE WHEN t.codec IS NOT NULL THEN lower(t.codec) IN (${_marks(codecs.length)}) '
        'ELSE $_extension IN (${_marks(extensions.length)}) END DESC, '
        't.bitrate DESC NULLS LAST, m.root, t.source_id, t.id) AS rn '
        'FROM tracks t LEFT JOIN source_mounts m ON m.source_id = t.source_id '
        "WHERE t.status = '${TrackStatus.present}' AND t.name_key IN ("
        // Only keys held by two or more present rows need ranking; the
        // partial index answers this without sorting the whole library.
        'SELECT name_key FROM tracks '
        "WHERE status = '${TrackStatus.present}' AND name_key <> '' "
        'GROUP BY name_key HAVING COUNT(*) > 1)) '
        'WHERE rn > 1) '
        'UPDATE tracks SET dup_hidden = (id IN (SELECT id FROM losers)) '
        'WHERE dup_hidden <> (id IN (SELECT id FROM losers))',
        variables: [
          for (final c in codecs) Variable<String>(c),
          for (final e in extensions) Variable<String>(e),
        ],
      );
    }
    if (changed > 0) {
      db.notifyUpdates({const TableUpdate('tracks', kind: UpdateKind.update)});
    }
  });
}
