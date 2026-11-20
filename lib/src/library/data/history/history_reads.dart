import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/data/track_info_rows.dart';
import '../../domain/history/history_days.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_ordinal.dart';
import '../playlists/playlist_sql.dart' show jsonList;
import 'history_sql.dart';

Variable<int> _i(int v) => Variable.withInt(v);

Future<({int first, int last})?> readPlayedRange(AppDatabase db) async {
  final row = await db.customSelect(historyBoundsSql).getSingle();
  final lo = row.readNullable<int>('lo');
  final hi = row.readNullable<int>('hi');
  return lo == null || hi == null ? null : (first: lo, last: hi);
}

/// Years with a counted play, newest first: the span from the per-track
/// aggregate, then one index probe per candidate year.
Future<List<int>> readYears(AppDatabase db) async {
  final range = await readPlayedRange(db);
  if (range == null) return const [];
  final from = DateTime.fromMillisecondsSinceEpoch(range.first).year;
  final to = DateTime.fromMillisecondsSinceEpoch(range.last).year;
  final years = <int>[];
  for (var y = to; y >= from; y--) {
    final w = yearWindow(y);
    final row = await db
        .customSelect(
          historyWindowHasPlaySql,
          variables: [_i(w.start), _i(w.end)],
        )
        .getSingle();
    if (row.read<int>('has_play') == 1) years.add(y);
  }
  return years;
}

/// The plays of [year] with their all-time ordinal. The three reads (plays,
/// plays after the year, play counts) share one transaction so they describe
/// one state of the log; the ordinals are then worked out in Dart.
Future<List<HistoryPlay>> readYearPlays(AppDatabase db, int year) async {
  final w = yearWindow(year);
  final snapshot = await db.transaction(() async {
    final rows = await db
        .customSelect(historyYearPlaysSql, variables: [_i(w.start), _i(w.end)])
        .get();
    if (rows.isEmpty) return null;
    final after = await db
        .customSelect(historyAfterCountsSql, variables: [_i(w.end)])
        .get();
    final tracks = {for (final r in rows) r.read<int>('track_id')};
    final counts = await db
        .customSelect(historyPlayCountsSql, variables: [jsonList(tracks)])
        .get();
    return (rows: rows, after: after, counts: counts, tracks: tracks);
  });
  if (snapshot == null) return const [];
  final trackIds = [for (final r in snapshot.rows) r.read<int>('track_id')];
  final ordinals = assignOrdinals(
    trackIds,
    playCount: {
      for (final r in snapshot.counts)
        r.read<int>('track_id'): r.read<int>('play_count'),
    },
    afterYear: {
      for (final r in snapshot.after) r.read<int>('track_id'): r.read<int>('n'),
    },
  );
  final infos = await infosById(db, snapshot.tracks);
  return [
    for (var i = 0; i < snapshot.rows.length; i++)
      if (infos[trackIds[i]] case final info?)
        HistoryPlay(
          id: snapshot.rows[i].read<int>('id'),
          uid: snapshot.rows[i].read<String>('uid'),
          track: info,
          playedAt: snapshot.rows[i].read<int>('played_at'),
          listenedMs: snapshot.rows[i].readNullable<int>('listened_ms'),
          ordinal: ordinals[i],
        ),
  ];
}

/// [plays] with fresh track metadata; a play whose track is gone is dropped.
Future<List<HistoryPlay>> refreshInfos(
  AppDatabase db,
  List<HistoryPlay> plays,
) async {
  final infos = await infosById(db, {for (final p in plays) p.track.id.value});
  return [
    for (final p in plays)
      if (infos[p.track.id.value] case final info?) p.withTrack(info),
  ];
}

/// [TrackInfo] of every id of [ids] that still has a track row, by id.
Future<Map<int, TrackInfo>> infosById(AppDatabase db, Set<int> ids) async => {
  for (final info in await loadTrackInfos(db, [
    for (final id in ids) TrackId(id),
  ]))
    info.id.value: info,
};

Future<Set<DateTime>> readPlayDays(AppDatabase db, int start, int end) async {
  final rows = await db
      .customSelect(historyPlayTimesSql, variables: [_i(start), _i(end)])
      .get();
  return {
    for (final r in rows)
      localDay(DateTime.fromMillisecondsSinceEpoch(r.read<int>('played_at'))),
  };
}

Future<int> readCountPlays(AppDatabase db, int start, int end) async {
  final row = await db
      .customSelect(historyCountSql, variables: [_i(start), _i(end)])
      .getSingle();
  return row.read<int>('n');
}

Future<List<TrackId>> readPlayedTracks(AppDatabase db) async => [
  for (final r in await db.customSelect(historyPlayedTracksSql).get())
    TrackId(r.read<int>('track_id')),
];
