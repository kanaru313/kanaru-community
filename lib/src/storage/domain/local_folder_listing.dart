import '../../platform/domain/local_audio_catalog.dart';

/// An audio file of a listing, addressed by its locator (the path relative to
/// the music folder, `/` separators, no leading `/`).
class ListedFile {
  const ListedFile({
    required this.locator,
    required this.sizeBytes,
    required this.mtimeMs,
    this.durationMs,
  });

  final String locator;
  final int sizeBytes;
  final int mtimeMs;

  /// Known only where the platform index has it (Android MediaStore).
  final int? durationMs;

  @override
  String toString() => 'ListedFile($locator)';
}

/// A `.lrc` sidecar of a listing.
class ListedLyrics {
  const ListedLyrics({
    required this.locator,
    required this.sizeBytes,
    required this.mtimeMs,
  });

  final String locator;
  final int sizeBytes;
  final int mtimeMs;
}

/// What one listing of a music folder found, with every path turned into a
/// locator and the platform's counts carried over for the scan report.
class SourceListing {
  const SourceListing({
    this.reachable = true,
    this.unreachableReason = UnreachableReason.missing,
    this.files = const [],
    this.lyrics = const {},
    this.uncertainPrefixes = const [],
    this.unstattable = const {},
    this.excludedOut = 0,
    this.skippedOut = 0,
    this.shortOut = 0,
    this.skippedLinks = 0,
    this.undecodableNames = 0,
    this.undecodableSampleDirs = const [],
    this.droppedOutsideRoot = 0,
  });

  /// A root that could not be read: nothing may be concluded about its rows.
  const SourceListing.unreachable([
    UnreachableReason reason = UnreachableReason.missing,
  ]) : this(reachable: false, unreachableReason: reason);

  final bool reachable;

  /// Meaningful only when [reachable] is false.
  final UnreachableReason unreachableReason;
  final List<ListedFile> files;

  /// `.lrc` sidecars by the folder key of their folder (`''` for the root).
  final Map<String, List<ListedLyrics>> lyrics;

  /// Locator prefixes whose content is unknown: unreadable and empty
  /// folders, each with a trailing `/` (`''` stands for the whole root).
  /// Stored rows under a prefix are never marked missing.
  final List<String> uncertainPrefixes;

  /// Locators the platform saw but could not stat (broken links).
  final Set<String> unstattable;

  final int excludedOut;
  final int skippedOut;
  final int shortOut;
  final int skippedLinks;
  final int undecodableNames;
  final List<String> undecodableSampleDirs;

  /// Listed paths that were not under the root and were dropped.
  final int droppedOutsideRoot;

  /// What the user's own settings removed (exclusions and the short-file
  /// filter). Only this may switch off the empty-root guard.
  int get filteredOut => excludedOut + shortOut;
}

/// The locator of [path] below [root], or null when [path] is not strictly
/// inside [root] or has an empty, `.` or `..` segment. Never throws.
String? toLocator(String root, String path) {
  final prefix = root.endsWith('/') ? root : '$root/';
  if (!path.startsWith(prefix) || path.length == prefix.length) return null;
  final locator = path.substring(prefix.length);
  for (final segment in locator.split('/')) {
    if (segment.isEmpty || segment == '.' || segment == '..') return null;
  }
  return locator;
}

/// Whether [locator] lies in the folder [key] (`''` is the whole root).
bool isUnderFolderKey(String locator, String key) =>
    key.isEmpty || locator.startsWith('$key/');

/// The folder key of [locator]: everything before the last `/`, `''` for a
/// file at the root.
String folderKeyOf(String locator) {
  final slash = locator.lastIndexOf('/');
  return slash < 0 ? '' : locator.substring(0, slash);
}

/// Whether a music folder is still there, asked after a pass saw files
/// vanish (see `LocalFolderSource.presenceCheck`).
class RootPresence {
  const RootPresence({required this.present, this.lostPrefixes = const []});

  /// The folder exists, has content and (on Linux) the mount it sat on is
  /// still mounted. False: nothing may be concluded about files under it.
  final bool present;

  /// Locator prefixes (with trailing `/`) of mounts nested inside the folder
  /// that disappeared; files under them are not known to be gone.
  final List<String> lostPrefixes;

  bool isLost(String locator) {
    for (final p in lostPrefixes) {
      if (locator.startsWith(p)) return true;
    }
    return false;
  }
}
