import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/storage_volumes.dart';

/// Linux: the home folder is the one known volume; everything else is
/// `other`.
class LinuxStorageVolumes implements StorageVolumes {
  LinuxStorageVolumes({Map<String, String>? environment})
    : _volumes = _home(environment ?? Platform.environment);

  final List<StorageVolume> _volumes;

  static List<StorageVolume> _home(Map<String, String> env) {
    final home = env['HOME'];
    if (home == null || !p.isAbsolute(home)) return const [];
    return [
      StorageVolume(root: p.normalize(home), kind: StorageVolumeKind.home),
    ];
  }

  @override
  Future<List<StorageVolume>> list() async => _volumes;

  @override
  StorageVolume volumeOf(String path) => volumeForPath(_volumes, path);
}
