import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../data/browse/custom_cover_index_query.dart';
import '../custom_cover_providers.dart';

/// Item keys (`AlbumKey.encode()` / `ArtistKey.encode()`) that have a custom
/// cover of a kind, one stream per kind for the whole app. Lists and grids
/// ask this (with `select`) instead of opening a stream per tile; only an item
/// in the set then resolves its file through `customCoverFileProvider`.
/// Only [CustomCoverKind.album] and [CustomCoverKind.artist] are used here.
final customCoverIndexProvider =
    StreamProvider.family<Set<String>, CustomCoverKind>(
      (ref, kind) =>
          watchCustomCoverItemKeys(ref.watch(appDatabaseProvider), kind.name),
      isAutoDispose: true,
    );
