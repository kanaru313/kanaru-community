/// What a plugin does. The wire name is `metadata.type` in `plugin.json`.
enum PluginKind {
  lyrics('lyrics', ['search', 'lyrics']),
  translate('translate', ['translate']),
  aiTranslate('ai-translate', ['translate']),
  streaming('streaming', ['search', 'stream']);

  const PluginKind(this.wire, this.requiredScripts);

  /// The `metadata.type` text.
  final String wire;

  /// Script keys the manifest must declare for this kind, in report order.
  final List<String> requiredScripts;

  /// Whether this kind belongs to the translation family (`translate` and
  /// `ai-translate` may replace each other on update).
  bool get isTranslation => this == translate || this == aiTranslate;

  /// Only streaming plugins may list `*.` wildcard hosts.
  bool get allowsWildcardHosts => this == streaming;

  /// The kind whose wire name is [value], or null (also for non-strings).
  static PluginKind? fromWire(Object? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}
