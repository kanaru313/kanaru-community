import 'ai_tool.dart';

/// Something that offers tools. v1 has the built-in provider only; plugin and
/// MCP providers join later behind the same interface.
abstract interface class AiToolProvider {
  List<AiTool> get tools;
}

/// The tools the assistant knows, from every provider, by name.
class AiToolRegistry {
  /// Throws [ArgumentError] when two tools share a name or a name is longer
  /// than the contract's 64 characters.
  AiToolRegistry(Iterable<AiToolProvider> providers)
    : _byName = _index(providers);

  final Map<String, AiTool> _byName;

  static Map<String, AiTool> _index(Iterable<AiToolProvider> providers) {
    final map = <String, AiTool>{};
    for (final provider in providers) {
      for (final tool in provider.tools) {
        if (tool.name.isEmpty || tool.name.length > 64) {
          throw ArgumentError.value(tool.name, 'name', 'must be 1-64 chars');
        }
        if (map.containsKey(tool.name)) {
          throw ArgumentError.value(tool.name, 'name', 'duplicate tool');
        }
        map[tool.name] = tool;
      }
    }
    return Map.unmodifiable(map);
  }

  List<AiTool> get all => _byName.values.toList(growable: false);

  AiTool? byName(String name) => _byName[name];

  /// Tools to offer for [enabled] (the group switch and, for read-only
  /// conversations, the write filter are the caller's rules).
  List<AiTool> where(bool Function(AiTool tool) enabled) => [
    for (final t in _byName.values)
      if (enabled(t)) t,
  ];
}

/// The built-in tools.
class BuiltinToolProvider implements AiToolProvider {
  const BuiltinToolProvider(this.tools);

  @override
  final List<AiTool> tools;
}
