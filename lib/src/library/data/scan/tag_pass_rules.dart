import 'package:drift/drift.dart' show Variable;
import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../domain/scan/lrc_match.dart';
import '../../domain/scan/scan_diff.dart';
import '../../domain/scan/scan_folder.dart';
import '../../domain/scan/scan_report.dart';
import '../../domain/scan/tag_read.dart';
import 'scan_writer.dart';
import 'tag_pass_types.dart';
import 'track_row_builder.dart';

final _log = Logger('library.scan.tags');

/// The largest `tracks.id` now; ids are never reused, so a row returned by
/// an upsert with a bigger id is new.
Future<int> maxTrackId(AppDatabase db) async {
  final row = await db
      .customSelect('SELECT COALESCE(MAX(id), 0) AS m FROM tracks')
      .getSingle();
  return row.read<int>('m');
}

void dropShort(ScanReport report, Set<int> candidates, StoredTrackRow? stored) {
  report.filteredOut++;
  if (stored != null && stored.isPresent) candidates.add(stored.id);
}

/// Applies the error and short-file rules to one answer and queues the row.
void queueTagResult(
  ScanRead item,
  TagRead answer,
  ScanFolder folder,
  TagPassDeps deps,
  ScanReport report,
  Set<int> candidates,
  Map<int, String> notFound,
  List<WriteItem> buffer,
) {
  final file = item.file;
  final stored = item.stored;
  final error = answer.error;
  if (error != null) {
    if (error.isNotFound) {
      // The listing was stale: the file is gone. Treat it as not listed, but
      // only mark the row once the folder itself is confirmed to be there
      // (a drive that dropped mid-pass answers NotFound for everything).
      report.staleListing++;
      if (stored != null && stored.isPresent) {
        notFound[stored.id] = file.locator;
      }
      return;
    }
    if (error.transient && stored != null) {
      // Keep the row as it is; mtime and size stay old, so the next scan
      // reads the file again.
      report.transientSkipped++;
      _log.fine('${file.locator}: transient ${error.kind}, row kept');
      return;
    }
    if (stored != null &&
        stored.revision == revisionOf(file.mtimeMs, file.sizeBytes)) {
      // The file did not change, so the error says nothing new about the
      // tags we hold (a permission or parser change must not wipe them).
      report.permanentKept++;
      // Fine, not warning: a parser regression would repeat this for every
      // file on every scan. The folder summary carries the count.
      _log.fine('${file.locator}: ${error.kind} on an unchanged file; kept');
      return;
    }
  } else {
    final duration = answer.fields?.durationMs;
    if (deps.skipShorterThanMs > 0 &&
        duration != null &&
        duration < deps.skipShorterThanMs) {
      deps.shortMemo.add(
        folder.sourceId,
        file.locator,
        file.mtimeMs,
        file.sizeBytes,
      );
      dropShort(report, candidates, stored);
      return;
    }
  }
  buffer.add(
    SnapshotWrite(
      buildTrackRow(
        folder: folder,
        file: file,
        read: answer,
        now: deps.now(),
        lrc: item.lrc,
        stored: stored,
      ),
    ),
  );
}

/// How many present rows of [sourceId] have an id above [maxBefore].
Future<int> presentTracksAbove(
  AppDatabase db,
  int sourceId,
  int maxBefore,
) async {
  final row = await db
      .customSelect(
        'SELECT COUNT(*) AS n FROM tracks WHERE source_id = ?1 AND id > ?2 '
        "AND status = 'present'",
        variables: [Variable.withInt(sourceId), Variable.withInt(maxBefore)],
        readsFrom: {db.tracks},
      )
      .getSingle();
  return row.read<int>('n');
}
