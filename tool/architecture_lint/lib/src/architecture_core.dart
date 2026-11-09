// Pure Dart (no analyzer import): shared by the analyzer plugin and the CLI.
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const layers = {'domain', 'data', 'state', 'ui'};

class Violation {
  Violation(this.code, this.message);
  final String code; // module_dependency | domain_no_flutter | ...
  final String message;
}

/// Rule codes reported by the plugin and the CLI.
const ruleCodes = {
  'module_dependency',
  'domain_no_flutter',
  'screens_no_data',
  'rust_only_from_data',
  'layout_api_outside_shell',
};

class ArchitectureConfig {
  ArchitectureConfig(this.direct, this.special, {this.package = 'kanaru'});

  /// Dart package name of the app (`package:<name>/...` imports).
  final String package;

  /// module -> modules it declares as direct dependencies.
  final Map<String, Set<String>> direct;

  /// folders under lib/src that are outside the DAG (e.g. generated `rust`).
  final Set<String> special;

  late final Map<String, Set<String>> allowed = {
    for (final m in direct.keys) m: _closure(m),
  };

  /// Transitive closure: A may import everything reachable from A's edges.
  Set<String> _closure(String m) {
    final seen = <String>{};
    final stack = [...?direct[m]];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      if (seen.add(n)) stack.addAll(direct[n] ?? const {});
    }
    return seen;
  }

  /// Cycle in the declared DAG, or null.
  List<String>? findCycle() {
    for (final m in direct.keys) {
      if (allowed[m]!.contains(m)) return [m, ...allowed[m]!];
    }
    return null;
  }

  static ArchitectureConfig parse(String source) {
    final y = loadYaml(source) as YamlMap;
    final mods = y['modules'] as YamlMap;
    return ArchitectureConfig(package: y['package'] as String? ?? 'kanaru', {
      for (final e in mods.entries)
        e.key as String: {
          for (final d in (e.value as YamlList? ?? YamlList())) d as String,
        },
    }, {for (final s in (y['special'] as YamlList? ?? YamlList())) s as String});
  }
}

/// Where a file sits relative to `<pkg>/lib/src`.
class Place {
  Place(this.module, this.layer);
  final String module;
  final String? layer; // domain|data|state|ui or null
  static Place? of(String libSrcRelative) {
    final parts = p.posix.split(libSrcRelative);
    if (parts.length < 2) return null; // lib/src/foo.dart: no module
    return Place(parts[0], layers.contains(parts[1]) ? parts[1] : null);
  }
}

/// Resolve an import/export/part [uri] written in [filePath] to a path
/// relative to `<packageRoot>/lib/src`, or null when it points elsewhere.
/// [packageName] is the app package (`kanaru`).
String? resolveToLibSrc({
  required String uri,
  required String filePath,
  required String packageRoot,
  required String packageName,
}) {
  String abs;
  if (uri.startsWith('package:$packageName/')) {
    abs = p.join(packageRoot, 'lib', uri.substring('package:$packageName/'.length));
  } else if (uri.contains(':')) {
    return null;
  } else {
    abs = p.normalize(p.join(p.dirname(filePath), uri));
  }
  final srcRoot = p.join(packageRoot, 'lib', 'src');
  if (!p.isWithin(srcRoot, abs)) return null;
  return p.posix.joinAll(p.split(p.relative(abs, from: srcRoot)));
}

/// All violations for one directive. [fileRel] is the importing file relative
/// to lib/src (null when the file is outside lib/src).
List<Violation> checkDirective({
  required ArchitectureConfig config,
  required String? fileRel,
  required String uri,
  required String? targetRel, // from resolveToLibSrc
}) {
  final out = <Violation>[];
  final from = fileRel == null ? null : Place.of(fileRel);
  if (from == null) return out;

  if (from.layer == 'domain' &&
      (uri.startsWith('package:flutter/') || uri.startsWith('package:flutter_'))) {
    out.add(Violation('domain_no_flutter',
        "'domain/' must stay pure Dart; '$uri' imports Flutter."));
  }
  final to = targetRel == null ? null : Place.of(targetRel);
  if (to == null) return out;

  if (to.module == 'rust' && from.module != 'rust' && from.layer != 'data') {
    out.add(Violation('rust_only_from_data',
        "'rust/' (generated FFI) can only be imported from '<module>/data/'."));
  }
  if (from.module == 'screens' && to.module != 'screens' &&
      (to.layer == 'data' || to.module == 'database')) {
    out.add(Violation('screens_no_data',
        "'screens/' may not import data/ or database/ (found '${to.module}${to.layer == 'data' ? '/data' : ''}')."));
  }
  if (to.module != from.module && !config.special.contains(to.module)) {
    final ok = config.allowed[from.module];
    if (ok == null) {
      out.add(Violation('module_dependency',
          "Module '${from.module}' is not declared in architecture.yaml."));
    } else if (!config.direct.containsKey(to.module)) {
      out.add(Violation('module_dependency',
          "Module '${to.module}' is not declared in architecture.yaml."));
    } else if (!ok.contains(to.module)) {
      out.add(Violation('module_dependency',
          "'${from.module}' may not depend on '${to.module}' (allowed: ${ok.toList()..sort()})."));
    }
  }
  return out;
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
/// rule. Such comments are forbidden; the gate must stay un-silenceable.
bool isArchitectureIgnore(String line) {
  final m = RegExp(r'//\s*ignore(?:_for_file)?\s*:(.*)').firstMatch(line);
  if (m == null) return false;
  final body = m.group(1)!;
  return body.contains('kanaru_architecture') ||
      ruleCodes.any((c) => RegExp('\\b$c\\b').hasMatch(body));
}
