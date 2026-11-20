import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../../playback/data/track_info_rows.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_ranges.dart' show clampMostPlayedLimit;
import 'history_reads.dart' show infosById;
import 'history_sql.dart';

Variable<int> _i(int v) => Variable.withInt(v);

Future<HistoryOverview> readOverview(AppDatabase db) async {
  final row = await db.customSelect(historyOverviewSql).getSingle();
  return HistoryOverview(
    plays: row.read<int>('plays'),
    songs: row.read<int>('songs'),
    since: row.readNullable<int>('since'),
  );
}

/// Every play of [id]; null when the track does not exist.
Future<TrackHistory?> readTrackHistory(AppDatabase db, TrackId id) async {
  final info = (await loadTrackInfos(db, [id])).firstOrNull;
  if (info == null) return null;
  final rows = await db
      .customSelect(historyTrackPlaysSql, variables: [_i(id.value)])
      .get();
  final count = rows.length;
  final list = [
    for (var i = 0; i < count; i++)
      HistoryPlay(
        id: rows[i].read<int>('id'),
        uid: rows[i].read<String>('uid'),
        track: info,
        playedAt: rows[i].read<int>('played_at'),
        listenedMs: rows[i].readNullable<int>('listened_ms'),
        ordinal: count - i,
      ),
  ];
  return TrackHistory(
    track: info,
    plays: count,
    first: list.isEmpty ? null : list.last.playedAt,
    last: list.isEmpty ? null : list.first.playedAt,
    listenedMs: list.fold(0, (sum, p) => sum + (p.listenedMs ?? 0)),
    list: list,
  );
}

/// The list and the window totals in one transaction; [limit] is clamped to
/// the 1-1000 the list accepts (SQLite reads a negative LIMIT as none).
Future<MostPlayed> readMostPlayed(
  AppDatabase db, {
  required ({int start, int end})? window,
  required int limit,
}) => db.transaction(() async {
  final cap = clampMostPlayedLimit(limit);
  final rows = window == null
      ? await db.customSelect(historyTopAllSql, variables: [_i(cap)]).get()
      : await db
            .customSelect(
              historyTopWindowSql,
              variables: [_i(window.start), _i(window.end), _i(cap)],
            )
            .get();
  final totals = window == null
      ? await readOverview(db).then((o) => (songs: o.songs, plays: o.plays))
      : await db
            .customSelect(
              historyWindowTotalsSql,
              variables: [_i(window.start), _i(window.end)],
            )
            .getSingle()
            .then(
              (r) => (songs: r.read<int>('songs'), plays: r.read<int>('plays')),
            );
  final infos = await infosById(db, {
    for (final r in rows) r.read<int>('track_id'),
  });
  final entries = <TopEntry>[];
  for (final r in rows) {
    final info = infos[r.read<int>('track_id')];
    if (info == null) continue;
    entries.add(
      TopEntry(
        rank: entries.length + 1,
        track: info,
        count: r.read<int>('n'),
        lastPlayedAt: r.read<int>('last'),
      ),
    );
  }
  return MostPlayed(entries: entries, songs: totals.songs, plays: totals.plays);
});
