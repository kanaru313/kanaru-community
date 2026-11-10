import 'package:drift/drift.dart' show Variable;
import 'package:logging/logging.dart';

import '../../../media/domain/cover_files.dart';
import 'cover_layout.dart';
import 'cover_pass.dart';

final _log = Logger('library.scan.covers');

/// Re-extracts the covers whose files were reported gone (`TrackCover` via
/// `coverMissesProvider`): resets `cover_scan_version` of the present rows
/// holding one of [keys] (statements of at most 200 keys, yielding between
/// them) after making sure the cache layout exists, then runs a cover pass
/// over just those rows.
Future<CoverPassResult> reExtractCovers(
  CoverPassDeps deps,
  Iterable<String> keys,
) async {
  final valid = {
    for (final k in keys)
      if (isCoverKey(k)) k,
  };
  if (valid.length < keys.toSet().length) {
    _log.warning('ignored malformed cover keys in a miss report');
  }
  if (valid.isEmpty) return CoverPassResult()..finished = true;
  await ensureCoverLayout(deps.db, deps.cacheDir, yielder: deps.yielder);
  final list = valid.toList();
  for (var i = 0; i < list.length; i += coverResetChunk) {
    final part = list.sublist(
      i,
      i + coverResetChunk > list.length ? list.length : i + coverResetChunk,
    );
    await deps.db.customUpdate(
      'UPDATE tracks SET cover_scan_version = 0 '
      "WHERE status = 'present' AND cover_key IN "
      '(${List.filled(part.length, '?').join(',')})',
      variables: [for (final k in part) Variable.withString(k)],
      updates: {deps.db.tracks},
    );
    await deps.yielder.now();
  }
  return runCoverPass(deps, onlyKeys: valid);
}
