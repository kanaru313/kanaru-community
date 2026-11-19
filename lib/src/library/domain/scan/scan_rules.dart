import '../../../storage/domain/local_folder_listing.dart';
import 'format_groups.dart';

/// The user's scan rules, read once at the start of a pass.
class ScanRules {
  ScanRules({
    this.minDurationMs = defaultMinDurationMs,
    this.minSizeBytes = 0,
    Set<String>? allowedExtensions,
    this.respectNomedia = false,
  }) : allowedExtensions = allowedExtensions ?? allGroupExtensions;

  /// Today's behaviour: 30 s minimum, no size minimum, every format.
  static final ScanRules defaults = ScanRules();

  /// Default of `library.min_duration_ms`.
  static const int defaultMinDurationMs = 30000;

  /// Files shorter than this are not kept (0 = keep all).
  final int minDurationMs;

  /// Files smaller than this are not kept (0 = keep all). A listed size of
  /// 0 or less means "unknown" (MediaStore NULL) and is never filtered.
  final int minSizeBytes;

  /// Lower-case extensions that are scanned.
  final Set<String> allowedExtensions;

  /// Linux: skip folders that hold a `.nomedia` file.
  final bool respectNomedia;

  /// Whether [file] passes the format and size rules (the duration rule runs
  /// in the listing and the tag pass, where durations are known).
  bool accepts(ListedFile file) {
    final size = file.sizeBytes;
    if (minSizeBytes > 0 && size > 0 && size < minSizeBytes) return false;
    return allowedExtensions.contains(_extensionOf(file.locator));
  }

  /// [listing] without the files [accepts] refuses; they are counted in
  /// `ruleOut`, never in `filteredOut`, so a listing emptied only by these
  /// rules still trips the empty-root guard.
  SourceListing applyTo(SourceListing listing) {
    if (!listing.reachable) return listing;
    final kept = <ListedFile>[];
    for (final f in listing.files) {
      if (accepts(f)) kept.add(f);
    }
    final dropped = listing.files.length - kept.length;
    if (dropped == 0) return listing;
    return listing.withFiles(kept, extraRuleOut: dropped);
  }
}

String _extensionOf(String locator) {
  final name = locator.substring(locator.lastIndexOf('/') + 1);
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}
