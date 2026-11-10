import '../../media/domain/library_keys.dart';
import '../domain/library_tabs.dart';

/// Locations of the library pages. Other modules (Now Playing, queue menus)
/// navigate through these instead of building paths themselves; the library
/// registers routes that match them exactly.
abstract final class LibraryLocations {
  static const root = '/library';

  /// Root page of one list: `/library/songs` … `/library/folders`.
  static String list(LibraryTab tab) => '$root/${tab.name}';

  static String album(AlbumKey key) => '$root/albums/${key.encode()}';

  static String artist(ArtistKey key) => '$root/artists/${key.encode()}';

  static String genre(String genreKey) => '$root/genres/${encodeKey(genreKey)}';

  /// A null [languageKey] is the "unknown" group.
  static String language(String? languageKey) => languageKey == null
      ? '$root/languages/_unknown'
      : '$root/languages/${encodeKey(languageKey)}';
}
