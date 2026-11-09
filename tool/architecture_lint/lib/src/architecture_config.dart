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
  'domain_layer',
  'screens_no_data',
  'rust_only_from_data',
  'layout_api_outside_shell',
  'package_imports_app',
};

/// Packages `domain/` may never import, whatever `domain_forbidden` says.
const _alwaysForbiddenInDomain = {'flutter', 'kanaru_ui'};

class ArchitectureConfig {
  ArchitectureConfig(
    this.direct,
    this.special, {
    this.package = 'kanaru',
    Set<String> domainForbidden = const {},
  }) : domainForbidden = {..._alwaysForbiddenInDomain, ...domainForbidden};

  /// Dart package name of the app (`package:<name>/...` imports).
  final String package;

  /// module -> modules it declares as direct dependencies.
  final Map<String, Set<String>> direct;

  /// folders under lib/src that are outside the DAG (e.g. generated `rust`).
  final Set<String> special;

  /// Packages `domain/` may not import (Flutter-dependent ones, plus
  /// `flutter` and `kanaru_ui`). Any `package:flutter_*` is forbidden too.
  final Set<String> domainForbidden;

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

  /// True when [uri] pulls Flutter (or a Flutter-dependent package) into
  /// `domain/`.
  bool isForbiddenInDomain(String uri) {
    if (uri == 'dart:ui' || uri.startsWith('dart:ui/')) return true;
    if (!uri.startsWith('package:')) return false;
    final name = uri.substring('package:'.length).split('/').first;
    return name.startsWith('flutter_') || domainForbidden.contains(name);
  }

  static ArchitectureConfig parse(String source) {
    final y = loadYaml(source) as YamlMap;
    final mods = y['modules'] as YamlMap;
    return ArchitectureConfig(
      {
        for (final e in mods.entries)
          e.key as String: {
            for (final d in (e.value as YamlList? ?? YamlList())) d as String,
          },
      },
      {for (final s in (y['special'] as YamlList? ?? YamlList())) s as String},
      package: y['package'] as String? ?? 'kanaru',
      domainForbidden: {
        for (final d in (y['domain_forbidden'] as YamlList? ?? YamlList())) d as String,
      },
    );
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
