import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/state/listen_recorder_provider.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/state/playback_settings_providers.dart';
import '../../domain/history/history_clear_scope.dart';
import '../../domain/history/history_days.dart';
import '../../domain/history/history_models.dart';
import '../browse/song_list_providers.dart' show trackRowLoaderProvider;
import 'history_providers.dart';
import 'history_removal_holder.dart';

final _log = Logger('library.history');

/// Everything the History and Most played pages do besides reading.
///
/// A write that fails is logged by type only and reported to the caller
/// (`null` or `false`) so the screen can say so; nothing here shows UI.
final historyActionsProvider = Provider<HistoryActions>(HistoryActions.new);

class HistoryActions {
  HistoryActions(this._ref);

  final Ref _ref;

  HistoryRemovalHolder get _holder => _ref.read(historyRemovalHolderProvider);

  /// Plays [shown] from [tapped] on: each song once, songs that cannot play
  /// left out. False when [tapped] itself cannot play.
  Future<bool> playFrom(
    List<TrackInfo> shown,
    TrackInfo tapped, {
    String? label,
  }) async {
    final queue = playableQueue(shown, tapped);
    if (queue == null) return false;
    return _play(
      [for (final t in queue.tracks) t.id],
      startIndex: queue.startIndex,
      kind: PlayContextKind.history,
      label: label,
    );
  }

  /// Plays the songs of one day, newest play first, each once.
  Future<bool> playDay(HistoryDay day, {bool shuffle = false, String? label}) =>
      _playInfos(
        [for (final p in day.plays) p.track],
        shuffle: shuffle,
        kind: PlayContextKind.history,
        label: label,
      );

  /// Plays every song ever played, last played first, without the ones that
  /// cannot play. False when there is nothing to play or the read failed.
  Future<bool> playAllHistory({bool shuffle = false, String? label}) async {
    try {
      final ids = await _ref
          .read(historyStoreProvider)
          .playedTracksNewestFirst();
      final infos = await _ref.read(trackRowLoaderProvider)(ids);
      return await _playInfos(
        infos,
        shuffle: shuffle,
        kind: PlayContextKind.history,
        label: label,
      );
    } on Object catch (e) {
      _log.warning('Playing all history failed: ${e.runtimeType}');
      return false;
    }
  }

  /// Plays the Most played [entries] in rank order (from [tapped] when
  /// given), songs that cannot play left out.
  Future<bool> playTop(
    List<TopEntry> entries, {
    TrackInfo? tapped,
    bool shuffle = false,
    String? label,
  }) {
    final infos = [for (final e in entries) e.track];
    if (tapped != null) {
      final queue = playableQueue(infos, tapped);
      if (queue == null) return Future.value(false);
      return _play(
        [for (final t in queue.tracks) t.id],
        startIndex: queue.startIndex,
        shuffle: shuffle,
        kind: PlayContextKind.mostPlayed,
        label: label,
      );
    }
    return _playInfos(
      infos,
      shuffle: shuffle,
      kind: PlayContextKind.mostPlayed,
      label: label,
    );
  }

  Future<bool> _playInfos(
    List<TrackInfo> infos, {
    required bool shuffle,
    required PlayContextKind kind,
    String? label,
  }) {
    final seen = <int>{};
    final ids = [
      for (final t in infos)
        if (canPlayTrack(t) && seen.add(t.id.value)) t.id,
    ];
    if (ids.isEmpty) return Future.value(false);
    return _play(ids, shuffle: shuffle, kind: kind, label: label);
  }

  Future<bool> _play(
    List<TrackId> ids, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContextKind kind,
    String? label,
  }) async {
    try {
      await _ref
          .read(playbackCommandsProvider)
          .playTracks(
            ids,
            startIndex: startIndex,
            shuffle: shuffle,
            context: PlayContext(kind, label: label),
          );
      return true;
    } on Object catch (e) {
      _log.warning('Playing history failed: ${e.runtimeType}');
      return false;
    }
  }

  /// Removes one play (it can be undone while its toast is open). Returns how
  /// many plays wait for the toast in all (the removals merge), 0 when the
  /// play was gone already, null when the write failed.
  Future<int?> remove(HistoryPlay play) async {
    try {
      final batch = await _ref.read(historyStoreProvider).removePlays([
        play.uid,
      ]);
      if (batch != null) _holder.add(batch);
      return _holder.pendingCount;
    } on Object catch (e) {
      _log.warning('Removing a play failed: ${e.runtimeType}');
      return null;
    }
  }

  /// Registers how to close the toast now showing the pending removals, on
  /// the same holder that took the removal (see [remove]).
  void attachToast(HistoryToastHandle hide) => _holder.attachToast(hide);

  /// The removal toast [hide] closed without Undo: commits the removals.
  /// False when the commit failed, so the screen can show the error toast.
  Future<bool> toastClosed(HistoryToastHandle hide) =>
      _holder.toastClosed(hide);

  /// Brings every pending removal back. False when the write failed.
  Future<bool> undo() async {
    try {
      await _holder.undo();
      return true;
    } on Object {
      return false;
    }
  }

  /// Deletes every play that started on local [day]; see [clear] for the
  /// result.
  Future<int?> deleteDay(DateTime day) {
    final start = localDay(day);
    return _clearRange(
      from: start.millisecondsSinceEpoch,
      to: addDays(start, 1).millisecondsSinceEpoch,
    );
  }

  /// Deletes the plays [scope] covers, all taken from the fixed [now] the
  /// dialog showed its counts for. Returns how many went, null on failure.
  Future<int?> clear(ClearScope scope, DateTime now) {
    final bounds = scope.bounds(now);
    return _clearRange(from: bounds.from, to: bounds.to);
  }

  Future<int?> _clearRange({int? from, int? to}) async {
    // Pending removals first: a tombstoned play outside a live-rows delete
    // would come back with Undo after the clear. A failed commit is logged by
    // the holder and does not stop the clear: its batches are dropped, so
    // nothing can undo them any more.
    await _holder.commit();
    final count = await _ref
        .read(listenRecorderProvider)
        .clearHistory(from: from, to: to);
    if (count == null) _log.warning('Clearing history failed');
    return count;
  }

  /// How many plays each scope would delete at [now], for the dialog.
  Future<Map<ClearScope, int>> counts(DateTime now) async {
    final store = _ref.read(historyStoreProvider);
    final out = <ClearScope, int>{};
    for (final scope in ClearScope.values) {
      final b = scope.bounds(now);
      out[scope] = b.from == null || b.to == null
          ? (await store.overview()).plays
          : await store.countPlays(b.from!, b.to!);
    }
    return out;
  }

  /// Switches recording of listens back on (the notice on the empty page).
  Future<void> enableRecording() =>
      _ref.read(historyEnabledProvider.notifier).set(true);
}
