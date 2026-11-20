import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../playback/state/listen_recorder_provider.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_store.dart';
import 'history_providers.dart';

final _log = Logger('library.history');

/// Closes the toast the holder's removals showed. Set by the UI that shows it.
typedef HistoryToastHandle = void Function();

/// The removals of plays whose "Undo" toast is still open. Each removal
/// leaves tombstones in a batch; batches merge, so one Undo brings back every
/// play removed meanwhile and one commit deletes them all for good.
///
/// Commits happen when the toast closes, before a clear or a day delete, when
/// the recorder reports a clear, and when the container goes away. Both
/// [undo] and [commit] take the batches first, so overlapping triggers do
/// the work once.
class HistoryRemovalHolder {
  HistoryRemovalHolder(this._store, {Stream<void>? cleared}) {
    _sub = cleared?.listen((_) => unawaited(commit()));
  }

  final HistoryStore _store;
  StreamSubscription<void>? _sub;
  List<HistoryBatch> _batches = [];
  HistoryToastHandle? _hide;

  /// Plays waiting for their commit, for the merged toast message.
  int get pendingCount => _batches.fold(0, (n, b) => n + b.uids.length);

  bool get hasPending => _batches.isNotEmpty;

  /// Adds the batch of a removal that just happened.
  void add(HistoryBatch batch) => _batches.add(batch);

  /// Registers how to close the toast now showing the pending removals.
  /// A toast it replaces is no longer the one whose closing commits.
  void attachToast(HistoryToastHandle hide) => _hide = hide;

  /// The toast [hide] closed (timeout, swipe, any way but Undo): commits,
  /// unless it was replaced by a newer toast meanwhile. False when the
  /// commit failed, so the UI can show the error toast; true otherwise.
  Future<bool> toastClosed(HistoryToastHandle hide) async {
    if (!identical(_hide, hide)) return true;
    _hide = null;
    return commit();
  }

  /// Brings every pending batch back; returns how many plays returned. On a
  /// failed write the error is thrown to the caller and the batches are
  /// committed right away: their toast is gone, so nothing could undo them
  /// later, and a later removal's toast must not count them.
  Future<int> undo() async {
    final batches = _take();
    if (batches.isEmpty) return 0;
    try {
      return await _store.undoBatches(batches);
    } on Object catch (e) {
      _log.warning('Undoing removed plays failed: ${e.runtimeType}');
      await _commitBatches(batches);
      rethrow;
    }
  }

  /// Deletes every pending batch for good and closes the toast. Returns false
  /// when the store failed: the batches are dropped anyway (the tombstones
  /// stay hidden and are purged later) and the failure is logged by type.
  Future<bool> commit() => _commitBatches(_take());

  Future<bool> _commitBatches(List<HistoryBatch> batches) async {
    if (batches.isEmpty) return true;
    try {
      await _store.commitBatches(batches);
      return true;
    } on Object catch (e) {
      _log.warning('Committing removed plays failed: ${e.runtimeType}');
      return false;
    }
  }

  List<HistoryBatch> _take() {
    final batches = _batches;
    _batches = [];
    final hide = _hide;
    _hide = null;
    hide?.call();
    return batches;
  }

  /// Commits what is pending (the container is going away).
  Future<void> dispose() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
    await commit();
  }
}

final historyRemovalHolderProvider = Provider<HistoryRemovalHolder>((ref) {
  final holder = HistoryRemovalHolder(
    ref.watch(historyStoreProvider),
    cleared: ref.watch(listenRecorderProvider).cleared,
  );
  ref.onDispose(() => unawaited(holder.dispose()));
  return holder;
});
