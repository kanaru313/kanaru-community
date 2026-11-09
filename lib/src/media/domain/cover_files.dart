/// cover_key format: `<2 hex>/<32 hex>`: blake3 of the original image bytes,
/// computed only in Rust by the scanner (one writer).
final RegExp _coverKeyPattern = RegExp(r'^[0-9a-f]{2}/[0-9a-f]{32}$');

/// True when [key] is a well-formed cover key. Anything else (including
/// `../` escapes from a bad DB value) is rejected.
bool isCoverKey(String key) => _coverKeyPattern.hasMatch(key);

/// thumb: 256 px, full: 1024 px (longest side), both JPEG. `full` is used for
/// Now Playing and the Android media session art, `thumb` for tiles.
enum CoverSize { thumb, full }

/// Relative path under the app cache dir: `covers/<size>/<key>.jpg`.
/// Throws [ArgumentError] on a malformed key.
String coverRelativePath(String coverKey, CoverSize size) {
  if (!isCoverKey(coverKey)) {
    throw ArgumentError.value(coverKey, 'coverKey', 'not a cover key');
  }
  return 'covers/${size.name}/$coverKey.jpg';
}

/// Prefix of temporary files while a cover is being written.
const String coverTempPrefix = '.kanaru-tmp-';

/// Written in `<cache>/covers/` once the layout exists. A missing marker
/// (cache cleared by Android or a cleaner app) means the scanner resets
/// `cover_scan_version` to 0 for every row and rewrites covers.
const String coverLayoutMarker = '.layout-v1';
