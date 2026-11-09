import 'state/extension_registry.dart';

/// Extension point implemented by optional feature sets: the built-in modules
/// of the public app and, in a Pro build, the Pro features.
abstract interface class KanaruExtension {
  /// Stable unique id; also the key in `extension_schema` for extensions that
  /// own database tables.
  String get id;

  /// Adds this extension's contributions to [registry].
  void register(ExtensionRegistry registry);
}
