import 'dart:async';

import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../media/domain/cover_colors.dart' as media;
import '../../domain/scan/cover_read.dart';
import '../../domain/scan/native_failure.dart';
import '../../domain/scan/scan_versions.dart';
import 'cover_layout.dart';
import 'cover_pass_types.dart';
import 'cover_work.dart';
import 'cover_writer.dart';

export 'cover_layout.dart' show ensureCoverLayout;
export 'cover_pass_types.dart';

final _log = Logger('library.scan.covers');

/// Runs the cover pass: the present rows whose `cover_scan_version` is below
/// [coverPassVersion], ordered by source and locator, optionally limited to
/// [sourceIds] or to rows holding one of [onlyKeys]. Checks the cache layout
/// first. Colours for covers that already existed are computed at the end.
Future<CoverPassResult> runCoverPass(
  CoverPassDeps deps, {
  Set<int>? sourceIds,
  Set<String>? onlyKeys,
}) async {
  final result = CoverPassResult();
  final db = deps.db;
  if (!deps.cacheDir.startsWith('/')) {
    _log.severe('cache folder ${deps.cacheDir} is not absolute; no covers');
    return result..failureKind = 'io';
  }
  await ensureCoverLayout(db, deps.cacheDir, yielder: deps.yielder);

  final ids = [
    for (final id in await coverWorkSet(db, sourceIds, onlyKeys))
      if (!deps.skip.contains(id)) id,
  ];
  result.total = ids.length;
  if (ids.isEmpty) return result..finished = true;
  deps.onProgress?.call(0, ids.length);
  final checkColors = <String>{};
  for (var i = 0; i < ids.length; i += coverBatchSize) {
    if (deps.shouldStop()) return result..stopped = true;
    final end = i + coverBatchSize > ids.length
        ? ids.length
        : i + coverBatchSize;
    final items = await coverItemsOf(db, ids.sublist(i, end));
    if (items.isNotEmpty) {
      final call = deps.maker.extract(
        cacheDir: deps.cacheDir,
        items: [for (final it in items) (trackId: it.id, path: it.path)],
        sidecars: deps.sidecars,
      );
      final List<CoverRead> answers;
      try {
        answers = await call.timeout(deps.timeout);
      } on TimeoutException {
        _log.severe('cover call timed out after ${deps.timeout}');
        return result
          ..stuck = true
          ..stopped = true
          ..pendingNative = call.then((_) {}, onError: (Object _) {});
      } on Object catch (e, st) {
        _log.severe('cover call failed', e, st);
        return result
          ..failureKind = 'native_unavailable'
          ..stopped = true;
      }
      if (deps.shouldStop()) return result..stopped = true;
      final byId = {for (final a in answers) a.trackId: a};
      final results = [
        for (final it in items)
          byId[it.id] ??
              CoverRead(
                trackId: it.id,
                status: CoverStatus.failed,
                error: const NativeFailure(kind: 'io', transient: true),
              ),
      ];
      final out = await applyCoverResults(
        db,
        results,
        sidecars: deps.sidecars,
        now: deps.now(),
      );
      result
        ..found += out.found
        ..noCover += out.noCover
        ..transientFailed += out.transientFailed
        ..permanentFailed += out.permanentFailed
        ..deferred += out.deferred
        ..colorsWritten += out.colorsWritten;
      deps.skip.addAll(out.skip);
      checkColors.addAll(out.checkColors);
      if (out.cacheFailed) {
        _log.severe('the cover cache is not writable; pass ended');
        result.cacheFailed = true;
        break;
      }
    }
    result.done = end;
    deps.onProgress?.call(end, ids.length);
    await deps.yielder.now();
  }
  if (!result.cacheFailed) {
    await _fillColors(deps, checkColors, result);
    result.finished = !result.stuck;
  }
  return result;
}

/// Computes colours for covers whose files already existed, when no colour
/// row of the current version is stored. One query per 200 keys finds the
/// missing ones; keys answered "no colours" are remembered for the session.
Future<void> _fillColors(
  CoverPassDeps deps,
  Set<String> keys,
  CoverPassResult result,
) async {
  final todo = [
    for (final k in keys)
      if (!deps.noColors.contains(k)) k,
  ];
  final missing = <String>[];
  for (var i = 0; i < todo.length; i += coverKeyChunk) {
    final part = todo.sublist(
      i,
      i + coverKeyChunk > todo.length ? todo.length : i + coverKeyChunk,
    );
    final current = await currentColorKeys(deps.db, part);
    missing.addAll(part.where((k) => !current.contains(k)));
  }
  for (var i = 0; i < missing.length; i += coverBatchSize) {
    if (deps.shouldStop()) return;
    final part = missing.sublist(
      i,
      i + coverBatchSize > missing.length ? missing.length : i + coverBatchSize,
    );
    final call = deps.maker.colorsFor(cacheDir: deps.cacheDir, keys: part);
    final List<CoverColorsRead> answers;
    try {
      answers = await call.timeout(deps.timeout);
    } on TimeoutException {
      _log.severe('cover colours timed out after ${deps.timeout}');
      result
        ..stuck = true
        ..pendingNative = call.then((_) {}, onError: (Object _) {});
      return;
    } on Object catch (e, st) {
      _log.warning('cover colours failed', e, st);
      return;
    }
    if (deps.shouldStop()) return;
    for (final a in answers) {
      final c = a.colors;
      if (a.error != null) {
        _log.fine('no colours for ${a.key}: ${a.error}');
      } else if (c != null && c.palette.isNotEmpty) {
        await upsertCoverColors(
          deps.db,
          coverKey: a.key,
          seed: c.seed,
          colors: c.palette,
          version: media.coverColorsVersion,
          now: deps.now(),
        );
        result.colorsWritten++;
      } else {
        deps.noColors.add(a.key);
      }
    }
    await deps.yielder.now();
  }
}
