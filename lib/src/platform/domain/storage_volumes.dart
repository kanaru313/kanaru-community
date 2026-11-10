enum StorageVolumeKind { internal, sdCard, usb, home, other }

/// A mounted storage the user can keep music on.
class StorageVolume {
  const StorageVolume({required this.root, required this.kind});

  /// Absolute path without a trailing slash (except `/`).
  final String root;
  final StorageVolumeKind kind;

  @override
  bool operator ==(Object other) =>
      other is StorageVolume && other.root == root && other.kind == kind;

  @override
  int get hashCode => Object.hash(root, kind);

  @override
  String toString() => 'StorageVolume($root, ${kind.name})';
}

/// Fallback for a path no known volume holds.
const StorageVolume otherVolume = StorageVolume(
  root: '/',
  kind: StorageVolumeKind.other,
);

abstract interface class StorageVolumes {
  /// Refreshes and returns the volumes.
  Future<List<StorageVolume>> list();

  /// The volume with the longest root that contains [path], else
  /// [otherVolume]. Uses the volumes of the last [list] (or the defaults
  /// known without one).
  StorageVolume volumeOf(String path);
}

/// Longest-root match of [path] in [volumes], on path segments (`/sd2` is not
/// inside `/sd`). Else [otherVolume].
StorageVolume volumeForPath(List<StorageVolume> volumes, String path) {
  StorageVolume? best;
  for (final v in volumes) {
    final root = v.root.endsWith('/') ? v.root : '${v.root}/';
    final inside = path == v.root || path.startsWith(root);
    if (inside && (best == null || v.root.length > best.root.length)) best = v;
  }
  return best ?? otherVolume;
}
