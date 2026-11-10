import 'dart:isolate';

import '../../../media/domain/library_keys.dart';
import '../../../storage/domain/local_folder_listing.dart';
import '../../domain/scan/scan_diff.dart';
import '../../domain/scan/scan_versions.dart';

ScanDiff diffAgainstStored(
  SourceListing listing,
  List<StoredTrackRow> stored,
  bool full,
) => diffScan(
  listing,
  stored,
  tagsVersion: tagsPassVersion,
  keysVersion: libraryKeysVersion,
  full: full,
);

// Top-level so the closure captures only its arguments.
Future<ScanDiff> diffAgainstStoredInIsolate(
  SourceListing listing,
  List<StoredTrackRow> stored,
  bool full,
) => Isolate.run(() => diffAgainstStored(listing, stored, full));
