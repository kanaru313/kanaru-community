import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/app_paths.dart';

/// XDG base directories with the spec's fallbacks. Relative XDG values are
/// ignored, as the spec requires.
class LinuxAppPaths implements AppPaths {
  LinuxAppPaths({Map<String, String>? environment})
      : _env = environment ?? Platform.environment;

  final Map<String, String> _env;

  String _root(String variable, String homeRelative) {
    final value = _env[variable];
    if (value != null && p.isAbsolute(value)) return value;
    final home = _env['HOME'];
    if (home == null || !p.isAbsolute(home)) {
      throw StateError('Neither $variable nor an absolute HOME is set');
    }
    return p.join(home, homeRelative);
  }

  @override
  Directory get dataDir =>
      Directory(p.join(_root('XDG_DATA_HOME', '.local/share'), kanaruDirName));

  @override
  Directory get cacheDir =>
      Directory(p.join(_root('XDG_CACHE_HOME', '.cache'), kanaruDirName));

  @override
  Directory get configDir =>
      Directory(p.join(_root('XDG_CONFIG_HOME', '.config'), kanaruDirName));
}
