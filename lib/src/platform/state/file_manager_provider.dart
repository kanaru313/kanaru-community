import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/file_manager_linux.dart';
import '../data/file_manager_unsupported.dart';
import '../domain/file_manager.dart';

/// File manager of the running platform. Tests override it.
final fileManagerProvider = Provider<FileManager>((ref) {
  if (Platform.isLinux) return LinuxFileManager();
  return const UnsupportedFileManager();
});
