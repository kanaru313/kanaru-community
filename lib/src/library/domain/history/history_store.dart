import '../../../media/domain/track_id.dart';
import 'history_change.dart';
import 'history_models.dart';

/// Reads and single-play writes of the listen history. Range deletes (delete a
/// day, clear history) are not here: they go through the listen recorder so an
/// open listen is not counted into a range being cleared.
///
/// Every read leaves out removed (tombstoned) and skipped plays.
abstract interface class HistoryStore {
  /// Local calendar years that have at least one play, newest first.
  Future<List<int>> years();

  /// Epoch ms of the first and last counted play; null when there is none.
  Future<({int first, int last})?> playedRange();

  /// Every play of [year], newest first, with its all-time ordinal. One
  /// consistent snapshot.
  Future<List<HistoryPlay>> yearPlays(int year);

  /// Plays, songs and the first play over all time.
  Future<HistoryOverview> overview();

  /// All plays of one song, newest first; null when the track does not exist.
  Future<TrackHistory?> trackHistory(TrackId id);

  /// The most played songs of `[start, end)` (all time when [window] is
  /// null), at most [limit], with the totals of the whole window.
  Future<MostPlayed> top({({int start, int end})? window, required int limit});

  /// Local days of `[start, end)` that have a play.
  Future<Set<DateTime>> playDays(int start, int end);

  /// Plays in `[start, end)`.
  Future<int> countPlays(int start, int end);

  /// Tracks ever played, last played first.
  Future<List<TrackId>> playedTracksNewestFirst();

  /// [plays] with fresh track metadata (ordinals kept); a play whose track is
  /// gone is dropped.
  Future<List<HistoryPlay>> refreshTracks(List<HistoryPlay> plays);

  /// Emits when the plays change (not a listened-time checkpoint), debounced,
  /// with the kinds seen in the window: the current year re-reads on either,
  /// an older year only when plays were [HistoryChange.removed] (an undo
  /// reports both).
  Stream<HistoryChange> watchPlays();

  /// Emits when track metadata changes, debounced; only infos need reloading.
  Stream<void> watchTracks();

  /// Tombstones the plays [uids]; null when none was live.
  Future<HistoryBatch?> removePlays(List<String> uids);

  /// Revives the plays of every batch whose tombstone is still its own stamp;
  /// returns how many came back.
  Future<int> undoBatches(List<HistoryBatch> batches);

  /// Deletes the tombstones of [batches] for good. Idempotent.
  Future<void> commitBatches(List<HistoryBatch> batches);
}
