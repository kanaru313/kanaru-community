import 'package:analyzer/file_system/file_system.dart';

import 'architecture_core.dart';

/// Parsed architecture.yaml keyed by path + modification stamp, so the
/// analysis server re-reads it only when it changes.
class ConfigCache {
  static final _byPath = <String, (int, ArchitectureConfig)>{};

  /// Config and its path for the app containing [anyFile], or null.
  static (String, ArchitectureConfig)? load(File anyFile) {
    final provider = anyFile.provider;
    final path = findConfigPath(anyFile.path, (c) => provider.getFile(c).exists);
    if (path == null) return null;
    final file = provider.getFile(path);
    final stamp = file.modificationStamp;
    final hit = _byPath[path];
    if (hit != null && hit.$1 == stamp) return (path, hit.$2);
    final cfg = ArchitectureConfig.parse(file.readAsStringSync());
    _byPath[path] = (stamp, cfg);
    return (path, cfg);
  }
}
