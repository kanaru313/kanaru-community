/// Locations of the plugin pages under Settings. The store takes an optional
/// `kind` query (`lyrics`, `translate` or `streaming`) that opens it with
/// Lọc › Loại set to that kind.
abstract final class PluginPaths {
  static const store = '/settings/plugins';
  static const repositories = '/settings/plugins/repositories';

  /// The store filtered to [kind], for the "Thêm …" rows of other pages.
  static String storeForKind(String kind) => '$store?kind=$kind';
}
