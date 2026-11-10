import '../../../storage/domain/local_folder_listing.dart';

/// Counts of one music folder's scan, for logs and `ScanFinished`.
class ScanReport {
  ScanReport();

  /// Starts a report with the listing's own counts.
  ScanReport.fromListing(SourceListing listing)
    : unreachable = !listing.reachable,
      filteredOut = listing.filteredOut,
      skippedOut = listing.skippedOut,
      skippedLinks = listing.skippedLinks,
      undecodable = listing.undecodableNames,
      undecodableSampleDirs = listing.undecodableSampleDirs;

  /// Files handed to the tag reader.
  int read = 0;
  int added = 0;
  int updated = 0;
  int unchanged = 0;
  int missingMarked = 0;

  /// Items the user's filters removed: short files, and excluded items (files
  /// on Android, whole folders on Linux, which does not enter them).
  int filteredOut = 0;
  int skippedOut = 0;
  int skippedLinks = 0;

  /// Names that are not valid UTF-8 (not scanned), with sample folders.
  int undecodable = 0;
  List<String> undecodableSampleDirs = const [];

  /// Listed files the reader could not find (the listing was stale).
  int staleListing = 0;

  /// Existing rows left untouched after a transient read error.
  int transientSkipped = 0;

  /// Existing rows left untouched after a permanent error on a file that
  /// did not change (nothing new is known about it).
  int permanentKept = 0;

  /// Rows whose file was not found but lies under a nested mount that
  /// vanished: kept.
  int keptUnderLostMount = 0;

  /// Rows whose write failed (logged).
  int writeFailed = 0;

  /// Write transactions run (at most 64 rows each).
  int writeBatches = 0;
  bool rootSuspect = false;
  bool unreachable = false;

  /// Adds [other]'s counts (flags are or-ed).
  void merge(ScanReport other) {
    read += other.read;
    added += other.added;
    updated += other.updated;
    unchanged += other.unchanged;
    missingMarked += other.missingMarked;
    filteredOut += other.filteredOut;
    skippedOut += other.skippedOut;
    skippedLinks += other.skippedLinks;
    undecodable += other.undecodable;
    staleListing += other.staleListing;
    transientSkipped += other.transientSkipped;
    permanentKept += other.permanentKept;
    keptUnderLostMount += other.keptUnderLostMount;
    writeFailed += other.writeFailed;
    writeBatches += other.writeBatches;
    rootSuspect = rootSuspect || other.rootSuspect;
    unreachable = unreachable || other.unreachable;
  }

  @override
  String toString() =>
      'read $read, added $added, updated $updated, unchanged $unchanged, '
      'missing $missingMarked, filtered $filteredOut, skipped $skippedOut, '
      'undecodable $undecodable, stale $staleListing, '
      'transient $transientSkipped, permanentKept $permanentKept, lostMount $keptUnderLostMount, writeFailed $writeFailed, '
      'batches $writeBatches'
      '${rootSuspect ? ', ROOT SUSPECT' : ''}'
      '${unreachable ? ', UNREACHABLE' : ''}';
}
