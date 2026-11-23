/// Where Settings › Lyrics lives. The lyrics module cannot import the screens
/// that own the route, so the location is declared here and the route reads it.
const String lyricsSettingsLocation = '/settings/lyrics';

/// The plugin store filtered to lyrics plugins (`?kind=lyrics`), where "Thêm
/// nguồn lời trực tuyến" leads. Same reason as [lyricsSettingsLocation]: the
/// store route belongs to `screens/plugins`, which this module cannot import.
const String lyricsPluginStoreLocation = '/settings/plugins?kind=lyrics';
