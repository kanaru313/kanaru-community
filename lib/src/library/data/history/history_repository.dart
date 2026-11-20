import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/history/history_change.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_store.dart';
import 'history_reads.dart';
import 'history_summary_reads.dart';
import 'history_watch.dart';
import 'history_writes.dart';

/// [HistoryStore] on `play_log` / `play_stats`. Every write is one
/// transaction; [clock] (epoch ms) is injectable for tests.
class HistoryRepository implements HistoryStore {
  HistoryRepository(this._db, {int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final int Function() _clock;

  @override
  Future<List<int>> years() => readYears(_db);

  @override
  Future<({int first, int last})?> playedRange() => readPlayedRange(_db);

  @override
  Future<List<HistoryPlay>> yearPlays(int year) => readYearPlays(_db, year);

  @override
  Future<List<HistoryPlay>> refreshTracks(List<HistoryPlay> plays) =>
      refreshInfos(_db, plays);

  @override
  Future<HistoryOverview> overview() => readOverview(_db);

  @override
  Future<TrackHistory?> trackHistory(TrackId id) => readTrackHistory(_db, id);

  @override
  Future<MostPlayed> top({
    ({int start, int end})? window,
    required int limit,
  }) => readMostPlayed(_db, window: window, limit: limit);

  @override
  Future<Set<DateTime>> playDays(int start, int end) =>
      readPlayDays(_db, start, end);

  @override
  Future<int> countPlays(int start, int end) => readCountPlays(_db, start, end);

  @override
  Future<List<TrackId>> playedTracksNewestFirst() => readPlayedTracks(_db);

  @override
  Stream<HistoryChange> watchPlays() => watchPlayLog(_db);

  @override
  Stream<void> watchTracks() => watchTracksChanged(_db);

  @override
  Future<HistoryBatch?> removePlays(List<String> uids) =>
      removePlaysWrite(_db, uids, _clock());

  @override
  Future<int> undoBatches(List<HistoryBatch> batches) =>
      undoBatchesWrite(_db, batches, _clock());

  @override
  Future<void> commitBatches(List<HistoryBatch> batches) =>
      commitBatchesWrite(_db, batches);
}
