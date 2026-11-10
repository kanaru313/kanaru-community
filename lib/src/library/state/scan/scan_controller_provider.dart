import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../database/state/database_providers.dart';
import '../../../platform/domain/setting.dart';
import '../../../platform/state/media_permissions_provider.dart';
import '../../../platform/state/platform_providers.dart';
import '../../../platform/state/settings_providers.dart';
import '../../../playback/state/cover_providers.dart';
import '../../../storage/state/local_folder_source_provider.dart';
import '../custom_cover_providers.dart';
import '../../data/scan/native_cover_maker.dart';
import '../../data/scan/native_tag_reader.dart';
import '../../data/scan/scan_pipeline.dart';
import '../../data/scan/track_gc_runner.dart';
import 'scan_controller.dart';
import 'scan_settings.dart';

/// Reads a boolean setting from the store at call time, falling back to the
/// default for a missing or unreadable value.
bool _flag(Ref ref, Setting<bool> setting) {
  final raw = ref.read(settingsStoreProvider).read(setting.key);
  if (raw == null) return setting.defaultValue;
  try {
    return setting.decode(raw);
  } on FormatException catch (e) {
    Logger('library.scan').warning('bad value for ${setting.key}: $e');
    return setting.defaultValue;
  }
}

/// The scanner. It watches only the database and the app paths: settings,
/// permissions, catalog and native ports are read when a pass starts, so a
/// settings change never rebuilds it in the middle of a scan. Creating it
/// starts no timer and does no I/O.
final scanControllerProvider = Provider<ScanController>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final paths = ref.watch(appPathsProvider);
  int now() => DateTime.now().millisecondsSinceEpoch;
  ScanPipelineDeps deps() => ScanPipelineDeps(
    db: db,
    source: ref.read(localFolderSourceProvider),
    permissions: ref.read(mediaPermissionsProvider),
    reader: const RustTagReader(),
    maker: const RustCoverMaker(),
    cacheDir: paths.cacheDir.path,
    skipShortTracks: _flag(ref, skipShortTracksSetting),
    now: now,
  );
  final controller = ScanController(
    runPass: (session, hooks, {required full}) =>
        runScanPass(deps(), session, hooks, full: full),
    runCoverMisses: (session, hooks, keys) =>
        runCoverMisses(deps(), session, hooks, keys),
    isSetupDone: () => _flag(ref, setupDoneSetting),
    collectGarbage: () async {
      await runTrackGc(db, now: now());
    },
    collectCoverFiles: () =>
        ref.read(customCoverControllerProvider).collectUnreferencedFiles(),
    coverMisses: ref.read(coverMissesProvider).misses,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
