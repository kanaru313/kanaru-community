import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

PlaylistSummary summary({
  String uid = 'p',
  String name = 'Mix',
  int updatedAt = 1,
  int trackCount = 0,
}) => PlaylistSummary(
  id: 0,
  uid: uid,
  name: name,
  description: '',
  isFavorites: false,
  trackCount: trackCount,
  durationMs: 0,
  createdAt: 1,
  updatedAt: updatedAt,
  autoCoverKeys: const [],
);

/// Entries named by uid; the track id is the position in [uids] + 1 unless
/// [trackOf] says otherwise. Uids in [unavailable] have a missing track.
PlaylistDetail detail(
  List<String> uids, {
  int updatedAt = 1,
  Set<String> unavailable = const {},
  Map<String, int> trackOf = const {},
}) => PlaylistDetail(
  summary: summary(updatedAt: updatedAt, trackCount: uids.length),
  entries: [
    for (var i = 0; i < uids.length; i++)
      PlaylistEntryView(
        id: 0,
        uid: uids[i],
        info: TrackInfo(
          id: TrackId(trackOf[uids[i]] ?? i + 1),
          title: 't-${uids[i]}',
          status: unavailable.contains(uids[i])
              ? TrackAvailability.missing
              : TrackAvailability.present,
          relPath: '${uids[i]}.flac',
        ),
      ),
  ],
);

List<String> uidsOf(PlaylistDetail? d) => [
  for (final e in d?.entries ?? const <PlaylistEntryView>[]) e.uid,
];

/// Polls [condition] (yielding to the event loop) until it holds.
Future<void> waitFor(bool Function() condition, {String? what}) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('timed out waiting for ${what ?? 'condition'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

class PendingCall<T> {
  PendingCall(this.args);
  final List<Object?> args;
  final result = Completer<T>();
}

/// A store whose writes finish when the test says so.
class FakeStore implements PlaylistStore {
  FakeStore(this.initial);

  PlaylistDetail? initial;

  /// What `loadPlaylist` returns.
  PlaylistDetail? loadResult;
  int loads = 0;
  Completer<void>? loadGate;
  Object? loadError;

  final stream = StreamController<PlaylistDetail?>.broadcast();
  final moves = <PendingCall<PlaylistMove>>[];
  final removals = <PendingCall<PlaylistRemoval?>>[];
  final undos = <PendingCall<int>>[];

  @override
  Stream<PlaylistDetail?> watchPlaylist(String uid) async* {
    yield initial;
    yield* stream.stream;
  }

  @override
  Future<PlaylistDetail?> loadPlaylist(String uid) async {
    loads++;
    await loadGate?.future;
    if (loadError != null) throw loadError!;
    return loadResult;
  }

  @override
  Future<PlaylistMove> moveEntry(
    String playlistUid,
    String entryUid, {
    required String? afterEntryUid,
  }) {
    final call = PendingCall<PlaylistMove>([entryUid, afterEntryUid]);
    moves.add(call);
    return call.result.future;
  }

  @override
  Future<PlaylistRemoval?> removeEntries(
    String playlistUid,
    List<String> entryUids,
  ) {
    final call = PendingCall<PlaylistRemoval?>([entryUids]);
    removals.add(call);
    return call.result.future;
  }

  @override
  Future<PlaylistRemoval?> removeDuplicates(String playlistUid) {
    final call = PendingCall<PlaylistRemoval?>(const []);
    removals.add(call);
    return call.result.future;
  }

  @override
  Future<int> undoRemoval(PlaylistRemoval removal) {
    final call = PendingCall<int>([removal]);
    undos.add(call);
    return call.result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlaylistRemoval removal(List<String> uids) =>
    PlaylistRemoval(playlistUid: 'p', entryUids: uids, removedAt: 1);
