import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../../media/domain/track_id.dart';
import '../data/favorites_repository.dart';
import '../domain/favorites.dart';

export '../domain/favorites.dart' show FavoritesController;

final _repositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(appDatabaseProvider)),
);

/// One query for the whole Favorites set; tiles select from it.
final favoriteTrackIdsProvider = StreamProvider<Set<TrackId>>(
  (ref) => ref.watch(_repositoryProvider).watchIds(),
);

/// Rebuilds only the tile whose answer changes.
final isFavoriteProvider = Provider.family<bool, TrackId>(
  (ref, id) => ref.watch(
    favoriteTrackIdsProvider.select((s) => s.value?.contains(id) ?? false),
  ),
  isAutoDispose: true,
);

final favoritesControllerProvider = Provider<FavoritesController>(
  (ref) => ref.watch(_repositoryProvider),
);
