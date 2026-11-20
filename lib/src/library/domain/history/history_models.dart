import '../../../media/domain/track_info.dart';
import 'history_days.dart';

/// One counted play, with the all-time number of this play of its song.
class HistoryPlay {
  const HistoryPlay({
    required this.id,
    required this.uid,
    required this.track,
    required this.playedAt,
    required this.listenedMs,
    required this.ordinal,
  });

  final int id;
  final String uid;
  final TrackInfo track;

  /// Epoch ms the play began.
  final int playedAt;
  final int? listenedMs;

  /// "This was the nth time the song was played", counting from 1.
  final int ordinal;

  HistoryPlay withTrack(TrackInfo track) => HistoryPlay(
    id: id,
    uid: uid,
    track: track,
    playedAt: playedAt,
    listenedMs: listenedMs,
    ordinal: ordinal,
  );
}

/// The plays of one local day, newest first, with the figures of its header.
class HistoryDay {
  HistoryDay(this.start, this.plays)
    : songCount = {for (final p in plays) p.track.id.value}.length,
      listenedMs = plays.fold(0, (sum, p) => sum + (p.listenedMs ?? 0));

  /// Local midnight of the day.
  final DateTime start;
  final List<HistoryPlay> plays;
  final int songCount;
  final int listenedMs;

  int get playCount => plays.length;
}

/// Splits [plays] (newest first) into local days, newest day first.
List<HistoryDay> groupByDay(List<HistoryPlay> plays) {
  final days = <HistoryDay>[];
  var current = <HistoryPlay>[];
  DateTime? currentDay;
  for (final play in plays) {
    final day = localDay(DateTime.fromMillisecondsSinceEpoch(play.playedAt));
    if (currentDay != null && !isSameDay(day, currentDay)) {
      days.add(HistoryDay(currentDay, current));
      current = <HistoryPlay>[];
    }
    currentDay = day;
    current.add(play);
  }
  if (currentDay != null) days.add(HistoryDay(currentDay, current));
  return days;
}

/// Plays, songs and the first play over all time.
class HistoryOverview {
  const HistoryOverview({
    required this.plays,
    required this.songs,
    required this.since,
  });

  final int plays;
  final int songs;

  /// Epoch ms of the first play; null when there is none.
  final int? since;
}

/// Every play of one song.
class TrackHistory {
  const TrackHistory({
    required this.track,
    required this.plays,
    required this.first,
    required this.last,
    required this.listenedMs,
    required this.list,
  });

  final TrackInfo track;
  final int plays;
  final int? first;
  final int? last;
  final int listenedMs;

  /// Newest first; `list[i].ordinal == plays - i`.
  final List<HistoryPlay> list;
}

/// One row of the Most played list.
class TopEntry {
  const TopEntry({
    required this.rank,
    required this.track,
    required this.count,
    required this.lastPlayedAt,
  });

  final int rank;
  final TrackInfo track;
  final int count;
  final int lastPlayedAt;
}

/// The Most played list of a window and the totals of the whole window (not
/// only of the listed rows).
class MostPlayed {
  const MostPlayed({
    required this.entries,
    required this.songs,
    required this.plays,
  });

  final List<TopEntry> entries;
  final int songs;
  final int plays;
}

/// The plays one removal tombstoned: [stamp] is their `deleted_at`, which an
/// undo checks so a play removed again later is not brought back by mistake.
class HistoryBatch {
  const HistoryBatch({required this.uids, required this.stamp});

  final List<String> uids;
  final int stamp;
}

/// What a tap on [tapped] plays: the songs of [shown] in order, each once at
/// its first appearance, without the ones that cannot play (missing or
/// hidden). `null` when [tapped] itself cannot play. [tapped] not being in
/// [shown] (the list was read again meanwhile) plays just that song.
({List<TrackInfo> tracks, int startIndex})? playableQueue(
  List<TrackInfo> shown,
  TrackInfo tapped,
) {
  if (!_canPlay(tapped)) return null;
  final seen = <int>{};
  final tracks = <TrackInfo>[
    for (final t in shown)
      if (_canPlay(t) && seen.add(t.id.value)) t,
  ];
  final start = tracks.indexWhere((t) => t.id == tapped.id);
  return start < 0
      ? (tracks: [tapped], startIndex: 0)
      : (tracks: tracks, startIndex: start);
}

bool _canPlay(TrackInfo t) =>
    t.status != TrackAvailability.missing &&
    t.status != TrackAvailability.hidden;
