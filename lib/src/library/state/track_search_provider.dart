import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/search/track_lookup_query.dart';
import '../data/search/track_search_query.dart';
import '../domain/search/track_lookup.dart';
import '../domain/search/track_search.dart';

export '../domain/search/track_hit.dart';
export '../domain/search/track_lookup.dart';
export '../domain/search/track_search.dart';

/// The shared track search backend (AI tools, search screen).
final trackSearchProvider = Provider<TrackSearch>(
  (ref) => TrackSearchQuery(ref.watch(appDatabaseProvider)),
);

/// Resolves track ids to visible tracks.
final trackLookupProvider = Provider<TrackLookup>(
  (ref) => TrackLookupQuery(ref.watch(appDatabaseProvider)),
);
