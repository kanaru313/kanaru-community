import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../database/tables.dart';
import '../../media/domain/track_id.dart';
import '../domain/playable.dart';

const _chunk = 500;

/// Same rule as `media/domain/track_info.dart` (private there): a locator
/// ending in `#NN` is a track inside a CUE sheet.
final RegExp _cueSuffix = RegExp(r'#\d+$');

/// The columns the decision reads, joined from `tracks`, `sources` and
/// `source_mounts`.
class PlayableRow {
  const PlayableRow({
    required this.status,
    required this.locator,
    required this.durationMs,
    required this.sourceKind,
    required this.sourceDeleted,
    required this.mountRoot,
    required this.mountEnabled,
  });

  final String status;
  final String locator;
  final int? durationMs;
  final String sourceKind;
  final bool sourceDeleted;

  /// Null when the source has no mount (or a mount without a path).
  final String? mountRoot;
  final bool mountEnabled;
}

/// The decision for one row ([row] null = no such track). Pure.
Playable decidePlayable(PlayableRow? row) {
  if (row == null) return const Unplayable(UnplayableReason.unknownTrack);
  if (row.sourceDeleted) {
    return const Unplayable(UnplayableReason.removedSource);
  }
  switch (row.status) {
    case TrackStatus.missing:
      return const Unplayable(UnplayableReason.missing);
    case TrackStatus.hidden:
      return const Unplayable(UnplayableReason.hidden);
    case TrackStatus.remote:
      return const Unplayable(UnplayableReason.remote);
  }
  if (_cueSuffix.hasMatch(row.locator)) {
    return const Unplayable(UnplayableReason.cue);
  }
  if (row.sourceKind != SourceKind.local) {
    return const Unplayable(UnplayableReason.remote);
  }
  final root = row.mountRoot;
  if (root == null || !row.mountEnabled) {
    return const Unplayable(UnplayableReason.noMount);
  }
  // The locator is kept byte for byte (no Unicode normalisation): the file
  // system stores the name the scanner read.
  return LocalFile(
    p.joinAll([root, ...row.locator.split('/')]),
    row.durationMs,
  );
}

/// Resolves local tracks to file paths from the library database.
class LocalPlayableResolver implements PlayableResolver {
  LocalPlayableResolver(this._db);

  final DatabaseConnectionUser _db;

  @override
  Future<Map<TrackId, Playable>> resolve(List<TrackId> ids) async {
    final wanted = {for (final id in ids) id.value};
    final rows = <int, PlayableRow>{};
    final list = wanted.toList();
    for (var i = 0; i < list.length; i += _chunk) {
      final part = list.sublist(
        i,
        i + _chunk > list.length ? list.length : i + _chunk,
      );
      final result = await _db
          .customSelect(
            'SELECT t.id, t.status, t.locator, t.duration_ms, s.kind, '
            's.deleted_at, m.root, m.enabled '
            'FROM tracks t JOIN sources s ON s.id = t.source_id '
            'LEFT JOIN source_mounts m ON m.source_id = t.source_id '
            'WHERE t.id IN (${List.filled(part.length, '?').join(', ')})',
            variables: [for (final id in part) Variable.withInt(id)],
          )
          .get();
      for (final r in result) {
        rows[r.read<int>('id')] = PlayableRow(
          status: r.read<String>('status'),
          locator: r.read<String>('locator'),
          durationMs: r.readNullable<int>('duration_ms'),
          sourceKind: r.read<String>('kind'),
          sourceDeleted: r.readNullable<int>('deleted_at') != null,
          mountRoot: r.readNullable<String>('root'),
          mountEnabled: (r.readNullable<int>('enabled') ?? 0) != 0,
        );
      }
    }
    return {for (final id in wanted) TrackId(id): decidePlayable(rows[id])};
  }
}
