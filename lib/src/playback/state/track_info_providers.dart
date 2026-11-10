import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../data/track_info_rows.dart';

/// Live info of one track, for single-item screens (Now Playing, menus).
/// Lists never use this per row: they map their own list query with
/// `trackInfoFromRow`.
final trackInfoProvider = StreamProvider.family<TrackInfo?, TrackId>(
  (ref, id) => watchTrackInfo(ref.watch(appDatabaseProvider), id),
  isAutoDispose: true,
);
