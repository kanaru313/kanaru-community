import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../platform/domain/storage_volumes.dart';
import '../../../platform/state/storage_volumes_provider.dart';

/// The storage volumes with their list refreshed once, so a path can be
/// shown as "SD card › Music" before any folder exists. Falls back to the
/// volumes as they were when the platform call fails.
final displayVolumesProvider = FutureProvider<StorageVolumes>((ref) async {
  final volumes = ref.watch(storageVolumesProvider);
  try {
    await volumes.list();
  } on Object catch (e, st) {
    Logger('library.folders').warning('listing volumes failed', e, st);
  }
  return volumes;
});
