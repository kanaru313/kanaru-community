import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';

bool _sameList<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// What a saved queue (`PlaylistKind.queue`) adds to its [PlaylistSummary]:
/// when it was saved and what it was playing from. The context fields are the
/// `PlayContextKind` name, its reference and its label at save time, null when
/// unknown (read them back through the playback model, an unknown kind name
/// means "no source line").
class SavedQueueInfo {
  const SavedQueueInfo({
    required this.savedAt,
    this.contextKind,
    this.contextRef,
    this.contextLabel,
  });

  /// Epoch milliseconds of the save, or of the last time it was played again.
  final int savedAt;
  final String? contextKind;
  final String? contextRef;
  final String? contextLabel;

  @override
  bool operator ==(Object other) =>
      other is SavedQueueInfo &&
      other.savedAt == savedAt &&
      other.contextKind == contextKind &&
      other.contextRef == contextRef &&
      other.contextLabel == contextLabel;

  @override
  int get hashCode =>
      Object.hash(savedAt, contextKind, contextRef, contextLabel);

  @override
  String toString() => 'SavedQueueInfo($savedAt, $contextKind)';
}

/// A playlist as the list page shows it.
class PlaylistSummary {
  PlaylistSummary({
    required this.id,
    required this.uid,
    required this.name,
    required this.description,
    required this.isFavorites,
    required this.trackCount,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
    required List<String> autoCoverKeys,
    this.savedQueue,
  }) : autoCoverKeys = List.unmodifiable(autoCoverKeys);

  /// Integer id the AI chat uses (`playlists.id`). Favorites is always `0`
  /// ([favoritesPlaylistId]), also before its row exists, so the real row id
  /// never leaks.
  final int id;
  final String uid;
  final String name;
  final String description;
  final bool isFavorites;

  /// Distinct songs.
  final int trackCount;
  final int durationMs;

  /// Epoch milliseconds.
  final int createdAt;
  final int updatedAt;

  /// 0..4 cover keys of the automatic cover (`pickAutoCoverKeys`).
  final List<String> autoCoverKeys;

  /// Set only for a saved queue; part of the equality so a page that watches
  /// it sees a new `savedAt` (the queue was played again).
  final SavedQueueInfo? savedQueue;

  @override
  bool operator ==(Object other) =>
      other is PlaylistSummary &&
      other.id == id &&
      other.uid == uid &&
      other.name == name &&
      other.description == description &&
      other.isFavorites == isFavorites &&
      other.trackCount == trackCount &&
      other.durationMs == durationMs &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.savedQueue == savedQueue &&
      _sameList(other.autoCoverKeys, autoCoverKeys);

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    name,
    description,
    isFavorites,
    trackCount,
    durationMs,
    createdAt,
    updatedAt,
    savedQueue,
    Object.hashAll(autoCoverKeys),
  );

  @override
  String toString() => 'PlaylistSummary($uid, $name)';
}

/// User playlists plus Favorites, from one query.
class PlaylistSummaries {
  PlaylistSummaries({
    required List<PlaylistSummary> playlists,
    required this.favorites,
  }) : playlists = List.unmodifiable(playlists);

  final List<PlaylistSummary> playlists;
  final PlaylistSummary favorites;

  @override
  bool operator ==(Object other) =>
      other is PlaylistSummaries &&
      other.favorites == favorites &&
      _sameList(other.playlists, playlists);

  @override
  int get hashCode => Object.hash(favorites, Object.hashAll(playlists));
}

/// One row of a playlist: the entry [uid] (stable across moves) and its track.
class PlaylistEntryView {
  const PlaylistEntryView({
    required this.id,
    required this.uid,
    required this.info,
  });

  /// Integer id of the entry row (`playlist_entries.id`), for the AI chat.
  final int id;
  final String uid;
  final TrackInfo info;

  /// False for a track that is missing or hidden. A `remote` track counts as
  /// available (the resolver decides at playback).
  bool get available =>
      info.status != TrackAvailability.missing &&
      info.status != TrackAvailability.hidden;

  @override
  bool operator ==(Object other) =>
      other is PlaylistEntryView &&
      other.id == id &&
      other.uid == uid &&
      other.info == info;

  @override
  int get hashCode => Object.hash(id, uid, info);
}

/// Model-facing id of Favorites: reserved, valid before the row exists.
const favoritesPlaylistId = 0;

/// Display name of the Favorites playlist (stored on its row, never
/// localized in the database).
const favoritesPlaylistName = 'Favorites';

/// A playlist the AI chat may write to (a user playlist or Favorites).
class WritablePlaylist {
  const WritablePlaylist({
    required this.id,
    required this.uid,
    required this.name,
  });

  /// `playlists.id`, or [favoritesPlaylistId] for Favorites.
  final int id;
  final String uid;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is WritablePlaylist &&
      other.id == id &&
      other.uid == uid &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, uid, name);

  @override
  String toString() => 'WritablePlaylist($id, $uid, $name)';
}

/// A playlist with its entries in playlist order (sort_key, then uid).
class PlaylistDetail {
  PlaylistDetail({
    required this.summary,
    required List<PlaylistEntryView> entries,
  }) : entries = List.unmodifiable(entries);

  final PlaylistSummary summary;
  final List<PlaylistEntryView> entries;

  /// Entries whose track is missing or hidden.
  int get unavailableCount => entries.where((e) => !e.available).length;

  /// Entries beyond the first of the same track.
  int get duplicateCount =>
      entries.length - entries.map((e) => e.info.id).toSet().length;

  /// Ids of the available entries, in playlist order (repeats kept).
  List<TrackId> get playableIds => [
    for (final e in entries)
      if (e.available) e.info.id,
  ];

  @override
  bool operator ==(Object other) =>
      other is PlaylistDetail &&
      other.summary == summary &&
      _sameList(other.entries, entries);

  @override
  int get hashCode => Object.hash(summary, Object.hashAll(entries));
}

/// What to do with a batch track a target playlist already holds.
enum DuplicatePolicy { skipExisting, moveToEnd, addAll }

/// Result of an edit: "unchanged" and "gone" are never failures.
enum PlaylistUpdate { saved, unchanged, gone }

/// Result of moving an entry.
enum PlaylistMove { moved, unchanged, gone }

/// Entries removed from a playlist and held as tombstones until committed or
/// undone.
class PlaylistRemoval {
  PlaylistRemoval({
    required this.playlistUid,
    required List<String> entryUids,
    required this.removedAt,
  }) : entryUids = List.unmodifiable(entryUids);

  final String playlistUid;
  final List<String> entryUids;
  final int removedAt;

  @override
  bool operator ==(Object other) =>
      other is PlaylistRemoval &&
      other.playlistUid == playlistUid &&
      other.removedAt == removedAt &&
      _sameList(other.entryUids, entryUids);

  @override
  int get hashCode =>
      Object.hash(playlistUid, removedAt, Object.hashAll(entryUids));
}

/// What adding a batch did to one target playlist.
class PlaylistAddOutcome {
  const PlaylistAddOutcome({
    required this.uid,
    required this.created,
    required this.added,
    required this.skipped,
    required this.movedToEnd,
  });

  final String uid;

  /// The playlist was created by this call.
  final bool created;
  final int added;
  final int skipped;
  final int movedToEnd;

  @override
  bool operator ==(Object other) =>
      other is PlaylistAddOutcome &&
      other.uid == uid &&
      other.created == created &&
      other.added == added &&
      other.skipped == skipped &&
      other.movedToEnd == movedToEnd;

  @override
  int get hashCode => Object.hash(uid, created, added, skipped, movedToEnd);
}

/// Result of adding a batch to several playlists.
class AddToPlaylistsResult {
  AddToPlaylistsResult({
    required List<PlaylistAddOutcome> outcomes,
    required List<String> goneUids,
    required this.addedTrackCount,
    required this.skippedTrackCount,
  }) : outcomes = List.unmodifiable(outcomes),
       goneUids = List.unmodifiable(goneUids);

  final List<PlaylistAddOutcome> outcomes;

  /// Targets deleted before the write.
  final List<String> goneUids;

  /// Distinct batch tracks added to at least one target.
  final int addedTrackCount;

  /// Distinct batch tracks skipped in at least one target.
  final int skippedTrackCount;

  @override
  bool operator ==(Object other) =>
      other is AddToPlaylistsResult &&
      other.addedTrackCount == addedTrackCount &&
      other.skippedTrackCount == skippedTrackCount &&
      _sameList(other.outcomes, outcomes) &&
      _sameList(other.goneUids, goneUids);

  @override
  int get hashCode => Object.hash(
    addedTrackCount,
    skippedTrackCount,
    Object.hashAll(outcomes),
    Object.hashAll(goneUids),
  );
}

/// A request to open the "add to playlist" picker for [tracks]; [sourceLabel]
/// names where they come from; [excludePlaylistUid] hides the playlist the
/// tracks are being taken from.
class AddToPlaylistRequest {
  AddToPlaylistRequest({
    required List<TrackId> tracks,
    required this.sourceLabel,
    this.excludePlaylistUid,
  }) : tracks = List.unmodifiable(tracks);

  final List<TrackId> tracks;
  final String sourceLabel;
  final String? excludePlaylistUid;

  @override
  bool operator ==(Object other) =>
      other is AddToPlaylistRequest &&
      other.sourceLabel == sourceLabel &&
      other.excludePlaylistUid == excludePlaylistUid &&
      _sameList(other.tracks, tracks);

  @override
  int get hashCode =>
      Object.hash(sourceLabel, excludePlaylistUid, Object.hashAll(tracks));
}
