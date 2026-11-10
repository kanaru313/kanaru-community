import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../domain/scan/scan_folder.dart';
import '../../domain/scan_status.dart';
import 'library_counts.dart';
import 'scan_cover_phase.dart';
import 'scan_folders.dart';
import 'scan_pipeline_types.dart';
import 'tag_pass.dart';

export 'scan_cover_phase.dart' show runCoverMisses;
export 'scan_pipeline_types.dart';

final _log = Logger('library.scan');

/// One scan of every enabled music folder: tag pass per folder, then the
/// cover pass over the folders that finished, then the library counts.
///
/// Never throws: database trouble ends the folder (or the cover pass) with
/// `io`, the first failure kind wins in [ScanOutcome.failureKind]. A folder
/// whose native call is stuck is skipped until [ScanSession.stuck] clears.
Future<ScanOutcome> runScanPass(
  ScanPipelineDeps d,
  ScanSession session,
  ScanHooks hooks, {
  bool full = false,
}) async {
  final out = ScanOutcome();
  d.source.beginScan();
  try {
    hooks.onStatus(
      const ScanRunning(phase: ScanPhase.listing, done: 0, total: 0),
    );
    final perms = await d.permissions.status();
    if (perms.applies && perms.audio != MediaPermissionStatus.granted) {
      return out..failureKind = 'permission';
    }
    final finished = <int>{};
    var doneBefore = 0;
    var totalBefore = 0;
    for (final folder in await liveScanFolders(d.db)) {
      if (hooks.shouldStop()) break;
      if (session.stuck.contains(folder.root)) {
        _log.warning('${folder.root}: skipped, a native call is still stuck');
        out.failureKind ??= 'native_timeout';
        continue;
      }
      var folderTotal = 0;
      try {
        final result = await _scanFolder(d, session, hooks, folder, full, (
          done,
          total,
        ) {
          folderTotal = total;
          hooks.onStatus(
            ScanRunning(
              phase: ScanPhase.tags,
              done: doneBefore + done,
              total: totalBefore + total,
            ),
          );
        });
        out.added += result.report.added;
        if (result.nativeStuck) {
          session.stuck.add(folder.root);
          final pending = result.pendingNative;
          if (pending != null) {
            out.pending.add((key: folder.root, future: pending));
          }
          out.failureKind ??= 'native_timeout';
        }
        out.failureKind ??= result.failureKind;
        if (result.finished) {
          finished.add(folder.sourceId);
          doneBefore += folderTotal;
          totalBefore += folderTotal;
        }
      } on Object catch (e, st) {
        _log.severe('${folder.root}: scan failed', e, st);
        out.failureKind ??= 'io';
      }
    }
    if (hooks.shouldStop()) return out..stopped = true;
    if (finished.isNotEmpty) {
      await runCoverPhase(d, session, hooks, out, perms, finished);
      if (hooks.shouldStop()) return out..stopped = true;
    }
    if (out.failureKind == null) out.counts = await countsForFinished(d.db);
  } on Object catch (e, st) {
    _log.severe('scan pass failed', e, st);
    out.failureKind ??= 'io';
  }
  return out;
}

Future<FolderTagResult> _scanFolder(
  ScanPipelineDeps d,
  ScanSession session,
  ScanHooks hooks,
  ScanFolder folder,
  bool full,
  void Function(int done, int total) onProgress,
) async {
  final excluded = (await excludedFolderKeys(d.db, folder.sourceId)).toSet();
  // Built before the listing: it remembers the mounts the folder sat on.
  final presence = d.source.presenceCheck((root: folder.root));
  final listing = await d.source.list(
    (root: folder.root),
    excludedKeys: excluded,
    skipShorterThanMs: d.skipShortTracks ? shortTrackMs : 0,
  );
  return runTagPass(
    folder,
    listing,
    TagPassDeps(
      db: d.db,
      reader: d.reader,
      now: d.now,
      shouldStop: hooks.shouldStop,
      onProgress: onProgress,
      tagTimeout: d.tagTimeout,
      skipShorterThanMs: d.skipShortTracks ? shortTrackMs : 0,
      shortMemo: session.shortMemo,
      yielder: d.yielder,
      rootStillThere: presence,
    ),
    full: full,
  );
}
