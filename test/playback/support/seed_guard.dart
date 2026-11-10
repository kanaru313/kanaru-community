import 'dart:io';

import 'package:path/path.dart' as p;

/// The folders the seed script may write into.
const seedAllowedRoot = '/tmp';

const _xdgVariables = ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME'];

/// Why the fixture seed must not run with [env], or null when it may. The
/// seed writes a database and settings; pointed at the user's real folders it
/// would replace their library and queue, so it needs the explicit opt-in
/// `KANARU_SEED=1` and all three XDG roots set to folders under `/tmp/`.
///
/// [resolve] turns a folder into its real path (symbolic links followed); it
/// defaults to the file system, and a folder that does not exist yet is
/// taken as written.
String? seedEnvironmentProblem(
  Map<String, String> env, {
  String Function(String path)? resolve,
}) {
  if (env['KANARU_SEED'] != '1') {
    return 'Refusing to seed: set KANARU_SEED=1 to confirm this is a '
        'throwaway run.';
  }
  final real = resolve ?? _resolve;
  for (final name in _xdgVariables) {
    final value = env[name];
    if (value == null || value.isEmpty) {
      return 'Refusing to seed: $name is not set (it must point under '
          '$seedAllowedRoot/).';
    }
    if (!p.isAbsolute(value)) {
      return 'Refusing to seed: $name must be an absolute path, got "$value".';
    }
    final path = p.normalize(value);
    if (!p.isWithin(seedAllowedRoot, path)) {
      return 'Refusing to seed: $name="$value" is not under '
          '$seedAllowedRoot/.';
    }
    final resolved = real(path);
    if (!p.isWithin(seedAllowedRoot, resolved)) {
      return 'Refusing to seed: $name="$value" resolves to "$resolved", '
          'outside $seedAllowedRoot/.';
    }
  }
  return null;
}

String _resolve(String path) {
  // The deepest existing parent decides: a link anywhere on the way counts.
  var dir = Directory(path);
  final tail = <String>[];
  while (!dir.existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) return path;
    tail.add(p.basename(dir.path));
    dir = parent;
  }
  return p.joinAll([dir.resolveSymbolicLinksSync(), ...tail.reversed]);
}
