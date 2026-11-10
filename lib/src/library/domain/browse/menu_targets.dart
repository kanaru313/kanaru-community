import '../../../media/domain/library_keys.dart';
import 'browse_items.dart';

/// An artist named on a track (or as album artist).
class ArtistRef {
  const ArtistRef(this.key, this.name);

  final ArtistKey key;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is ArtistRef && other.key == key && other.name == name;

  @override
  int get hashCode => Object.hash(key, name);
}

/// A folder of a path-based source, for "show folder" links. [folderKey] is
/// the relative path (`''` = the music folder); [name] is its last segment,
/// or the source name for the music folder itself.
class FolderRef {
  const FolderRef({
    required this.sourceId,
    required this.sourceUid,
    required this.folderKey,
    required this.name,
    required this.songCount,
  });

  final int sourceId;
  final String sourceUid;
  final String folderKey;
  final String name;

  /// Files of the request that sit directly in this folder.
  final int songCount;

  @override
  bool operator ==(Object other) =>
      other is FolderRef &&
      other.sourceId == sourceId &&
      other.sourceUid == sourceUid &&
      other.folderKey == folderKey &&
      other.name == name &&
      other.songCount == songCount;

  @override
  int get hashCode =>
      Object.hash(sourceId, sourceUid, folderKey, name, songCount);
}

/// Where "Đi tới" of a track leads.
class TrackLinks {
  const TrackLinks({
    required this.albumKey,
    required this.albumTitle,
    required this.artists,
    required this.albumArtists,
    required this.folder,
  });

  /// Null when the track has no album.
  final AlbumKey? albumKey;
  final String? albumTitle;

  /// Track artists in tag order.
  final List<ArtistRef> artists;

  /// Album artists that are not among [artists]; empty when all are.
  final List<ArtistRef> albumArtists;
  final FolderRef folder;
}

/// An artist's albums split by who owns them.
class ArtistAlbums {
  const ArtistAlbums({required this.own, required this.appears});

  /// Albums whose album artist is the artist, newest first.
  final List<AlbumSummary> own;

  /// Albums of other album artists that hold a track by the artist.
  final List<AlbumSummary> appears;

  @override
  bool operator ==(Object other) =>
      other is ArtistAlbums &&
      _same(other.own, own) &&
      _same(other.appears, appears);

  @override
  int get hashCode => Object.hash(Object.hashAll(own), Object.hashAll(appears));
}

/// File facts of the song info page (the title, artists and album come from
/// `TrackInfo`).
class SongInfo {
  const SongInfo({
    required this.format,
    required this.bitrate,
    required this.sampleRate,
    required this.bitDepth,
    required this.sizeBytes,
    required this.path,
    required this.playCount,
  });

  final String? format;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final int? sizeBytes;

  /// Absolute path of the file; null for a source without a local root.
  final String? path;
  final int playCount;
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
