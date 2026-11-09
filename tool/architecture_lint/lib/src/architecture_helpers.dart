import 'package:path/path.dart' as p;

import 'architecture_config.dart';

/// Absolute path an import/export/part [uri] points to, or null for `dart:`
/// and other packages.
String? _absoluteTarget(String uri, String filePath, String packageRoot, String packageName) {
  if (uri.startsWith('package:$packageName/')) {
    return p.join(packageRoot, 'lib', uri.substring('package:$packageName/'.length));
  }
  if (uri.contains(':')) return null;
  return p.normalize(p.join(p.dirname(filePath), uri));
}

/// Resolve [uri] written in [filePath] to a path relative to
/// `<packageRoot>/lib/src`, or null when it points elsewhere.
String? resolveToLibSrc({
  required String uri,
  required String filePath,
  required String packageRoot,
  required String packageName,
}) {
  final abs = _absoluteTarget(uri, filePath, packageRoot, packageName);
  if (abs == null) return null;
  final srcRoot = p.join(packageRoot, 'lib', 'src');
  if (!p.isWithin(srcRoot, abs)) return null;
  return p.posix.joinAll(p.split(p.relative(abs, from: srcRoot)));
}

/// File name when [uri] points at a file directly in `<packageRoot>/lib/`
/// (`kanaru.dart`, `main.dart`: the composition root), else null.
String? resolveToCompositionRoot({
  required String uri,
  required String filePath,
  required String packageRoot,
  required String packageName,
}) {
  final abs = _absoluteTarget(uri, filePath, packageRoot, packageName);
  if (abs == null) return null;
  final lib = p.join(packageRoot, 'lib');
  return p.equals(p.dirname(abs), lib) ? p.basename(abs) : null;
}

/// Locate architecture.yaml by walking up from [filePath].
String? findConfigPath(String filePath, bool Function(String) exists) {
  var dir = p.dirname(filePath);
  while (true) {
    final c = p.join(dir, 'architecture.yaml');
    if (exists(c)) return c;
    final parent = p.dirname(dir);
    if (parent == dir) return null;
    dir = parent;
  }
}

/// Width-based layout APIs (`MediaQuery.sizeOf`, `LayoutBuilder`) may only be
/// used in `packages/kanaru_ui/` and `lib/src/shell/`.
bool layoutApiAllowed(String filePath) {
  final path = p.posix.joinAll(p.split(filePath));
  return path.contains('/packages/kanaru_ui/') || path.contains('/lib/src/shell/');
}

/// True when [line] holds an `ignore` comment that silences an architecture
/// rule, or a blanket `type=lint` ignore (it silences the plugin too). Such
/// comments are forbidden; the gate must stay un-silenceable.
bool isArchitectureIgnore(String line) {
  final m = RegExp(r'//\s*ignore(?:_for_file)?\s*:(.*)').firstMatch(line);
  if (m == null) return false;
  final body = m.group(1)!;
  return body.contains('kanaru_architecture') ||
      RegExp(r'\btype\s*=\s*lint\b').hasMatch(body) ||
      ruleCodes.any((c) => RegExp('\\b$c\\b').hasMatch(body));
}
