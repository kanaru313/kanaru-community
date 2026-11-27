/// Where Settings › AI chat lives. The AI chat module cannot import the
/// screens that own the route, so the location is declared here and the route
/// reads it (the chat UI imports these, never `SettingsPaths`).
const String aiSettingsLocation = '/settings/ai';

/// The plugin store filtered to AI chat plugins (`?kind=aiChat`), where
/// "Thêm dịch vụ AI" leads. Same reason as [aiSettingsLocation]: the store
/// route belongs to `screens/plugins`.
const String aiPluginStoreLocation = '/settings/plugins?kind=aiChat';

/// The page of the installed plugin [installId] (its settings, API key and
/// default model). Same reason as above: the route belongs to
/// `screens/plugins`.
String aiPluginPageLocation(String installId) =>
    '/settings/plugins/p/${Uri.encodeComponent(installId)}';
