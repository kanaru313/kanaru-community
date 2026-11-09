import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/android_storage_volumes.dart';
import '../data/linux_storage_volumes.dart';
import '../domain/storage_volumes.dart';

/// Storage volumes of the running platform. Tests override it.
final storageVolumesProvider = Provider<StorageVolumes>((ref) {
  if (Platform.isAndroid) return AndroidStorageVolumes();
  if (Platform.isLinux) return LinuxStorageVolumes();
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
});
