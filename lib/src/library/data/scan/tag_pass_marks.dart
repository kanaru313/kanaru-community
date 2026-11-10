import 'package:drift/drift.dart' show Variable;
import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../domain/scan/scan_folder.dart';
import '../../domain/scan/scan_report.dart';
import 'scan_writer.dart';
import 'tag_pass_types.dart';

final _log = Logger('library.scan.tags');

/// Ids per `markTracksMissing` call.
const int missingMarkChunk = 200;

enum MarkOutcome { done, rootVanished, sourceGone }

/// Marks the rows that are no longer there as missing.
///
/// [candidates] come from a valid listing. [notFound] (id to locator) are
/// rows whose file the reader could not find: they are marked only if
/// `deps.rootStillThere` confirms the folder, and not when they lie under a
/// nested mount that vanished. The source is checked live first. Marks are
/// calls of at most [missingMarkChunk] ids with a yield between.
Future<MarkOutcome> markMissingRows(
  ScanFolder folder,
  TagPassDeps deps,
  ScanReport report,
  Set<int> candidates,
  Map<int, String> notFound,
) async {
  final ids = {...candidates};
  if (notFound.isNotEmpty) {
    final presence = await deps.rootStillThere();
    if (!presence.present) {
      _log.severe(
        '${folder.root}: ${notFound.length} files were not found and the '
        'folder is gone; nothing is marked missing',
      );
      report.unreachable = true;
      return MarkOutcome.rootVanished;
    }
    if (presence.mountsUnreadable) report.mountsUnreadable = true;
    for (final e in notFound.entries) {
      if (presence.isLost(e.value)) {
        report.keptUnderLostMount++;
      } else {
        ids.add(e.key);
      }
    }
  }
  if (ids.isEmpty) return MarkOutcome.done;
  if (!await isSourceLive(deps.db, folder.sourceId)) {
    return MarkOutcome.sourceGone;
  }
  final list = ids.toList();
  for (var i = 0; i < list.length; i += missingMarkChunk) {
    final end = i + missingMarkChunk > list.length
        ? list.length
        : i + missingMarkChunk;
    report.missingMarked += await markTracksMissing(
      deps.db,
      list.sublist(i, end),
      deps.now(),
    );
    await deps.yielder.now();
  }
  return MarkOutcome.done;
}

/// Records that the folder was scanned to the end (`last_scan_at`).
Future<void> recordFolderScanned(ScanFolder folder, TagPassDeps deps) =>
    deps.db.customUpdate(
      'UPDATE source_mounts SET last_scan_at = ? WHERE source_id = ?',
      variables: [
        Variable.withInt(deps.now()),
        Variable.withInt(folder.sourceId),
      ],
      updates: {deps.db.sourceMounts},
    );
