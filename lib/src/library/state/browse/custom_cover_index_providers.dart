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

/// True when the item has a custom cover row. False while the index loads, so
/// a tile starts on its automatic cover and switches once the set arrives.
/// Watching this rebuilds the caller only when its own answer flips.
final hasCustomCoverProvider = Provider.family<bool, CustomCoverItem>(
  (ref, item) => ref.watch(
    customCoverIndexProvider(item.kind)
        .select((index) => index.value?.contains(item.itemKey) ?? false),
  ),
  isAutoDispose: true,
);
