import 'dart:async';

import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

/// The real [PlaylistRepository] with a failure or a stall injected per
/// method. Everything else (and every method with nothing injected) is the
/// repository's own behaviour over the same database.
class GatedPlaylistStore extends PlaylistRepository {
  GatedPlaylistStore(super.db, {super.now});

  /// While non-null, [watchSummaries] emits nothing until it completes.
  Completer<void>? watchGate;

  /// While non-null, [countExisting] waits for it.
  Completer<void>? countGate;

  /// While non-null, [addToPlaylists] waits for it, then writes.
  Completer<void>? addGate;

  /// Thrown by the next [countExisting] calls, one per call.
  final List<Object> countErrors = [];

  /// How many next [addToPlaylists] calls throw [ArgumentError] before
  /// anything is written.
  int addArgumentErrors = 0;

  /// Calls of [addToPlaylists], failed ones included.
  int addCalls = 0;

  @override
  Stream<PlaylistSummaries> watchSummaries() {
    final gate = watchGate;
    if (gate == null) return super.watchSummaries();
    return Stream.fromFuture(gate.future).asyncExpand((_) {
      return super.watchSummaries();
    });
  }

  @override
  Future<Map<String, int>> countExisting(List<TrackId> tracks) async {
    if (countErrors.isNotEmpty) throw countErrors.removeAt(0);
    await countGate?.future;
    return super.countExisting(tracks);
  }

  @override
  Future<AddToPlaylistsResult> addToPlaylists({
    required List<TrackId> tracks,
    List<String> playlistUids = const [],
    List<String> newPlaylistNames = const [],
    DuplicatePolicy policy = DuplicatePolicy.skipExisting,
  }) async {
    addCalls++;
    if (addArgumentErrors > 0) {
      addArgumentErrors--;
      throw ArgumentError('track removed');
    }
    await addGate?.future;
    return super.addToPlaylists(
      tracks: tracks,
      playlistUids: playlistUids,
      newPlaylistNames: newPlaylistNames,
      policy: policy,
    );
  }
}
