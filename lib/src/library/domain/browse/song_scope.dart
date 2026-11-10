import '../../../media/domain/library_keys.dart';

/// Which tracks a song list shows. Value type shared by queries, state, UI
/// and menus; equal scopes share one provider instance.
sealed class SongScope {
  const SongScope();

  /// Every visible track.
  const factory SongScope.all() = AllSongs;

  /// Tracks of one album.
  const factory SongScope.album(AlbumKey key) = AlbumSongs;

  /// Tracks one artist takes part in (any `track_artists` row).
  const factory SongScope.artist(ArtistKey key) = ArtistSongs;

  /// Tracks of one genre ([genreKey] is the stored `genre_key`).
  const factory SongScope.genre(String genreKey) = GenreSongs;

  /// Tracks of one ISO 639-3 language; null = tracks without a language.
  const factory SongScope.language(String? code) = LanguageSongs;

  /// Tracks under a folder of a path-based source. [folderKey] is the
  /// relative path (`''` = the source root). [direct] = only the files in
  /// that folder, not in its subfolders.
  const factory SongScope.folder(
    int sourceId,
    String folderKey, {
    bool direct,
  }) = FolderSongs;
}

class AllSongs extends SongScope {
  const AllSongs();

  @override
  bool operator ==(Object other) => other is AllSongs;

  @override
  int get hashCode => 1;
}

class AlbumSongs extends SongScope {
  const AlbumSongs(this.key);
  final AlbumKey key;

  @override
  bool operator ==(Object other) => other is AlbumSongs && other.key == key;

  @override
  int get hashCode => Object.hash('album', key);
}

class ArtistSongs extends SongScope {
  const ArtistSongs(this.key);
  final ArtistKey key;

  @override
  bool operator ==(Object other) => other is ArtistSongs && other.key == key;

  @override
  int get hashCode => Object.hash('artist', key);
}

class GenreSongs extends SongScope {
  const GenreSongs(this.genreKey);
  final String genreKey;

  @override
  bool operator ==(Object other) =>
      other is GenreSongs && other.genreKey == genreKey;

  @override
  int get hashCode => Object.hash('genre', genreKey);
}

class LanguageSongs extends SongScope {
  const LanguageSongs(this.code);
  final String? code;

  @override
  bool operator ==(Object other) =>
      other is LanguageSongs && other.code == code;

  @override
  int get hashCode => Object.hash('language', code);
}

class FolderSongs extends SongScope {
  const FolderSongs(this.sourceId, this.folderKey, {this.direct = false});
  final int sourceId;
  final String folderKey;
  final bool direct;

  @override
  bool operator ==(Object other) =>
      other is FolderSongs &&
      other.sourceId == sourceId &&
      other.folderKey == folderKey &&
      other.direct == direct;

  @override
  int get hashCode => Object.hash('folder', sourceId, folderKey, direct);
}
