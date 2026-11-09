/// Extension point implemented by optional feature sets (for example Pro).
/// Placeholder: the registry points are added together with the modules that
/// consume them.
abstract interface class KanaruExtension {
  String get id;

  /// Adds this extension's contributions to [registry].
  void register(ExtensionRegistry registry);
}

/// Collects contributions from every [KanaruExtension].
class ExtensionRegistry {
  ExtensionRegistry();
}
