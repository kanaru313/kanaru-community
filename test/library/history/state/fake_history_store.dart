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
  Future<TrackHistory?> trackHistory(TrackId id) async => null;

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
    return HistoryBatch(uids: uids, stamp: stamp++);
  }

  @override
  Future<int> undoBatches(List<HistoryBatch> batches) async {
    if (undoError != null) throw undoError!;
    undone.add(batches);
    return batches.fold<int>(0, (n, b) => n + b.uids.length);
  }

  @override
  Future<void> commitBatches(List<HistoryBatch> batches) async {
    if (commitError != null) throw commitError!;
    committed.add(batches);
  }
}
