import 'dart:async';

import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/saved_queues/saved_queue_store.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

TrackInfo song(
  int id, {
  String? title,
  TrackAvailability status = TrackAvailability.present,
  int durationMs = 60000,
}) => TrackInfo(
  id: TrackId(id),
  title: title ?? 'Song $id',
  artist: 'Artist',
  status: status,
  relPath: 't$id.flac',
  durationMs: durationMs,
);

/// A saved queue with songs [ids] (an id in [missing] is a missing song).
/// `trackCount` and the duration count each distinct song once, as the store.
PlaylistDetail savedQueue(
  String uid, {
  required int savedAt,
  required List<int> ids,
  Set<int> missing = const {},
  String? kind,
  String? ref,
  String? label,
}) {
  final entries = [
    for (var i = 0; i < ids.length; i++)
      PlaylistEntryView(
        uid: '$uid-e$i',
        info: song(
          ids[i],
          status: missing.contains(ids[i])
              ? TrackAvailability.missing
              : TrackAvailability.present,
        ),
      ),
  ];
  final distinct = {for (final e in entries) e.info.id.value: e.info};
  return PlaylistDetail(
    summary: PlaylistSummary(
      uid: uid,
      name: 'Queue',
      description: '',
      isFavorites: false,
      trackCount: distinct.length,
      durationMs: distinct.values.fold(0, (a, t) => a + (t.durationMs ?? 0)),
      createdAt: savedAt,
      updatedAt: savedAt,
      autoCoverKeys: const [],
      savedQueue: SavedQueueInfo(
        savedAt: savedAt,
        contextKind: kind,
        contextRef: ref,
        contextLabel: label,
      ),
    ),
    entries: entries,
  );
}

extension PlainPlaylist on PlaylistDetail {
  /// The same entries as an ordinary playlist (no saved-queue info).
  PlaylistDetail copyWithoutSavedQueue() => PlaylistDetail(
    summary: PlaylistSummary(
      uid: summary.uid,
      name: summary.name,
      description: '',
      isFavorites: false,
      trackCount: summary.trackCount,
      durationMs: summary.durationMs,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      autoCoverKeys: summary.autoCoverKeys,
    ),
    entries: entries,
  );
}

/// A [SavedQueueStore] over a list the test edits. Reads can be made to fail
/// ([failReads]) and writes too ([failWrites]); writes are recorded.
class FakeSavedQueueStore implements SavedQueueStore {
  FakeSavedQueueStore([Iterable<PlaylistDetail> queues = const []])
    : queues = [...queues];

  /// Newest first, as the store lists them.
  final List<PlaylistDetail> queues;
  final _changes = StreamController<void>.broadcast();

  bool failReads = false;
  bool failWrites = false;

  /// Runs right before a delete is applied (to see where the page was).
  void Function()? beforeDelete;

  /// What the page was asked to do, in order.
  final List<String> touched = [];
  final List<String> deleted = [];
  final List<String> prunedMissing = [];

  void _check(bool fail) {
    if (fail) throw StateError('store failed');
  }

  PlaylistDetail? _find(String uid) {
    for (final q in queues) {
      if (q.summary.uid == uid) return q;
    }
    return null;
  }

  /// Replaces the queues and tells every watcher.
  void set(Iterable<PlaylistDetail> next) {
    queues
      ..clear()
      ..addAll(next);
    _changes.add(null);
  }

  int _missingOf(PlaylistDetail d) => {
    for (final e in d.entries)
      if (!e.available) e.info.id.value,
  }.length;

  @override
  Stream<List<SavedQueueRow>> watchSavedQueues() async* {
    _check(failReads);
    List<SavedQueueRow> rows() => [
      for (final q in queues)
        SavedQueueRow(summary: q.summary, missingCount: _missingOf(q)),
    ];
    yield rows();
    await for (final _ in _changes.stream) {
      yield rows();
    }
  }

  @override
  Stream<PlaylistDetail?> watchSavedQueue(String uid) async* {
    _check(failReads);
    yield _find(uid);
    await for (final _ in _changes.stream) {
      yield _find(uid);
    }
  }

  @override
  Future<bool> touch(String uid) async {
    _check(failWrites);
    final q = _find(uid);
    if (q == null) return false;
    touched.add(uid);
    set([q, ...queues.where((o) => o != q)]);
    return true;
  }

  @override
  Future<bool> deleteSavedQueue(String uid) async {
    _check(failWrites);
    beforeDelete?.call();
    final q = _find(uid);
    if (q == null) return false;
    deleted.add(uid);
    set(queues.where((o) => o != q));
    return true;
  }

  @override
  Future<int> removeMissingFromSavedQueue(String uid) async {
    _check(failWrites);
    final q = _find(uid);
    if (q == null) return 0;
    prunedMissing.add(uid);
    final kept = [
      for (final e in q.entries)
        if (e.available) e,
    ];
    final removed = q.entries.length - kept.length;
    set([
      for (final o in queues)
        if (o == q) PlaylistDetail(summary: q.summary, entries: kept) else o,
    ]);
    return removed;
  }

  Future<void> close() => _changes.close();
}
