import '../../../storage/domain/local_folder_listing.dart';
import 'lrc_match.dart';

/// A stored `tracks` row of one source, as far as the diff needs it.
class StoredTrackRow {
  const StoredTrackRow({
    required this.id,
    required this.locator,
    required this.status,
    this.mtimeMs,
    this.sizeBytes,
    this.revision,
    this.tagsVersion = 0,
    this.keysVersion = 0,
    this.lrcLocator,
    this.lrcRevision,
    this.hasDetails = false,
  });

  final int id;
  final String locator;

  /// `present` or `missing` (hidden and remote rows are not read).
  final String status;
  final int? mtimeMs;
  final int? sizeBytes;
  final String? revision;
  final int tagsVersion;
  final int keysVersion;
  final String? lrcLocator;
  final String? lrcRevision;

  /// Whether a `track_details` row exists.
  final bool hasDetails;

  bool get isPresent => status == 'present';
}

/// A listed file the tag pass has to read.
class ScanRead {
  const ScanRead({required this.file, this.stored, this.lrc});

  final ListedFile file;

  /// Null for a file with no stored row.
  final StoredTrackRow? stored;
  final LrcMatch? lrc;
}

/// An unchanged file whose `.lrc` sidecar was added, changed or removed.
class LrcUpdate {
  const LrcUpdate({required this.row, required this.lrc});

  final StoredTrackRow row;

  /// Null: the sidecar is gone, clear it.
  final LrcMatch? lrc;
}

/// What a scan has to do for one music folder.
class ScanDiff {
  const ScanDiff({
    this.toRead = const [],
    this.unchanged = 0,
    this.lrcUpdates = const [],
    this.missingCandidates = const [],
    this.rootSuspect = false,
  });

  final List<ScanRead> toRead;
  final int unchanged;
  final List<LrcUpdate> lrcUpdates;

  /// Ids of stored `present` rows that are no longer listed.
  final List<int> missingCandidates;

  /// The listing is reachable but empty although rows exist, and no filter of
  /// the user explains it: no row may be marked missing.
  final bool rootSuspect;
}

bool _under(String locator, List<String> prefixes) {
  for (final p in prefixes) {
    if (locator.startsWith(p)) return true;
  }
  return false;
}

/// Compares [listing] with the stored rows of the source. Pure (the caller
/// runs it in an isolate for big sources).
///
/// A file is read when it is new, its size or mtime differ, its
/// `tags_version` or `keys_version` is below the given one, its row is
/// `missing` (listed again: revive), or [full] is set. A `present` row that
/// is not listed becomes a missing candidate unless it lies under an
/// uncertain folder or could not be stat'ed. Nothing at all is concluded
/// from an unreachable listing, and a reachable but empty one with
/// `filteredOut == 0` and stored `present` rows is [ScanDiff.rootSuspect].
ScanDiff diffScan(
  SourceListing listing,
  List<StoredTrackRow> stored, {
  required int tagsVersion,
  required int keysVersion,
  bool full = false,
}) {
  if (!listing.reachable) return const ScanDiff();
  final byLocator = {for (final r in stored) r.locator: r};
  final lyrics = LyricsIndex(listing.lyrics);
  final toRead = <ScanRead>[];
  final lrcUpdates = <LrcUpdate>[];
  final listed = <String>{};
  var unchanged = 0;
  for (final file in listing.files) {
    listed.add(file.locator);
    final row = byLocator[file.locator];
    final lrc = lyrics.match(file.locator);
    final mustRead =
        full ||
        row == null ||
        !row.isPresent ||
        row.mtimeMs != file.mtimeMs ||
        row.sizeBytes != file.sizeBytes ||
        row.tagsVersion < tagsVersion ||
        row.keysVersion < keysVersion;
    if (mustRead) {
      toRead.add(ScanRead(file: file, stored: row, lrc: lrc));
      continue;
    }
    unchanged++;
    if (row.lrcLocator != lrc?.locator || row.lrcRevision != lrc?.revision) {
      lrcUpdates.add(LrcUpdate(row: row, lrc: lrc));
    }
  }
  final present = [
    for (final r in stored)
      if (r.isPresent) r,
  ];
  if (listing.files.isEmpty && listing.filteredOut == 0 && present.isNotEmpty) {
    return ScanDiff(
      toRead: toRead,
      unchanged: unchanged,
      lrcUpdates: lrcUpdates,
      rootSuspect: true,
    );
  }
  final candidates = <int>[
    for (final r in present)
      if (!listed.contains(r.locator) &&
          !listing.unstattable.contains(r.locator) &&
          !_under(r.locator, listing.uncertainPrefixes))
        r.id,
  ];
  return ScanDiff(
    toRead: toRead,
    unchanged: unchanged,
    lrcUpdates: lrcUpdates,
    missingCandidates: candidates,
  );
}
