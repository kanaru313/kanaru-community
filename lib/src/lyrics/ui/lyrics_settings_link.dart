/// Where Settings › Lyrics lives. The lyrics module cannot import the screens
/// that own the route, so the location is declared here and the route reads it.
const String lyricsSettingsLocation = '/settings/lyrics';

/// The plugin store filtered to lyrics plugins (`?kind=lyrics`), where "Thêm
/// nguồn lời trực tuyến" leads. Same reason as [lyricsSettingsLocation]: the
/// store route belongs to `screens/plugins`, which this module cannot import.
const String lyricsPluginStoreLocation = '/settings/plugins?kind=lyrics';

/// The page of the installed plugin [installId] (its settings and status),
/// where "needs setup" leads. Same reason as the two above: the route belongs
/// to `screens/plugins`.
String lyricsPluginPageLocation(String installId) =>
    '/settings/plugins/p/${Uri.encodeComponent(installId)}';
