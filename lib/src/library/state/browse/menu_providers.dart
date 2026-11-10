import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/track_id.dart';
import '../../data/browse/menu_queries.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/browse/song_scope.dart';

/// Menu data loads once when a menu opens and is not live: a menu acts on
/// what it showed, and a scan must not rewrite it under the user's finger.

/// Where "Đi tới" of a track leads; null when the track is gone.
final trackLinksProvider = FutureProvider.family<TrackLinks?, TrackId>(
  (ref, id) => trackLinks(ref.watch(appDatabaseProvider), id),
  isAutoDispose: true,
);

/// Folders holding the tracks of a scope.
final foldersOfProvider = FutureProvider.family<List<FolderRef>, SongScope>(
  (ref, scope) => foldersOf(ref.watch(appDatabaseProvider), scope),
  isAutoDispose: true,
);

/// File facts for the song info page.
final songInfoProvider = FutureProvider.family<SongInfo?, TrackId>(
  (ref, id) => songInfo(ref.watch(appDatabaseProvider), id),
  isAutoDispose: true,
);
