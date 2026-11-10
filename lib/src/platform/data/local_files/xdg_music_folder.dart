import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('platform.files');

final _musicLine = RegExp(r'^XDG_MUSIC_DIR\s*=\s*"([^"]*)"\s*$');

/// The user's music folder to suggest, or null.
///
/// Reads `XDG_MUSIC_DIR` from [userDirsContent] (the text of `user-dirs.dirs`).
/// Only `"$HOME/..."` and absolute values are accepted, and the result is
/// normalised. A value is dropped when it is empty, relative, has a `..`
/// segment, is `$HOME` itself (how xdg-user-dirs marks a disabled folder, also
/// as `"$HOME/"`), is `/` or a parent of `$HOME`, or is not an existing
/// folder. Then `$HOME/Music` is tried. [isDirectory] is the existence check,
/// injectable for tests.
String? xdgMusicDirectory(
  Map<String, String> env,
  String? userDirsContent, {
  bool Function(String path)? isDirectory,
}) {
  final exists = isDirectory ?? (path) => Directory(path).existsSync();
  final rawHome = env['HOME'];
  if (rawHome == null || !rawHome.startsWith('/')) return null;
  final home = _normalize(rawHome);
  if (home == null || home == '/') return null;

  bool usable(String? path) =>
      path != null &&
      path != '/' &&
      path != home &&
      !home.startsWith('$path/') &&
      exists(path);

  final configured = _fromUserDirs(userDirsContent, home);
  if (usable(configured)) return configured;
  final fallback = '$home/Music';
  return usable(fallback) ? fallback : null;
}

/// Reads `user-dirs.dirs` from an absolute `$XDG_CONFIG_HOME` (else
/// `~/.config`) and returns [xdgMusicDirectory]. A missing or unreadable file
/// just means no configured value.
Future<String?> readXdgMusicDirectory(Map<String, String> env) async {
  String? content;
  final configured = env['XDG_CONFIG_HOME'];
  final home = env['HOME'];
  final base = configured != null && p.isAbsolute(configured)
      ? configured
      : (home != null && p.isAbsolute(home) ? p.join(home, '.config') : null);
  if (base != null) {
    try {
      content = await File(p.join(base, 'user-dirs.dirs')).readAsString();
    } on FileSystemException catch (error) {
      _log.fine('No readable user-dirs.dirs: $error');
    } on FormatException catch (error) {
      _log.fine('user-dirs.dirs is not valid text: $error');
    }
  }
  return xdgMusicDirectory(env, content);
}

String? _fromUserDirs(String? content, String home) {
  if (content == null) return null;
  String? value;
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#')) continue;
    final match = _musicLine.firstMatch(trimmed);
    if (match != null) value = match.group(1); // the last assignment wins
  }
  if (value == null || value.isEmpty) return null;
  if (value == r'$HOME' || value.startsWith(r'$HOME/')) {
    value = home + value.substring(r'$HOME'.length);
  }
  return value.startsWith('/') ? _normalize(value) : null;
}

/// [path] without empty and `.` segments and trailing slash; null when it has
/// a `..` segment.
String? _normalize(String path) {
  final segments = <String>[];
  for (final segment in path.split('/')) {
    if (segment == '..') return null;
    if (segment.isEmpty || segment == '.') continue;
    segments.add(segment);
  }
  return '/${segments.join('/')}';
}
