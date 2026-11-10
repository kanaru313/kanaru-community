import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../platform/data/local_files/mount_points.dart';
import '../../platform/domain/local_audio_catalog.dart';
import '../domain/local_folder_listing.dart';

/// How long listing a root's first entry may take before it counts as gone
/// (a dead network mount can hang).
const Duration rootPresenceTimeout = Duration(seconds: 10);

final _log = Logger('storage.presence');

bool _sameOrInside(String inner, String outer) =>
    inner == outer ||
    (outer == '/' ? inner.startsWith('/') : inner.startsWith('$outer/'));

/// Builds the check behind `TagPassDeps.rootStillThere`. Call it before the
/// listing: it remembers which mounts the folder depended on at that moment.
///
/// - Linux: the folder must exist and list at least one entry (an unmounted
///   drive leaves an empty mount-point folder behind, which `exists()` alone
///   cannot tell from a real empty folder), and every mount it sat on or
///   contained when this was built must still be in `/proc/self/mounts`. A
///   nested mount that vanished is reported in [RootPresence.lostPrefixes]
///   and the rest of the folder stays present. An unreadable mounts file
///   (an empty set: a running system always lists `/`) leaves only the
///   "lists at least one entry" rule; it is logged as a warning and flagged
///   in [RootPresence.mountsUnreadable] so the scan report shows it.
/// - Android: the catalog still reaches the folder (MediaStore listing).
Future<RootPresence> Function() rootPresenceCheck({
  required LocalAudioCatalog catalog,
  required String root,
  Set<String> Function() readMounts = readMountPoints,
  void Function(String message)? warn,
}) {
  final warning = warn ?? _log.warning;
  if (catalog.folderChoice == FolderChoice.mediaStoreSheet) {
    return () async {
      final listing = await catalog.listAudio(root: root, excludedKeys: {});
      return RootPresence(present: listing.reachable);
    };
  }
  final base = root.length > 1 && root.endsWith('/')
      ? root.substring(0, root.length - 1)
      : root;
  final beforeAll = readMounts();
  if (beforeAll.isEmpty) {
    warning(
      '$base: /proc/self/mounts is unreadable; mount protection is off '
      'for this scan',
    );
  }
  final before = beforeAll.where((m) => m != '/').toSet();
  final under = {
    for (final m in before)
      if (_sameOrInside(base, m)) m,
  };
  final nested = {
    for (final m in before)
      if (m != base && _sameOrInside(m, base)) m,
  };
  return () async {
    try {
      final hasEntry = !await Directory(base)
          .list(followLinks: false)
          .isEmpty
          .timeout(rootPresenceTimeout);
      if (!hasEntry) return const RootPresence(present: false);
    } on Object {
      // Missing, unreadable or hung: not there as far as a scan can tell.
      return const RootPresence(present: false);
    }
    final now = readMounts();
    if (now.isEmpty) {
      warning('$base: /proc/self/mounts unreadable at check time');
      return const RootPresence(present: true, mountsUnreadable: true);
    }
    if (under.any((m) => !now.contains(m))) {
      return const RootPresence(present: false);
    }
    return RootPresence(
      present: true,
      mountsUnreadable: beforeAll.isEmpty,
      lostPrefixes: [
        for (final m in nested)
          if (!now.contains(m))
            '${m.substring(base.length + (base == '/' ? 0 : 1))}/',
      ],
    );
  };
}
