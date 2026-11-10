import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/state/database_providers.dart';
import '../../platform/state/platform_providers.dart';
import '../data/custom_cover_store.dart';
import '../domain/custom_cover_controller.dart';

export '../domain/custom_cover_controller.dart'
    show CustomCoverController, CustomCoverKind;

final _storeProvider = Provider<CustomCoverStore>(
  (ref) => CustomCoverStore(
    ref.watch(appDatabaseProvider),
    ref.watch(appPathsProvider).dataDir,
  ),
);

/// Choose, reset and clean up custom covers. The scheduler of the cover GC
/// calls `collectUnreferencedFiles()` after startup (background, debounced).
final customCoverControllerProvider = Provider<CustomCoverController>(
  (ref) => ref.watch(_storeProvider),
);

/// Identifies one item: [itemKey] is the playlist uid, `AlbumKey.encode()` or
/// `ArtistKey.encode()`.
typedef CustomCoverItem = ({CustomCoverKind kind, String itemKey});

/// The image file the user chose for an item, or null when there is none or
/// the file is missing (a restored backup keeps rows but not the images).
/// Updates when the choice changes. Callers combine it with the automatic
/// cover: custom file, else the source cover, else placeholder. Show the file
/// through `KCover` (it decodes at display size), not a plain `FileImage`.
final customCoverFileProvider = StreamProvider.family<File?, CustomCoverItem>((
  ref,
  item,
) {
  final store = ref.watch(_storeProvider);
  return watchCustomCoverKey(
    ref.watch(appDatabaseProvider),
    item.kind.name,
    item.itemKey,
  ).asyncMap((key) => key == null ? null : store.fileFor(key));
}, isAutoDispose: true);
