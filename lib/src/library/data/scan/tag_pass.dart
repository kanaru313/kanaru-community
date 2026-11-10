import 'dart:async';

import 'package:logging/logging.dart';

import '../../../storage/domain/local_folder_listing.dart';
import '../../domain/scan/native_failure.dart';
import '../../domain/scan/scan_diff.dart';
import '../../domain/scan/scan_folder.dart';
import '../../domain/scan/scan_report.dart';
import '../../domain/scan/tag_read.dart';
import 'scan_writer.dart';
import 'stored_rows.dart';
import 'tag_pass_diff.dart';
import 'tag_pass_marks.dart';
import 'tag_pass_rules.dart';
import 'tag_pass_types.dart';
import 'track_row_builder.dart';

export 'tag_pass_types.dart';

final _log = Logger('library.scan.tags');

/// Runs the tag pass of one music folder: stored rows, diff, tag reads in
/// batches, rows written in small transactions, then the missing marks.
///
/// Nothing is concluded about rows when the folder was unreachable or
/// suspect (see [diffScan]); a stopped, stuck or failed pass marks nothing.
/// Never throws for a bad file or a failed write: those are counted in the
/// result's report and logged.
Future<FolderTagResult> runTagPass(
  ScanFolder folder,
  SourceListing listing,
  TagPassDeps deps, {
  bool full = false,
}) async {
  if (!listing.reachable) {
    return FolderTagResult(ScanReport.fromListing(listing));
  }
  final maxBefore = await maxTrackId(deps.db);
  final result = await _runTagPass(folder, listing, deps, full, maxBefore);
  // New visible tracks: ids above the pre-scan maximum (never reused) that
  // are present, so rows inserted hidden under an exclusion do not count.
  if (result.failureKind == null) {
    try {
      result.report.added = await presentTracksAbove(
        deps.db,
        folder.sourceId,
        maxBefore,
      );
    } on Object catch (e, st) {
      // Keep the pass result: the caller still needs its counts and flags.
      _log.warning('${folder.root}: could not count new tracks', e, st);
    }
  }
  return result;
}

Future<FolderTagResult> _runTagPass(
  ScanFolder folder,
  SourceListing listing,
  TagPassDeps deps,
  bool full,
  int maxBefore,
) async {
  final report = ScanReport.fromListing(listing);
  final result = FolderTagResult(report);
  final db = deps.db;

  final stored = await storedRowsOf(db, folder.sourceId, yielder: deps.yielder);
  final diff = stored.length > deps.isolateDiffAbove
      ? await diffAgainstStoredInIsolate(listing, stored, full)
      : diffAgainstStored(listing, stored, full);
  report
    ..unchanged = diff.unchanged
    ..rootSuspect = diff.rootSuspect;
  if (diff.rootSuspect) {
    _log.warning('${folder.root}: no files listed but rows exist; kept');
  }
  final candidates = <int>{...diff.missingCandidates};
  final notFound = <int, String>{};

  // Short files seen before in this session are not read again.
  final reads = <ScanRead>[];
  for (final r in diff.toRead) {
    final f = r.file;
    if (deps.skipShorterThanMs > 0 &&
        deps.shortMemo.contains(
          folder.sourceId,
          f.locator,
          f.mtimeMs,
          f.sizeBytes,
        )) {
      dropShort(report, candidates, r.stored);
    } else {
      reads.add(r);
    }
  }

  final buffer = <WriteItem>[];
  // Writes [buffer] in transactions of at most [writeBatchRows]; false when
  // the source is gone.
  Future<bool> flush({bool force = false}) async {
    while (buffer.length >= writeBatchRows || (force && buffer.isNotEmpty)) {
      final chunk = buffer.take(writeBatchRows).toList();
      buffer.removeRange(0, chunk.length);
      final out = await writeBatchSafely(db, folder.sourceId, chunk);
      report.writeBatches++;
      report.writeFailed += out.failed;
      if (out.systemic) {
        _log.severe('${folder.root}: the database refused every row; stopping');
        result
          ..failureKind = 'io'
          ..stopped = true;
        return false;
      }
      if (out.sourceGone) {
        result
          ..sourceGone = true
          ..stopped = true;
        return false;
      }
      for (final id in out.ids) {
        if (id == null) continue;
        if (id <= maxBefore) report.updated++;
      }
      await deps.yielder.tick();
    }
    return true;
  }

  for (final u in diff.lrcUpdates) {
    buffer.add(
      LrcWrite(
        trackId: u.row.id,
        details: DetailsPatch(
          lrcLocator: u.lrc?.locator,
          lrcRevision: u.lrc?.revision,
        ),
      ),
    );
  }
  if (!await flush(force: true)) return result;

  final total = reads.length;
  var done = 0;
  if (total > 0) deps.onProgress?.call(0, total);
  final batchSize = tagBatchSize(total);
  for (var i = 0; i < total; i += batchSize) {
    if (deps.shouldStop()) return result..stopped = true;
    final batch = reads.sublist(
      i,
      i + batchSize > total ? total : i + batchSize,
    );
    final paths = [for (final r in batch) folder.pathOf(r.file.locator)];
    final call = deps.reader.read(paths);
    final List<TagRead> answers;
    try {
      answers = await call.timeout(deps.tagTimeout);
    } on TimeoutException {
      _log.severe(
        '${folder.root}: tag call timed out after ${deps.tagTimeout}',
      );
      return result
        ..nativeStuck = true
        ..stopped = true
        ..pendingNative = call.then((_) {}, onError: (Object _) {});
    } on Object catch (e, st) {
      _log.severe('${folder.root}: tag call failed', e, st);
      return result
        ..failureKind = 'native_unavailable'
        ..stopped = true;
    }
    if (deps.shouldStop()) return result..stopped = true;
    report.read += batch.length;
    final byPath = {for (final a in answers) a.path: a};
    for (var j = 0; j < batch.length; j++) {
      final item = batch[j];
      final answer =
          byPath[paths[j]] ??
          TagRead(
            path: paths[j],
            error: const NativeFailure(kind: 'io', transient: true),
          );
      queueTagResult(
        item,
        answer,
        folder,
        deps,
        report,
        candidates,
        notFound,
        buffer,
      );
    }
    if (!await flush()) return result;
    done += batch.length;
    deps.onProgress?.call(done, total);
  }
  if (!await flush(force: true)) return result;

  if (deps.shouldStop()) return result..stopped = true;
  switch (await markMissingRows(folder, deps, report, candidates, notFound)) {
    case MarkOutcome.done:
      break;
    case MarkOutcome.rootVanished:
      return result
        ..rootVanished = true
        ..stopped = true;
    case MarkOutcome.sourceGone:
      return result
        ..sourceGone = true
        ..stopped = true;
  }
  await recordFolderScanned(folder, deps);
  _log.info('${folder.root}: $report');
  return result..finished = true;
}
