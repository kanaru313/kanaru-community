import '../../../media/domain/track_id.dart';
import 'playlist_import.dart';
import 'playlist_models.dart';

/// Reads and writes playlists. Implemented in `data/playlists/`.
///
/// Errors: `ArgumentError` for an invalid name or description, an unknown
/// track id, an [ImportedMissing] whose source is not a live local source, or
/// a rename / delete of Favorites (nothing is written). Database failures
/// propagate. "Unchanged" and "gone" are distinct results, never one `false`.
abstract interface class PlaylistStore {
  /// User playlists plus Favorites from one query; emits again after any
  /// change to them.
  Stream<PlaylistSummaries> watchSummaries();

  /// Playlist [uid] with its entries in playlist order; null when it does not
  /// exist (also after it is deleted). Favorites is never null.
  Stream<PlaylistDetail?> watchPlaylist(String uid);

  /// Same mapping as [watchPlaylist], read once in one transaction.
  Future<PlaylistDetail?> loadPlaylist(String uid);

  /// For each playlist (Favorites included) the number of distinct [tracks]
  /// it already holds; playlists holding none are absent.
  Future<Map<String, int>> countExisting(List<TrackId> tracks);

  /// Creates a playlist holding [tracks] (repeats kept) and returns its uid.
  Future<String> createPlaylist({
    required String name,
    String description = '',
    List<TrackId> tracks = const [],
  });

  /// Creates a playlist from imported M3U [entries], in file order, creating
  /// placeholders for [ImportedMissing] entries.
  Future<ImportedPlaylist> createImportedPlaylist({
    required String name,
    required List<ImportedEntry> entries,
  });

  /// Changes the given fields. [PlaylistUpdate.unchanged] when nothing
  /// differs, [PlaylistUpdate.gone] when [uid] no longer exists.
  Future<PlaylistUpdate> updatePlaylist(
    String uid, {
    String? name,
    String? description,
  });

  /// Deletes the playlist for good; false when it was already gone.
  Future<bool> deletePlaylist(String uid);

  /// Adds [tracks] to the playlists [playlistUids] and to new playlists named
  /// [newPlaylistNames]. [policy] applies only to targets that already hold at
  /// least one batch track; every other target (and every new one) gets all
  /// tracks, repeats kept. Targets deleted meanwhile are listed in `goneUids`.
  Future<AddToPlaylistsResult> addToPlaylists({
    required List<TrackId> tracks,
    List<String> playlistUids = const [],
    List<String> newPlaylistNames = const [],
    DuplicatePolicy policy = DuplicatePolicy.skipExisting,
  });

  /// Moves entry [entryUid] to just after [afterEntryUid] (null: to the
  /// start). [PlaylistMove.unchanged] when it already sits there,
  /// [PlaylistMove.gone] when the playlist or entry no longer exists.
  Future<PlaylistMove> moveEntry(
    String playlistUid,
    String entryUid, {
    required String? afterEntryUid,
  });

  /// Removes entries as tombstones (hidden from reads); null when none of
  /// them existed. Undo with [undoRemoval], finish with [commitRemoval].
  Future<PlaylistRemoval?> removeEntries(
    String playlistUid,
    List<String> entryUids,
  );

  /// Removes every entry that repeats an earlier track; null when there is
  /// none.
  Future<PlaylistRemoval?> removeDuplicates(String playlistUid);

  /// Revives exactly the tombstones of [removal]; returns how many came back.
  Future<int> undoRemoval(PlaylistRemoval removal);

  /// Deletes the tombstones of [removal] for good.
  Future<void> commitRemoval(PlaylistRemoval removal);

  /// Copies a playlist under [name], with its custom cover when [copyCover];
  /// returns the new uid, null when the source is gone.
  Future<String?> duplicatePlaylist(
    String uid, {
    required String name,
    bool copyCover = false,
  });

  /// Adds every available track of playlist [uid] to Favorites.
  Future<AddToPlaylistsResult> addAllToFavorites(String uid);
}
