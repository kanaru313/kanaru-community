import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../data/scan/library_counts.dart';
import '../../domain/scan_status.dart';
import '../scan_providers.dart';

/// What the library holds now: visible tracks, albums and artists.
typedef LibraryOverview = ({int tracks, int albums, int artists});

/// Counts of the visible library. Read again when a scan finishes (the only
/// moment they change), never while it reports progress.
final libraryOverviewProvider = FutureProvider.autoDispose<LibraryOverview>((
  ref,
) async {
  ref.watch(
    scanStatusProvider.select(
      (status) => switch (status.value) {
        ScanFinished(:final at) => at,
        _ => null,
      },
    ),
  );
  final counts = await countsForFinished(ref.watch(appDatabaseProvider));
  return (
    tracks: counts.tracks,
    albums: counts.albums,
    artists: counts.artists,
  );
});
