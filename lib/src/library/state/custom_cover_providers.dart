import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/state/database_providers.dart';
import '../../media/domain/cover_files.dart' show CoverSize;
import '../../platform/state/platform_providers.dart';
import '../data/custom_cover_store.dart';
import '../data/scan/native_cover_import.dart';
import '../domain/custom_cover_controller.dart';

export '../domain/custom_cover_controller.dart'
    show CustomCoverController, CustomCoverKind;

/// Overridden in tests so they do not need the native library.
final coverImporterProvider = Provider<CoverImporter>(
  (ref) => const RustCoverImporter(),
);

final _storeProvider = Provider<CustomCoverStore>(
  (ref) => CustomCoverStore(
    ref.watch(appDatabaseProvider),
    ref.watch(appPathsProvider).dataDir,
    importer: ref.watch(coverImporterProvider),
  ),
);

/// Choose, reset and clean up custom covers. The scheduler of the cover GC
/// calls `collectUnreferencedFiles()` after startup (background, debounced).
final customCoverControllerProvider = Provider<CustomCoverController>(
  (ref) => ref.watch(_storeProvider),
);

/// How long a custom cover stays loaded after its last tile goes away.
final customCoverKeepAliveProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 5),
);

/// Identifies one item: `itemKey` is the playlist uid, `AlbumKey.encode()` or
/// `ArtistKey.encode()`.
typedef CustomCoverItem = ({CustomCoverKind kind, String itemKey});

/// The cover key (`ab/<32 hex>`) the user chose for an item, or null when
/// there is none. Updates when the choice changes. Pass the key to
/// `coverColorsProvider` to tint the page: the store writes the colours into
/// `cover_colors` with the import (none for a near-gray image).
final customCoverKeyProvider = StreamProvider.family<String?, CustomCoverItem>(
  (ref, item) => watchCustomCoverKey(
    ref.watch(appDatabaseProvider),
    item.kind.name,
    item.itemKey,
  ),
  isAutoDispose: true,
);

/// The `full` (1024 px) image the user chose for an item, or null when there
/// is none or the file is missing (a restored backup keeps rows but not the
/// images). Updates when the choice changes. Callers combine it with the
/// automatic cover: custom file, else the source cover, else placeholder. Show
/// the file through `KCover` (it decodes at display size). For tiles use
/// [customCoverThumbProvider].
final customCoverFileProvider = StreamProvider.family<File?, CustomCoverItem>(
  (ref, item) => _watchFile(ref, item, CoverSize.full),
  isAutoDispose: true,
);

/// Like [customCoverFileProvider] but the `thumb` (256 px) image, for lists
/// and grids.
final customCoverThumbProvider = StreamProvider.family<File?, CustomCoverItem>(
  (ref, item) => _watchFile(ref, item, CoverSize.thumb),
  isAutoDispose: true,
);

Stream<File?> _watchFile(Ref ref, CustomCoverItem item, CoverSize size) {
  // Kept a few seconds after the last listener, so a tile scrolled back in
  // shows its custom cover at once instead of the source cover for a frame.
  final link = ref.keepAlive();
  Timer? release;
  final keep = ref.read(customCoverKeepAliveProvider);
  ref.onCancel(() => release = Timer(keep, link.close));
  ref.onResume(() => release?.cancel());
  ref.onDispose(() => release?.cancel());
  final store = ref.watch(_storeProvider);
  return watchCustomCoverKey(
    ref.watch(appDatabaseProvider),
    item.kind.name,
    item.itemKey,
  ).asyncMap((key) => key == null ? null : store.fileFor(key, size: size));
}
