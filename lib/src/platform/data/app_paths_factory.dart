import 'dart:io';

import '../domain/app_paths.dart';
import 'android_app_paths.dart';
import 'linux_app_paths.dart';

/// Picks the [AppPaths] of the running platform and creates its folders.
Future<AppPaths> createAppPaths() async {
  final AppPaths paths;
  if (Platform.isAndroid) {
    paths = await AndroidAppPaths.create();
  } else if (Platform.isLinux) {
    paths = LinuxAppPaths();
  } else {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
  await paths.ensureCreated();
  return paths;
}
