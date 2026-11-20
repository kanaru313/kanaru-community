import 'dart:async';

import 'package:kanaru/src/library/domain/history/history_change.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/domain/history/history_store.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

TrackInfo info(
  int id, {
  String title = 'Song',
  TrackAvailability status = TrackAvailability.present,
  String? artist,
}) => TrackInfo(
  id: TrackId(id),
  title: title,
  artist: artist,
  status: status,
  relPath: 't$id.flac',
);

HistoryPlay play(int id, int year, {TrackInfo? track, int ordinal = 1}) =>
    HistoryPlay(
      id: id,
      uid: 'p$id',
      track: track ?? info(id, title: 'Song $id'),
      playedAt: DateTime(year, 6, 1, 12).millisecondsSinceEpoch + id,
      listenedMs: 1000,
      ordinal: ordinal,
    );

/// A [HistoryStore] with scripted answers and controllable change streams.
class FakeHistoryStore implements HistoryStore {
  final playsChanged = StreamController<HistoryChange>.broadcast();
  final tracksChanged = StreamController<void>.broadcast();

  Map<int, List<HistoryPlay>> byYear = {};
  List<int> yearsAnswer = [];
  HistoryOverview overviewAnswer = const HistoryOverview(
    plays: 0,
    songs: 0,
    since: null,
  );
  MostPlayed topAnswer = const MostPlayed(entries: [], songs: 0, plays: 0);
  ({int first, int last})? played;
  List<TrackId> playedTracks = [];
  Map<int, int> counts = {};

  /// Songs and their plays (newest first) that [trackHistory] answers from.
  /// A removal or an undo moves plays out of / back into these lists and
  /// reports the change, as the database does.
  final trackInfos = <int, TrackInfo>{};
  final trackPlays = <int, List<HistoryPlay>>{};
  final _hiddenByStamp = <int, List<(int, HistoryPlay)>>{};

  final yearReads = <int>[];

  /// When set, the next year read waits for it.
  Completer<void>? yearGate;
  var refreshCalls = 0;
  var overviewReads = 0;
  final topCalls = <({int start, int end})?>[];
  final removed = <List<String>>[];
  final undone = <List<HistoryBatch>>[];
  final committed = <List<HistoryBatch>>[];
  Object? removeError;
  Object? trackError;
  Object? undoError;
  Object? commitError;
  int stamp = 100;

  @override
  Future<List<int>> years() async => List.of(yearsAnswer);

  @override
  Future<({int first, int last})?> playedRange() async => played;

  @override
  Future<List<HistoryPlay>> yearPlays(int year) async {
    yearReads.add(year);
    final gate = yearGate;
    if (gate != null) {
      yearGate = null;
      await gate.future;
    }
    return List.of(byYear[year] ?? const []);
  }

  @override
  Future<HistoryOverview> overview() async {
    overviewReads++;
    return overviewAnswer;
  }

  @override
  Future<TrackHistory?> trackHistory(TrackId id) async {
    if (trackError != null) throw trackError!;
    final track = trackInfos[id.value];
    if (track == null) return null;
    final list = List.of(trackPlays[id.value] ?? const <HistoryPlay>[]);
    return TrackHistory(
      track: track,
      plays: list.length,
      first: list.isEmpty ? null : list.last.playedAt,
      last: list.isEmpty ? null : list.first.playedAt,
      listenedMs: list.fold(0, (sum, p) => sum + (p.listenedMs ?? 0)),
      list: list,
    );
  }

  @override
  Future<MostPlayed> top({
    ({int start, int end})? window,
    required int limit,
  }) async {
    topCalls.add(window);
    return topAnswer;
  }

  @override
  Future<Set<DateTime>> playDays(int start, int end) async => {};

  @override
  Future<int> countPlays(int start, int end) async => counts[start] ?? 0;

  @override
  Future<List<TrackId>> playedTracksNewestFirst() async => playedTracks;

  @override
  Future<List<HistoryPlay>> refreshTracks(List<HistoryPlay> plays) async {
    refreshCalls++;
    return [
      for (final p in plays) p.withTrack(info(p.track.id.value, title: 'New')),
    ];
  }

  @override
  Stream<HistoryChange> watchPlays() => playsChanged.stream;

  @override
  Stream<void> watchTracks() => tracksChanged.stream;

  @override
  Future<HistoryBatch?> removePlays(List<String> uids) async {
    if (removeError != null) throw removeError!;
    removed.add(uids);
    final batch = HistoryBatch(uids: uids, stamp: stamp++);
    final hidden = <(int, HistoryPlay)>[];
    for (final entry in trackPlays.entries) {
      for (final p in entry.value.where((p) => uids.contains(p.uid))) {
        hidden.add((entry.key, p));
      }
      entry.value.removeWhere((p) => uids.contains(p.uid));
    }
    if (hidden.isNotEmpty) {
      _hiddenByStamp[batch.stamp] = hidden;
      playsChanged.add(const HistoryChange(removed: true));
    }
    return batch;
  }

  @override
  Future<int> undoBatches(List<HistoryBatch> batches) async {
    if (undoError != null) throw undoError!;
    undone.add(batches);
    var revived = false;
    for (final b in batches) {
      for (final (track, p)
          in _hiddenByStamp.remove(b.stamp) ?? const <(int, HistoryPlay)>[]) {
        (trackPlays[track] ??= []).add(p);
        trackPlays[track]!.sort((a, b) => b.playedAt.compareTo(a.playedAt));
        revived = true;
      }
    }
    if (revived) playsChanged.add(const HistoryChange(inserted: true));
    return batches.fold<int>(0, (n, b) => n + b.uids.length);
  }

  @override
  Future<void> commitBatches(List<HistoryBatch> batches) async {
    if (commitError != null) throw commitError!;
    committed.add(batches);
  }
}
