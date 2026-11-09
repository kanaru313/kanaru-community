import 'dart:io';

/// Folder name under the platform data/config/cache roots. Distinct from the
/// old app's `kanaru` folder so the two never share a database.
const String kanaruDirName = 'kanaru-community';

/// Where the app keeps its files. One implementation per platform.
abstract interface class AppPaths {
  /// Persistent user data (database, downloads).
  Directory get dataDir;

  /// Re-creatable data (image cache, temp files).
  Directory get cacheDir;

  /// Settings files.
  Directory get configDir;
}

extension AppPathsCreate on AppPaths {
  /// Creates the three folders when missing.
  Future<void> ensureCreated() async {
    for (final dir in [dataDir, cacheDir, configDir]) {
      await dir.create(recursive: true);
    }
  }
}
