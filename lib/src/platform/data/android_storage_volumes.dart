import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/storage_volumes.dart';

const _internalRoot = '/storage/emulated/0';
final _appDirSuffix = RegExp(r'/Android/(?:data|media|obb)/[^/]+(?:/.*)?$');
final _emulated = RegExp(r'^/storage/emulated/\d+$');
final _sdCard = RegExp(r'^/storage/[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$');

/// Android: volume roots come from the app-specific external directories
/// (`/storage/XXXX-XXXX/Android/data/<pkg>/files`) with the app suffix cut
/// off. No USB detection yet: removable volumes read as SD cards.
class AndroidStorageVolumes implements StorageVolumes {
  AndroidStorageVolumes({Future<List<Directory>?> Function()? externalDirs})
    : _externalDirs = externalDirs ?? getExternalStorageDirectories;

  final Future<List<Directory>?> Function() _externalDirs;
  List<StorageVolume> _volumes = const [
    StorageVolume(root: _internalRoot, kind: StorageVolumeKind.internal),
  ];

  /// Root of the volume that holds [appDir], or null when [appDir] is not an
  /// app-specific directory.
  static String? rootFromAppDir(String appDir) {
    final match = _appDirSuffix.firstMatch(appDir);
    if (match == null) return null;
    final root = appDir.substring(0, match.start);
    return root.isEmpty ? null : root;
  }

  /// Kind by path shape: `/storage/emulated/N` internal, `/storage/XXXX-XXXX`
  /// SD card.
  static StorageVolumeKind kindOfRoot(String root) {
    if (_emulated.hasMatch(root)) return StorageVolumeKind.internal;
    if (_sdCard.hasMatch(root)) return StorageVolumeKind.sdCard;
    return StorageVolumeKind.other;
  }

  @override
  Future<List<StorageVolume>> list() async {
    final dirs = await _externalDirs() ?? const <Directory>[];
    final roots = <String>{};
    for (final d in dirs) {
      final root = rootFromAppDir(d.path);
      if (root != null) roots.add(root);
    }
    // The primary volume is always there, even when the platform call failed.
    roots.add(_internalRoot);
    final volumes = [
      for (final r in roots) StorageVolume(root: r, kind: kindOfRoot(r)),
    ]..sort((a, b) => a.root.compareTo(b.root));
    return _volumes = volumes;
  }

  @override
  StorageVolume volumeOf(String path) => volumeForPath(_volumes, path);
}
