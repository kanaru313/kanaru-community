import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/linux_app_paths.dart';

void main() {
  test('uses XDG variables when absolute', () {
    final paths = LinuxAppPaths(environment: {
      'HOME': '/home/u',
      'XDG_DATA_HOME': '/x/data',
      'XDG_CACHE_HOME': '/x/cache',
      'XDG_CONFIG_HOME': '/x/config',
    });
    expect(paths.dataDir.path, '/x/data/kanaru-community');
    expect(paths.cacheDir.path, '/x/cache/kanaru-community');
    expect(paths.configDir.path, '/x/config/kanaru-community');
  });

  test('falls back to HOME defaults, ignoring relative XDG values', () {
    final paths = LinuxAppPaths(environment: {
      'HOME': '/home/u',
      'XDG_DATA_HOME': 'relative/path',
    });
    expect(paths.dataDir.path, '/home/u/.local/share/kanaru-community');
    expect(paths.cacheDir.path, '/home/u/.cache/kanaru-community');
    expect(paths.configDir.path, '/home/u/.config/kanaru-community');
  });

  test('throws without HOME or XDG', () {
    expect(() => LinuxAppPaths(environment: {}).dataDir, throwsStateError);
  });
}
