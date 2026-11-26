import '../package/plugin_kind.dart';

/// Scripts whose input lines may be written to the plugin's run log.
const _loggedInputScripts = {'search', 'lyrics'};

/// Longest `configAppend` value, in characters.
const maxConfigAppendChars = 1000;

/// Makes a run a streaming run: the script may `emit` events and read
/// streamed `fetch` bodies.
class StreamOptions {
  const StreamOptions({required this.idle, required this.onEvent});

  /// Longest wait for data in one stream read.
  final Duration idle;

  /// Receives each `emit` of the script as JSON text, in order. Called only
  /// while the run is in flight: never after the run returned its outcome. A
  /// throw is logged by type and does not end the run.
  final void Function(String eventJson) onEvent;
}

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
    this.stream,
    this.persistStorage = true,
  }) : logInput = logInput ?? _loggedInputScripts.contains(script);

  final String installId;

  /// A script key of the manifest (`search`, `lyrics`, `translate`, ...).
  final String script;

  /// What the script's `execute(input)` receives: any JSON value (null, bool,
  /// num, String, List, or Map with String keys, nested). It is JSON-encoded
  /// for the engine; a value `jsonEncode` refuses makes the run
  /// `RunFailed(internal)`.
  final Object? input;

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

  /// Non-null: a streaming run (own admission slot, 300 s wall, events to
  /// [StreamOptions.onEvent]). Null: a normal run.
  final StreamOptions? stream;

  /// False: the run starts with empty storage and what it writes is never
  /// saved (chat runs).
  final bool persistStorage;
}
