import 'package:logging/logging.dart';

import '../../platform/domain/local_audio_catalog.dart';
import '../domain/local_folder_listing.dart';
import '../../platform/data/local_files/mount_points.dart' show readMountPoints;
import 'root_presence.dart';

/// Lists one music folder through the platform catalog and returns locators
/// with the scan rules applied (the catalog already applies junk and hidden
/// folders, exclusions and the Android short-file pre-filter).
class LocalFolderSource {
  LocalFolderSource(this._catalog, {this.readMounts});

  /// Mount points of the machine; the real `/proc/self/mounts` when null.
  final Set<String> Function()? readMounts;

  final LocalAudioCatalog _catalog;
  static final _log = Logger('storage.source');

  /// The check for `TagPassDeps.rootStillThere`, to be built before [list]
  /// (see [rootPresenceCheck] for the rule).
  Future<RootPresence> Function() presenceCheck(({String root}) root) =>
      rootPresenceCheck(
        catalog: _catalog,
        root: root.root,
        readMounts: readMounts ?? readMountPoints,
      );

  /// [root] is the absolute path of the folder. [excludedKeys] are folder
  /// keys relative to it. Never throws for a platform failure: the result is
  /// unreachable instead.
  Future<SourceListing> list(
    ({String root}) root, {
    Set<String> excludedKeys = const {},
    int skipShorterThanMs = 0,
  }) async {
    final AudioListing listing;
    try {
      listing = await _catalog.listAudio(
        root: root.root,
        excludedKeys: excludedKeys,
        skipShorterThanMs: skipShorterThanMs,
      );
    } on Object catch (e, st) {
      // The catalog promises not to throw; a broken implementation must not
      // be read as "the folder is empty".
      _log.severe('listing ${root.root} threw', e, st);
      return const SourceListing.unreachable(UnreachableReason.failed);
    }
    if (!listing.reachable) {
      return SourceListing.unreachable(listing.unreachableReason);
    }
    var dropped = 0;
    final files = <ListedFile>[];
    for (final f in listing.audio) {
      final locator = toLocator(root.root, f.path);
      if (locator == null) {
        dropped++;
        continue;
      }
      files.add(
        ListedFile(
          locator: locator,
          sizeBytes: f.sizeBytes,
          mtimeMs: f.mtimeMs,
          durationMs: f.durationMs,
        ),
      );
    }
    final lyrics = <String, List<ListedLyrics>>{};
    for (final l in listing.lyrics) {
      final locator = toLocator(root.root, l.path);
      if (locator == null) {
        dropped++;
        continue;
      }
      (lyrics[folderKeyOf(locator)] ??= []).add(
        ListedLyrics(
          locator: locator,
          sizeBytes: l.sizeBytes,
          mtimeMs: l.mtimeMs,
        ),
      );
    }
    final prefixes = <String>[];
    for (final dir in [...listing.unreadableDirs, ...listing.emptyDirs]) {
      final prefix = _prefixOf(root.root, dir);
      if (prefix == null) {
        dropped++;
      } else {
        prefixes.add(prefix);
      }
    }
    final unstattable = <String>{};
    for (final path in listing.unstattable) {
      final locator = toLocator(root.root, path);
      if (locator == null) {
        dropped++;
      } else {
        unstattable.add(locator);
      }
    }
    if (dropped > 0) {
      _log.warning('${root.root}: $dropped listed paths outside the root');
    }
    if (listing.undecodableNames > 0) {
      _log.warning(
        '${root.root}: ${listing.undecodableNames} names are not valid UTF-8 '
        '(not scanned), e.g. in ${listing.undecodableSampleDirs}',
      );
    }
    if (listing.skippedLinks > 0) {
      _log.info('${root.root}: ${listing.skippedLinks} folder links skipped');
    }
    return SourceListing(
      files: files,
      lyrics: lyrics,
      uncertainPrefixes: prefixes,
      unstattable: unstattable,
      excludedOut: listing.excludedOut,
      skippedOut: listing.skippedOut,
      shortOut: listing.shortOut,
      skippedLinks: listing.skippedLinks,
      undecodableNames: listing.undecodableNames,
      undecodableSampleDirs: listing.undecodableSampleDirs,
      droppedOutsideRoot: dropped,
    );
  }

  /// The locator prefix of a folder: `''` for the root itself, `rel/`
  /// otherwise; null when [dir] is outside [root].
  static String? _prefixOf(String root, String dir) {
    final normalizedRoot = root.length > 1 && root.endsWith('/')
        ? root.substring(0, root.length - 1)
        : root;
    final normalizedDir = dir.length > 1 && dir.endsWith('/')
        ? dir.substring(0, dir.length - 1)
        : dir;
    if (normalizedDir == normalizedRoot) return '';
    final locator = toLocator(normalizedRoot, normalizedDir);
    return locator == null ? null : '$locator/';
  }
}
