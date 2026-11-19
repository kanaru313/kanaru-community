/// Font families that are not the theme's text font.
abstract final class KFont {
  /// Monospace for values the user types or reads literally (separators,
  /// codes): JetBrains Mono, then Fira Mono, then the system monospace.
  static const String mono = 'JetBrains Mono';
  static const List<String> monoFallback = ['Fira Mono', 'monospace'];
}
