import 'package:drift/drift.dart' show TableUpdate, Variable;
import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../media/domain/cover_colors.dart' as media;
import '../../../media/domain/cover_files.dart';
import '../../domain/scan/cover_read.dart';
import '../../domain/scan/scan_versions.dart';
import 'scan_writer.dart' show writeBatchRows;

final _log = Logger('library.scan.covers');

/// What one batch of cover results changed.
class CoverBatchOutcome {
  int found = 0;
  int noCover = 0;
  int transientFailed = 0;
  int permanentFailed = 0;

  /// `NoCover` seen without sidecars: the version is kept for later.
  int deferred = 0;
  int colorsWritten = 0;

  /// Writing under the cache folder failed: the pass must stop.
  bool cacheFailed = false;

  /// Track ids not to try again this session.
  final Set<int> skip = {};

  /// Keys of covers that already existed and may need colours.
  final Set<String> checkColors = {};
}

class _Update {
  _Update(this.sql, this.variables, {this.colors});

  final String sql;
  final List<Variable<Object>> variables;
  final ({String key, media.CoverColors colors})? colors;
}

bool _pathsMatch(CoverRead r, String key) {
  try {
    return r.thumbRel == coverRelativePath(key, CoverSize.thumb) &&
        r.fullRel == coverRelativePath(key, CoverSize.full);
  } on ArgumentError {
    return false;
  }
}

_Update _setError(int id, String kind) => _Update(
  'UPDATE tracks SET scan_error = ? WHERE id = ?',
  [Variable.withString(kind), Variable.withInt(id)],
);

/// Turns [results] into narrow updates of `tracks` (and `cover_colors`):
/// `Found` stores the key and the pass version; `NoCover` clears the key,
/// except without sidecars, where the version stays so sidecar covers arrive
/// once the permission is back; a transient failure records `scan_error` and
/// keeps key and version; a permanent one (the audio file is unreadable)
/// clears the key and bumps the version. The paths Rust reports must equal
/// [coverRelativePath], else the result counts as a transient failure.
///
/// Updates run in transactions of at most [writeBatchRows] rows, one
/// `tracks` notification per transaction.
Future<CoverBatchOutcome> applyCoverResults(
  AppDatabase db,
  List<CoverRead> results, {
  required bool sidecars,
  required int now,
}) async {
  final out = CoverBatchOutcome();
  final updates = <_Update>[];
  for (final r in results) {
    switch (r.status) {
      case CoverStatus.found:
        final key = r.key;
        if (key == null || !isCoverKey(key) || !_pathsMatch(r, key)) {
          _log.severe(
            'cover for track ${r.trackId} has key ${r.key} and paths '
            '${r.thumbRel}, ${r.fullRel}: not the layout Dart expects',
          );
          out.transientFailed++;
          out.skip.add(r.trackId);
          updates.add(_setError(r.trackId, 'coverLayout'));
          break;
        }
        out.found++;
        final c = r.colors;
        updates.add(
          _Update(
            'UPDATE tracks SET cover_key = ?, cover_scan_version = ?, '
            'scan_error = NULL WHERE id = ?',
            [
              Variable.withString(key),
              Variable.withInt(coverPassVersion),
              Variable.withInt(r.trackId),
            ],
            colors: c == null || c.palette.isEmpty
                ? null
                : (key: key, colors: c),
          ),
        );
        if (c == null && !r.made) out.checkColors.add(key);
      case CoverStatus.noCover:
        if (!sidecars) {
          out.deferred++;
          out.skip.add(r.trackId);
          break;
        }
        out.noCover++;
        updates.add(
          _Update(
            'UPDATE tracks SET cover_key = NULL, cover_scan_version = ? '
            'WHERE id = ?',
            [Variable.withInt(coverPassVersion), Variable.withInt(r.trackId)],
          ),
        );
      case CoverStatus.failed:
        final e = r.error;
        final kind = e?.kind ?? 'io';
        if (r.cacheFailure) out.cacheFailed = true;
        if (e != null && !e.transient) {
          out.permanentFailed++;
          // A panic in the encoder says nothing about the audio file: a
          // cover that worked before stays, only the version moves on.
          final keepKey = kind == 'panic' ? '' : 'cover_key = NULL, ';
          // A kept key whose file is gone would be re-extracted (and panic
          // again) on every miss report; the session skip set stops that.
          if (kind == 'panic') out.skip.add(r.trackId);
          updates.add(
            _Update(
              'UPDATE tracks SET ${keepKey}cover_scan_version = ?, '
              'scan_error = ? WHERE id = ?',
              [
                Variable.withInt(coverPassVersion),
                Variable.withString(kind),
                Variable.withInt(r.trackId),
              ],
            ),
          );
        } else {
          out.transientFailed++;
          out.skip.add(r.trackId);
          updates.add(_setError(r.trackId, kind));
        }
    }
  }
  for (var i = 0; i < updates.length; i += writeBatchRows) {
    final chunk = updates.sublist(
      i,
      i + writeBatchRows > updates.length ? updates.length : i + writeBatchRows,
    );
    await db.transaction(() async {
      for (final u in chunk) {
        await db.customUpdate(u.sql, variables: u.variables);
        final c = u.colors;
        if (c != null) {
          await upsertCoverColors(
            db,
            coverKey: c.key,
            seed: c.colors.seed,
            colors: c.colors.palette,
            version: media.coverColorsVersion,
            now: now,
          );
          out.colorsWritten++;
        }
      }
    });
    db.notifyUpdates({const TableUpdate('tracks')});
  }
  return out;
}
