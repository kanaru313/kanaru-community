import '../package/plugin_kind.dart';

/// Scripts whose input lines may be written to the plugin's run log.
const _loggedInputScripts = {'search', 'lyrics'};

/// Longest `configAppend` value, in characters.
const maxConfigAppendChars = 1000;

/// One run of one script of one installed plugin.
class PluginRunRequest {
  PluginRunRequest({
    required this.installId,
    required this.script,
    this.input = const {},
    required this.timeout,
    this.configAppend = const {},
    this.kinds = const {},
    bool? logInput,
  }) : logInput = logInput ?? _loggedInputScripts.contains(script);

  final String installId;

  /// A script key of the manifest (`search`, `lyrics`, `translate`, ...).
  final String script;

  /// What the script's `execute(input)` receives, as JSON.
  final Map<String, Object?> input;

  /// Base time limit of the script, before the allowance for the pause
  /// between its requests.
  final Duration timeout;

  /// Text added, for this run only, to the stored-or-default value of a
  /// declared `text` input (joined by a new line). Never saved.
  final Map<String, String> configAppend;

  /// The plugin kinds this caller may run (lyrics callers `{lyrics}`,
  /// translation the translate family). Empty means no check; a live row of
  /// another kind is `RunUnavailable(notInstalled)`: a removed id can be
  /// installed again as another kind with the same name and author.
  final Set<PluginKind> kinds;

  /// Whether the input may be written to the run log. Defaults to true for
  /// `search` and `lyrics`, false for every other script.
  final bool logInput;
}
