import 'dart:io';

import '../../../media/domain/cover_files.dart';

/// The `full` image of a song cover under the cache folder [root] (the
/// folder that holds `covers/`).
File songCoverFull(String root, String coverKey) =>
    File('$root/${coverRelativePath(coverKey, CoverSize.full)}');

/// The `thumb` image of a song cover under [root].
File songCoverThumb(String root, String coverKey) =>
    File('$root/${coverRelativePath(coverKey, CoverSize.thumb)}');

/// The `thumb` file that sits beside a custom cover's [full] file (same
/// layout, same key). Null when [full] is not in that layout.
File? thumbBesideFull(String coverKey, File full) {
  final suffix = coverRelativePath(coverKey, CoverSize.full);
  if (!full.path.endsWith(suffix)) return null;
  final root = full.path.substring(0, full.path.length - suffix.length);
  return File('$root${coverRelativePath(coverKey, CoverSize.thumb)}');
}
