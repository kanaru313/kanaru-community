/// Locations of the plugin pages under Settings. The store takes an optional
/// `kind` query (`lyrics`, `translate`, `streaming`, `aiChat` or `seekbar`) that opens it with
/// Lọc › Loại set to that kind.
abstract final class PluginPaths {
  static const store = '/settings/plugins';
  static const repositories = '/settings/plugins/repositories';

  /// The page of the installed plugin [installId].
  static String plugin(String installId) =>
      '$store/p/${Uri.encodeComponent(installId)}';

  /// The run log of the installed plugin [installId].
  static String pluginLogs(String installId) => '${plugin(installId)}/logs';

  /// The store filtered to [kind], for the "Thêm …" rows of other pages.
  static String storeForKind(String kind) => '$store?kind=$kind';
}
