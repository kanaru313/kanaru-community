import 'dart:io';

import 'package:drift/drift.dart' show TableUpdate, Variable;
import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../media/domain/cover_files.dart';
import 'scan_yield.dart';

final _log = Logger('library.scan.covers');

/// Rows reset per statement.
const int coverResetChunk = 200;

/// What [ensureCoverLayout] did.
class CoverLayoutResult {
  const CoverLayoutResult({
    this.reset = false,
    this.rowsReset = 0,
    this.statements = 0,
    this.markerWritten = true,
  });

  /// The marker was missing and the cover versions were reset.
  final bool reset;
  final int rowsReset;
  final int statements;

  /// False when the cache folder could not be prepared (logged).
  final bool markerWritten;
}

/// Checks `<cacheDir>/covers/.layout-v1`. When it is missing (the cache was
/// cleared by the system or a cleaner) every row's `cover_scan_version` goes
/// back to 0, in statements of at most [coverResetChunk] rows with a yield
/// between them, then the shard folders and the marker are created.
///
/// The marker is written last, so a reset that was cut short runs again. A
/// folder that cannot be written is logged, not thrown: the cover pass still
/// runs (its cache errors are transient) and the reset repeats next time.
Future<CoverLayoutResult> ensureCoverLayout(
  AppDatabase db,
  String cacheDir, {
  ScanYield? yielder,
}) async {
  final marker = File('$cacheDir/covers/$coverLayoutMarker');
  if (marker.existsSync()) return const CoverLayoutResult();
  final pause = yielder ?? ScanYield();
  var after = 0;
  var rows = 0;
  var statements = 0;
  while (true) {
    final ids = await db
        .customSelect(
          'SELECT id FROM tracks WHERE id > ? AND cover_scan_version <> 0 '
          'ORDER BY id LIMIT ?',
          variables: [
            Variable.withInt(after),
            Variable.withInt(coverResetChunk),
          ],
        )
        .get();
    if (ids.isEmpty) break;
    final from = ids.first.read<int>('id');
    after = ids.last.read<int>('id');
    rows += await db.customUpdate(
      'UPDATE tracks SET cover_scan_version = 0 '
      'WHERE id >= ? AND id <= ? AND cover_scan_version <> 0',
      variables: [Variable.withInt(from), Variable.withInt(after)],
    );
    statements++;
    await pause.now();
  }
  if (rows > 0) db.notifyUpdates({const TableUpdate('tracks')});
  var written = true;
  try {
    for (final size in CoverSize.values) {
      Directory('$cacheDir/covers/${size.name}').createSync(recursive: true);
    }
    marker.writeAsStringSync('v1\n');
  } on FileSystemException catch (e) {
    written = false;
    _log.severe('cannot prepare the cover cache at $cacheDir', e);
  }
  _log.info('cover layout reset: $rows rows in $statements statements');
  return CoverLayoutResult(
    reset: true,
    rowsReset: rows,
    statements: statements,
    markerWritten: written,
  );
}
