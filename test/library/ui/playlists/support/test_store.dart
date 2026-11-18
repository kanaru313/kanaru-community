import 'dart:async';

import 'package:kanaru/src/library/domain/playlists/playlist_import.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

/// A [PlaylistStore] that forwards to a real one and can be told to fail or
/// to wait, so the dialogs' error and double-submit paths run against the
/// real repository for everything else.
class TestStore implements PlaylistStore {
  TestStore(this.inner);

  final PlaylistStore inner;

  /// Thrown by the matching call while set.
  Object? createError,
      updateError,
      deleteError,
      duplicateError,
      removeError,
      undoError,
      addAllError;

  /// While set, `removeEntries` reports that it removed nothing.
  bool removeNothing = false;

  /// While set, `createPlaylist` waits for it before it forwards.
  Completer<void>? createGate;

  /// While set, `updatePlaylist` / `removeEntries` wait for it first.
  Completer<void>? updateGate, removeGate;

  /// Run at the start of `deletePlaylist` (observes the world at that moment).
  void Function()? onDelete;

  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int duplicateCalls = 0;
  final committed = <PlaylistRemoval>[];

  @override
  Future<String> createPlaylist({
    required String name,
    String description = '',
    List<TrackId> tracks = const [],
  }) async {
    createCalls++;
    await createGate?.future;
    if (createError != null) throw createError!;
    return inner.createPlaylist(
      name: name,
      description: description,
      tracks: tracks,
    );
  }

  @override
  Future<PlaylistUpdate> updatePlaylist(
    String uid, {
    String? name,
    String? description,
  }) async {
    updateCalls++;
    await updateGate?.future;
    if (updateError != null) throw updateError!;
    return inner.updatePlaylist(uid, name: name, description: description);
  }

  @override
  Future<bool> deletePlaylist(String uid) async {
    deleteCalls++;
    onDelete?.call();
    if (deleteError != null) throw deleteError!;
    return inner.deletePlaylist(uid);
  }

  @override
  Future<String?> duplicatePlaylist(
    String uid, {
    required String name,
    bool copyCover = false,
  }) async {
    duplicateCalls++;
    if (duplicateError != null) throw duplicateError!;
    return inner.duplicatePlaylist(uid, name: name, copyCover: copyCover);
  }

  @override
  Future<PlaylistRemoval?> removeEntries(
    String playlistUid,
    List<String> entryUids,
  ) async {
    await removeGate?.future;
    if (removeError != null) throw removeError!;
    if (removeNothing) return null;
    return inner.removeEntries(playlistUid, entryUids);
  }

  @override
  Future<void> commitRemoval(PlaylistRemoval removal) {
    committed.add(removal);
    return inner.commitRemoval(removal);
  }

  @override
  Stream<PlaylistSummaries> watchSummaries() => inner.watchSummaries();

  @override
  Stream<PlaylistDetail?> watchPlaylist(String uid) => inner.watchPlaylist(uid);

  @override
  Future<PlaylistDetail?> loadPlaylist(String uid) => inner.loadPlaylist(uid);

  @override
  Future<Map<String, int>> countExisting(List<TrackId> tracks) =>
      inner.countExisting(tracks);

  @override
  Future<ImportedPlaylist> createImportedPlaylist({
    required String name,
    required List<ImportedEntry> entries,
  }) => inner.createImportedPlaylist(name: name, entries: entries);

  @override
  Future<AddToPlaylistsResult> addToPlaylists({
    required List<TrackId> tracks,
    List<String> playlistUids = const [],
    List<String> newPlaylistNames = const [],
    DuplicatePolicy policy = DuplicatePolicy.skipExisting,
  }) => inner.addToPlaylists(
    tracks: tracks,
    playlistUids: playlistUids,
    newPlaylistNames: newPlaylistNames,
    policy: policy,
  );

  @override
  Future<PlaylistMove> moveEntry(
    String playlistUid,
    String entryUid, {
    required String? afterEntryUid,
  }) => inner.moveEntry(playlistUid, entryUid, afterEntryUid: afterEntryUid);

  @override
  Future<PlaylistRemoval?> removeDuplicates(String playlistUid) =>
      inner.removeDuplicates(playlistUid);

  @override
  Future<int> undoRemoval(PlaylistRemoval removal) async {
    if (undoError != null) throw undoError!;
    return inner.undoRemoval(removal);
  }

  @override
  Future<AddToPlaylistsResult> addAllToFavorites(String uid) async {
    if (addAllError != null) throw addAllError!;
    return inner.addAllToFavorites(uid);
  }
}
