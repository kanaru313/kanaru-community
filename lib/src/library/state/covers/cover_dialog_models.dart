import 'dart:io';

/// Ids of the rows of the cover dialog. A suggestion's id carries its album.
abstract final class CoverRowIds {
  static const automatic = 'automatic';

  /// The custom cover the item has now.
  static const current = 'current';

  /// The image picked from the device.
  static const picked = 'picked';

  static String album(String encodedAlbumKey) => 'album:$encodedAlbumKey';
}

/// How many album covers an artist suggests. A playlist suggests every album
/// it has (the dialog shows the first few and the rest on demand).
const int artistSuggestionLimit = 4;

/// The custom cover an item has, as files.
typedef CurrentCover = ({File thumb, File full});

/// An album whose cover can be used for the item.
class CoverSuggestion {
  const CoverSuggestion({
    required this.albumKey,
    required this.title,
    required this.year,
    required this.thumb,
    required this.full,
  });

  /// Encoded `AlbumKey`.
  final String albumKey;
  final String title;
  final int? year;

  /// The album's shown cover (its custom one first): [thumb] for the row,
  /// [full] is what a save reads.
  final File thumb;
  final File full;

  String get rowId => CoverRowIds.album(albumKey);
}

/// What the dialog offers for one item, read once when it opens.
class CoverDialogOptions {
  const CoverDialogOptions({
    required this.itemName,
    required this.automaticCoverKeys,
    required this.current,
    required this.suggestions,
  });

  /// Album title, artist name or playlist name ('' when the item is gone).
  final String itemName;

  /// Song cover keys of the automatic cover: none (placeholder), one for an
  /// album or artist, up to 4 for a playlist.
  final List<String> automaticCoverKeys;

  /// The item's custom cover; null when it has none or its files are gone.
  final CurrentCover? current;

  /// Empty for an album.
  final List<CoverSuggestion> suggestions;
}
