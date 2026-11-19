import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../domain/scan/read_rules.dart';
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
        final r = result.report;
        if (r.added + r.updated + r.missingMarked > 0) {
          // A copy that went missing may have been the shown one.
          await _applyDuplicateHiding(d, hooks);
        }
        if (result.nativeStuck) {
          session.stuck.add(folder.root);
          final pending = result.pendingNative;
          if (pending != null) {
            out.pending.add((key: folder.root, future: pending));
          }
          out.failureKind ??= 'native_timeout';
        }
        out.failureKind ??= result.failureKind;
        if (result.readEveryRow) await _noteReadRulesApplied(d, folder);
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
    await _applyDuplicateHiding(d, hooks);
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

/// Rows were added, changed or removed: show one copy per file name again
/// (a no-op while the setting is off). Skipped when the app is closing.
Future<void> _applyDuplicateHiding(ScanPipelineDeps d, ScanHooks hooks) async {
  final apply = d.applyDuplicateHiding;
  if (apply == null || hooks.shouldStop()) return;
  try {
    await apply();
  } on Object catch (e, st) {
    _log.warning('duplicate hiding failed', e, st);
  }
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
  final rules = d.rules;
  // A folder last read with other read rules is read in full again.
  final appliedFingerprint =
      d.readRulesApplied[folder.sourceUid] ??
      LibraryReadRules.defaults.fingerprint;
  final readInFull = full || appliedFingerprint != d.readRules.fingerprint;
  // Format and size rules run here, after the listing and in one place, so
  // both platforms share them and `ruleOut` keeps the empty-root guard.
  final listing = rules.applyTo(
    await d.source.list(
      (root: folder.root),
      excludedKeys: excluded,
      skipShorterThanMs: rules.minDurationMs,
      respectNomedia: rules.respectNomedia,
    ),
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
      skipShorterThanMs: rules.minDurationMs,
      shortMemo: session.shortMemo,
      yielder: d.yielder,
      rootStillThere: presence,
      readRules: d.readRules,
    ),
    full: readInFull,
  );
}

/// Tells the caller that [folder] was read with this pass's read rules. A
/// failed write is only logged: the next pass reads the folder again.
Future<void> _noteReadRulesApplied(
  ScanPipelineDeps d,
  ScanFolder folder,
) async {
  final note = d.onReadRulesApplied;
  if (note == null) return;
  try {
    await note(folder.sourceUid, d.readRules.fingerprint);
  } on Object catch (e, st) {
    _log.warning('${folder.root}: could not record the read rules', e, st);
  }
}
