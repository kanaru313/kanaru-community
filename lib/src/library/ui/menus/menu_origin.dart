import '../../../media/domain/library_keys.dart';
import '../../domain/browse/song_scope.dart';

/// The page a menu was opened from. It travels page -> tile -> menu builder,
/// so a menu never offers a link back to the page it came from.
sealed class MenuOrigin {
  const MenuOrigin();

  /// A list or shelf (or anywhere that is not a page of the item itself).
  const factory MenuOrigin.list() = ListOrigin;

  /// The page of one album.
  const factory MenuOrigin.album(AlbumKey key) = AlbumOrigin;

  /// The page of one artist.
  const factory MenuOrigin.artist(ArtistKey key) = ArtistOrigin;

  /// The page of one genre ([genreKey] is the stored `genre_key`).
  const factory MenuOrigin.genre(String genreKey) = GenreOrigin;

  /// The page of one language; null = the group without a language.
  const factory MenuOrigin.language(String? code) = LanguageOrigin;

  /// One level of the Folders tab.
  const factory MenuOrigin.folder(int sourceId, String folderKey) =
      FolderOrigin;

  /// The page of the item the menu is about (the ⋮ of a detail page).
  const factory MenuOrigin.own() = OwnOrigin;

  /// The origin of the songs of a list that shows [scope].
  factory MenuOrigin.ofScope(SongScope scope) => switch (scope) {
    AllSongs() => const ListOrigin(),
    AlbumSongs(:final key) => AlbumOrigin(key),
    ArtistSongs(:final key) => ArtistOrigin(key),
    AlbumArtistSongs(:final key) => ArtistOrigin(key),
    GenreSongs(:final genreKey) => GenreOrigin(genreKey),
    LanguageSongs(:final code) => LanguageOrigin(code),
    FolderSongs(:final sourceId, :final folderKey) => FolderOrigin(
      sourceId,
      folderKey,
    ),
  };
}

class ListOrigin extends MenuOrigin {
  const ListOrigin();

  @override
  bool operator ==(Object other) => other is ListOrigin;

  @override
  int get hashCode => 1;
}

class AlbumOrigin extends MenuOrigin {
  const AlbumOrigin(this.key);
  final AlbumKey key;

  @override
  bool operator ==(Object other) => other is AlbumOrigin && other.key == key;

  @override
  int get hashCode => Object.hash('album', key);
}

class ArtistOrigin extends MenuOrigin {
  const ArtistOrigin(this.key);
  final ArtistKey key;

  @override
  bool operator ==(Object other) => other is ArtistOrigin && other.key == key;

  @override
  int get hashCode => Object.hash('artist', key);
}

class GenreOrigin extends MenuOrigin {
  const GenreOrigin(this.genreKey);
  final String genreKey;

  @override
  bool operator ==(Object other) =>
      other is GenreOrigin && other.genreKey == genreKey;

  @override
  int get hashCode => Object.hash('genre', genreKey);
}

class LanguageOrigin extends MenuOrigin {
  const LanguageOrigin(this.code);
  final String? code;

  @override
  bool operator ==(Object other) =>
      other is LanguageOrigin && other.code == code;

  @override
  int get hashCode => Object.hash('language', code);
}

class FolderOrigin extends MenuOrigin {
  const FolderOrigin(this.sourceId, this.folderKey);
  final int sourceId;
  final String folderKey;

  @override
  bool operator ==(Object other) =>
      other is FolderOrigin &&
      other.sourceId == sourceId &&
      other.folderKey == folderKey;

  @override
  int get hashCode => Object.hash('folder', sourceId, folderKey);
}

class OwnOrigin extends MenuOrigin {
  const OwnOrigin();

  @override
  bool operator ==(Object other) => other is OwnOrigin;

  @override
  int get hashCode => 2;
}
