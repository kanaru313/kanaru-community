import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_store.dart';
import 'playlist_overlay_edits.dart';
import 'playlist_providers.dart';
import 'playlist_write_queue.dart';

export 'playlist_write_queue.dart' show PlaylistWriteFailure;

final _log = Logger('library.playlists');

/// The detail the page shows (stored detail plus pending edits) and whether
/// a write is queued or running.
class PlaylistPageState {
  const PlaylistPageState({required this.detail, required this.busy});

  final AsyncValue<PlaylistDetail?> detail;
  final bool busy;

  @override
  bool operator ==(Object other) =>
      other is PlaylistPageState &&
      other.detail == detail &&
      other.busy == busy;

  @override
  int get hashCode => Object.hash(detail, busy);
}

/// Playlist page state with a write gate: writes run one at a time in call
/// order, each shows its effect at once (before its first await) and the
/// stored state is re-read after the last one. When a write fails, the ones
/// queued behind it are cancelled (their basis is gone) and the stored state
/// is read once.
///
/// While busy, values of the stored stream are held. When idle, a stream or
/// settled value replaces the shown one unless it is older by `updatedAt`
/// (every real write bumps it), so a load that started before the last write
/// can never bring back the old order. Equal `updatedAt` takes the new value
/// when idle: same writes, possibly newer track infos. At the end of a burst
/// a held value must be strictly newer than the settled read (that read
/// started after the last write, `updatedAt` can tie within a millisecond).
///
/// A page that is disposed (or rebuilt) with writes queued still runs them in
/// order; calls on a kept notifier after dispose keep working, only state
/// updates stop. A rebuild keeps the queue and the shown state while busy.
class PlaylistPageController extends Notifier<PlaylistPageState> {
  PlaylistPageController(this.uid);

  final String uid;

  late PlaylistStore _store;
  AsyncValue<PlaylistDetail?> _saved = const AsyncLoading();
  PlaylistDetail? _overlay;
  ({PlaylistDetail? value})? _held;
  final _queue = Queue<WriteJob>();
  final _waiting = <Completer<void>>[];
  bool _busy = false;

  /// Edits of the writes that finished since the last settle.
  final _written = <DetailEdit>[];

  @override
  PlaylistPageState build() {
    _store = ref.read(playlistStoreProvider);
    // A rebuild (invalidate) keeps this instance: while a worker runs, its
    // queue, overlay and held value stay; only an idle page starts over.
    ref.onDispose(() {
      // Rebuilds dispose too: release only when the page is really gone.
      scheduleMicrotask(() {
        if (!ref.mounted) _releaseWaiting();
      });
    });
    ref.listen(playlistDetailProvider(uid), (_, next) => _onStored(next));
    if (!_busy) {
      _saved = ref.read(playlistDetailProvider(uid));
      _overlay = null;
      _held = null;
    }
    return _snapshot();
  }

  /// Completes when no write is queued or running (at once when idle). Also
  /// completes when the page is disposed: check `mounted` after it.
  Future<void> afterWrites() {
    if (!_busy) return Future.value();
    final completer = Completer<void>();
    _waiting.add(completer);
    return completer.future;
  }

  /// Moves [entryUid] behind [afterEntryUid] (null: to the top). "Unchanged"
  /// counts as success; a vanished playlist or entry is a failure.
  Future<void> move(String entryUid, {required String? afterEntryUid}) =>
      _enqueue<PlaylistMove>(
        moveEdit(entryUid, afterEntryUid),
        () => _store.moveEntry(uid, entryUid, afterEntryUid: afterEntryUid),
        (r) => r == PlaylistMove.gone
            ? StateError('playlist or entry is gone')
            : null,
      );

  /// Removes the shown entries among [entryUids]; null (and no write) when
  /// none is shown.
  Future<PlaylistRemoval?> remove(List<String> entryUids) {
    final shown = {
      for (final e in _shown?.entries ?? const <PlaylistEntryView>[]) e.uid,
    };
    final target = {
      for (final uid in entryUids)
        if (shown.contains(uid)) uid,
    };
    if (target.isEmpty) return Future.value();
    return _removal(
      removeEdit(target),
      () => _store.removeEntries(uid, target.toList()),
    );
  }

  /// Removes every repeat of a track; null (and no write) when there is none.
  Future<PlaylistRemoval?> removeDuplicates() {
    if ((_shown?.duplicateCount ?? 0) == 0) return Future.value();
    return _removal(removeDuplicatesEdit, () => _store.removeDuplicates(uid));
  }

  /// Removes the entries whose track is missing or hidden, as shown now; null
  /// (and no write) when there is none.
  Future<PlaylistRemoval?> removeUnavailable() {
    final target = {
      for (final e in _shown?.entries ?? const <PlaylistEntryView>[])
        if (!e.available) e.uid,
    };
    if (target.isEmpty) return Future.value();
    return _removal(
      removeEdit(target),
      () => _store.removeEntries(uid, target.toList()),
    );
  }

  /// Brings removed entries back, behind the writes already queued; also works
  /// on a notifier kept after the page closed. A removal of another playlist
  /// is an `ArgumentError`.
  Future<int> undo(PlaylistRemoval removal) {
    if (removal.playlistUid != uid) {
      return Future.error(
        ArgumentError.value(removal.playlistUid, 'removal', 'not of page $uid'),
      );
    }
    return _enqueue<int>(
      null,
      () => _store.undoRemoval(removal),
      (_) => null, // 0 revived: already committed, nothing left to undo
    );
  }

  PlaylistDetail? get _shown => _overlay ?? _saved.value;

  Future<PlaylistRemoval?> _removal(
    DetailEdit edit,
    Future<PlaylistRemoval?> Function() run,
  ) => _enqueue<PlaylistRemoval?>(
    edit,
    run,
    (r) => r == null ? StateError('nothing was removed') : null,
  );

  /// Applies [edit] to the shown detail now, queues [run] and starts the
  /// worker. Not `async`: nothing may be awaited before the state is set.
  Future<R> _enqueue<R>(
    DetailEdit? edit,
    Future<R> Function() run,
    Object? Function(R) failureOf,
  ) {
    final job = TypedWriteJob<R>(edit, run, failureOf);
    final base = _shown;
    if (edit != null && base != null) _overlay = edit(base);
    _queue.add(job);
    final start = !_busy;
    _busy = true;
    _publish();
    if (start) unawaited(_work());
    return job.future;
  }

  Future<void> _work() async {
    try {
      while (true) {
        var failed = false;
        while (_queue.isNotEmpty) {
          final job = _queue.removeFirst();
          final failure = await job.execute();
          if (failure == null) {
            final edit = job.edit;
            if (edit != null) _written.add(edit);
            continue;
          }
          _log.warning('A playlist write failed', failure.error, failure.stack);
          failed = true;
          job.fail(PlaylistWriteFailure(failure.error));
          final cancelled = PlaylistWriteFailure(
            failure.error,
            cancelled: true,
          );
          for (final queued in _queue) {
            queued.fail(cancelled);
          }
          _queue.clear();
        }
        if (!ref.mounted) return;
        await _settle(failed: failed);
        if (!ref.mounted) {
          // Page gone during the read: still run what was queued meanwhile.
          if (_queue.isNotEmpty) continue;
          return;
        }
        if (_queue.isNotEmpty) {
          // Writes queued while the read ran were applied to an older state.
          var shown = _saved.value;
          if (shown != null) {
            for (final job in _queue) {
              final edit = job.edit;
              if (edit != null) shown = edit(shown!);
            }
          }
          _overlay = shown == _saved.value ? null : shown;
          _publish();
          continue;
        }
        _overlay = null;
        _busy = false;
        _publish();
        _releaseWaiting();
        return;
      }
    } finally {
      // Every exit (page gone, unexpected error) leaves the gate usable.
      if (_busy && _queue.isEmpty) {
        _busy = false;
        _overlay = null;
        _publish();
        _releaseWaiting();
      }
    }
  }

  /// Reads the stored state once. When the read fails, a burst that failed
  /// keeps the last saved detail; one that succeeded keeps its own result
  /// (the optimistic detail) until the stream delivers something newer.
  Future<void> _settle({required bool failed}) async {
    ({PlaylistDetail? value})? read;
    try {
      read = (value: await _store.loadPlaylist(uid));
    } on Object catch (error, stack) {
      _log.warning('Reading the playlist after a write failed', error, stack);
    }
    final written = [..._written];
    _written.clear();
    if (!ref.mounted) return;
    final held = _held;
    _held = null;
    if (read != null) {
      _saved = AsyncData(read.value);
    } else if (!failed) {
      // Only the edits of writes that finished count, not those queued while
      // the read ran.
      var shown = _saved.value;
      if (shown != null) {
        for (final edit in written) {
          shown = edit(shown!);
        }
        _saved = AsyncData(shown);
      }
    }
    if (held != null) _takeIfNewer(held.value);
  }

  void _onStored(AsyncValue<PlaylistDetail?> next) {
    switch (next) {
      case AsyncLoading():
        return;
      case AsyncData(:final value):
        if (_busy) {
          _held = (value: value);
          return;
        }
        _take(value);
      case AsyncError():
        if (_busy) return;
        _saved = next;
    }
    _publish();
  }

  /// Takes a stored value unless it is older than the one held.
  void _take(PlaylistDetail? incoming) {
    final current = _saved.value;
    if (incoming != null &&
        current != null &&
        incoming.summary.updatedAt < current.summary.updatedAt) {
      return;
    }
    _saved = AsyncData(incoming);
  }

  /// Takes a stored value only when it is strictly newer than the one held.
  void _takeIfNewer(PlaylistDetail? incoming) {
    final current = _saved.value;
    if (incoming == null || current == null) return;
    if (incoming.summary.updatedAt > current.summary.updatedAt) {
      _saved = AsyncData(incoming);
    }
  }

  PlaylistPageState _snapshot() => PlaylistPageState(
    detail: _overlay != null ? AsyncData(_overlay) : _saved,
    busy: _busy,
  );

  void _publish() {
    if (!ref.mounted) return;
    state = _snapshot();
  }

  void _releaseWaiting() {
    final waiting = [..._waiting];
    _waiting.clear();
    for (final c in waiting) {
      if (!c.isCompleted) c.complete();
    }
  }
}

final playlistPageProvider =
    NotifierProvider.family<PlaylistPageController, PlaylistPageState, String>(
      PlaylistPageController.new,
      isAutoDispose: true,
    );
