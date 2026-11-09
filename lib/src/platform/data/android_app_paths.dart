import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/app_paths.dart';

/// App-private storage on Android (no storage permission needed).
class AndroidAppPaths implements AppPaths {
  AndroidAppPaths._(this.dataDir, this.cacheDir, this.configDir);

  static Future<AndroidAppPaths> create() async {
    final support = await getApplicationSupportDirectory();
    final cache = await getApplicationCacheDirectory();
    return AndroidAppPaths._(
      Directory(p.join(support.path, 'data')),
      cache,
      Directory(p.join(support.path, 'config')),
    );
  }

  @override
  final Directory dataDir;
  @override
  final Directory cacheDir;
  @override
  final Directory configDir;
}
