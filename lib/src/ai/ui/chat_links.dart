/// Where the chat sends the user for settings and plugins. The same names and
/// values as the AI settings work, which replaces this file with its own
/// `ai_settings_link.dart`.
const String aiSettingsLocation = '/settings/ai';

/// The plugin store, filtered to the AI chat plugins.
const String aiPluginStoreLocation = '/settings/plugins?kind=aiChat';

/// The page of one installed plugin.
String aiPluginPageLocation(String installId) =>
    '/settings/plugins/p/${Uri.encodeComponent(installId)}';
