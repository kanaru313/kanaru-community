import 'dart:io';

/// Folder name under the platform data/config/cache roots. The database file is
/// `kanaru.db`, so a leftover old-app `library.db` in the same folder is never opened.
const String kanaruDirName = 'kanaru';

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
