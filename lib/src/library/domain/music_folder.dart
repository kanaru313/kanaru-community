import '../../platform/domain/storage_volumes.dart';

/// A local music folder the user added: a live local source with an enabled
/// mount.
class MusicFolder {
  const MusicFolder({
    required this.sourceId,
    required this.sourceUid,
    required this.root,
    required this.volume,
    required this.name,
  });

  final int sourceId;
  final String sourceUid;

  /// Absolute path of the folder.
  final String root;

  /// Volume that holds [root].
  final StorageVolume volume;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is MusicFolder &&
      other.sourceId == sourceId &&
      other.sourceUid == sourceUid &&
      other.root == root &&
      other.volume == volume &&
      other.name == name;

  @override
  int get hashCode => Object.hash(sourceId, sourceUid, root, volume, name);

  @override
  String toString() => 'MusicFolder($sourceId, $root)';
}
