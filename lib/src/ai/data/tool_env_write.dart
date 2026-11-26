import '../../library/domain/playlists/playlist_models.dart';
import '../../library/domain/playlists/playlist_store.dart';
import '../../media/domain/track_id.dart';
import '../../playback/domain/removed_queue_entry.dart';
import '../domain/conversation/parts.dart';
import '../domain/tools/tool_env.dart';
import '../domain/tools/tool_env_write.dart';

/// [PlaybackWritePort] over the player's tool entry points. The functions
/// hide whether they belong to a controller or a test fake.
class PlaybackWritePortImpl implements PlaybackWritePort {
  PlaybackWritePortImpl({
    required this.playTracks,
    required this.playNext,
    required this.enqueue,
    required this.removeQueueEntries,
    required this.queueIsEmpty,
  });

  final Future<ToolPlayResult> Function(
    List<TrackId> visible, {
    required String contextLabel,
    int startIndex,
  })
  playTracks;
  final Future<void> Function(List<TrackId> tracks) playNext;
  final Future<void> Function(List<TrackId> tracks) enqueue;
  final Future<List<RemovedQueueEntry>> Function(Set<int> entryIds)
  removeQueueEntries;
  final bool Function() queueIsEmpty;

  @override
  Future<ReplacedQueueSnapshot?> play(
    List<int> trackIds, {
    required int startIndex,
    required String contextLabel,
  }) async {
    final r = await playTracks(
      [for (final id in trackIds) TrackId(id)],
      contextLabel: contextLabel,
      startIndex: startIndex,
    );
    final previous = r.previous;
    if (previous == null) return null;
    return ReplacedQueueSnapshot(
      tracks: [for (final t in previous.tracks) t.value],
      userOrder: [for (final t in previous.userOrder) t.value],
      shuffled: r.shuffled,
      previousIndex: r.previousIndex,
    );
  }

  @override
  Future<({bool startedPlayback})> queue(
    List<int> trackIds, {
    required bool next,
  }) async {
    // An empty queue makes both calls start playback.
    final started = queueIsEmpty();
    final ids = [for (final id in trackIds) TrackId(id)];
    await (next ? playNext(ids) : enqueue(ids));
    return (startedPlayback: started);
  }

  @override
  Future<List<QueueEntryRef>> removeEntries(List<int> entryIds) async {
    final removed = await removeQueueEntries(entryIds.toSet());
    return [
      for (final e in removed)
        QueueEntryRef(entryId: e.entryId, trackId: e.trackId.value),
    ];
  }
}

/// [PlaylistsWritePort] over the playlist store. Ids are the integer ids of
/// `PlaylistsPort`; a playlist that is not writable (saved queue, mood,
/// deleted) is "not found".
class PlaylistsWritePortImpl implements PlaylistsWritePort {
  PlaylistsWritePortImpl({required this.store});

  final PlaylistStore store;

  Future<({String uid, String name})?> _target(int id) async {
    final uid = (await store.resolvePlaylistIds([id]))[id];
    if (uid == null) return null;
    final writable = await store.listWritable();
    for (final p in writable) {
      if (p.uid == uid) return (uid: uid, name: p.name);
    }
    return null;
  }

  @override
  Future<({int? id, int count})> create(String name, List<int> trackIds) async {
    // The playlist exists after this call. Whatever fails after it is
    // swallowed on purpose: reporting an error would make the model create the
    // playlist a second time.
    final uid = await store.createPlaylist(
      name: name,
      tracks: [for (final id in trackIds) TrackId(id)],
    );
    int? id;
    var count = trackIds.length;
    try {
      final writable = await store.listWritable();
      for (final p in writable) {
        if (p.uid == uid) id = p.id;
      }
      final held = await store.loadPlaylist(uid);
      if (held != null) count = held.entries.length;
    } on Object {
      // keep what is known
    }
    return (id: id, count: count);
  }

  @override
  Future<({String name, List<int> addedTrackIds, int skipped})?> add(
    int playlistId,
    List<int> trackIds,
  ) async {
    final target = await _target(playlistId);
    if (target == null) return null;
    final tracks = [for (final id in trackIds) TrackId(id)];
    // The result has counts only: read what the playlist holds first to
    // name the tracks that went in.
    final before = await store.loadPlaylist(target.uid);
    final held = {
      for (final e in before?.entries ?? const <PlaylistEntryView>[])
        e.info.id.value,
    };
    final res = await store.addToPlaylists(
      tracks: tracks,
      playlistUids: [target.uid],
    );
    if (res.goneUids.isNotEmpty) return null;
    final outcome = res.outcomes.firstWhere((o) => o.uid == target.uid);
    final overlap = trackIds.any(held.contains);
    // Without overlap the store adds every track; with overlap it skips the
    // ones held. Counts come from the store, the list is derived from them.
    final candidates = overlap
        ? [
            for (final id in trackIds)
              if (!held.contains(id)) id,
          ]
        : trackIds;
    return (
      name: target.name,
      addedTrackIds: outcome.added == 0
          ? const <int>[]
          : candidates.take(outcome.added).toList(),
      skipped: outcome.skipped,
    );
  }

  @override
  Future<({String name, List<QueueEntryRef> removed})?> removeEntries(
    int playlistId,
    List<int> entryIds,
  ) async {
    final target = await _target(playlistId);
    if (target == null) return null;
    final uids = await store.resolveEntryIds(target.uid, entryIds);
    if (uids.isEmpty) {
      return (name: target.name, removed: const <QueueEntryRef>[]);
    }
    final removed = await store.removeEntriesNow(
      target.uid,
      uids.values.toList(),
    );
    return (
      name: target.name,
      removed: [
        for (final e in removed)
          QueueEntryRef(entryId: e.id, trackId: e.info.id.value),
      ],
    );
  }
}
