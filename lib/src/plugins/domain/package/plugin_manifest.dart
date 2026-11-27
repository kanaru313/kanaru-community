import '../config/config_field.dart';
import 'chat_spec.dart';
import 'plugin_kind.dart';
import 'seekbar_spec.dart';
import 'translate_spec.dart';

/// A checked `plugin.json`. Built by `parseManifest`; it is a read-only view:
/// what gets stored is the original text, so fields this model does not know
/// survive for later readers.
class PluginManifest {
  const PluginManifest({
    required this.apiVersion,
    required this.kind,
    required this.name,
    required this.version,
    required this.hosts,
    required this.scripts,
    this.author = '',
    this.description = '',
    this.languages = const [],
    this.regexp,
    this.translate,
    this.chat,
    this.license = '',
    this.seekbar,
    this.config = const [],
  });

  final int apiVersion;
  final PluginKind kind;
  final String name;
  final int version;
  final String author;
  final String description;

  /// Lower-case, deduplicated host entries (plain names; `*.` wildcards for
  /// a streaming plugin only), each already passed `hostListProblem`.
  final List<String> hosts;

  /// Normalized language keys the plugin serves (`vie`, `zho`); empty means
  /// global (any language).
  final List<String> languages;

  /// Every `script` entry, key to file name (`search` to `search.js`), in
  /// manifest order. All keys are kept, not just the ones the kind needs;
  /// `kind.requiredScripts` are guaranteed present.
  final Map<String, String> scripts;

  /// `metadata.regexp`: a pattern the streaming engine uses to match links
  /// to this plugin. Checked to compile as a Dart `RegExp`, kept as text.
  ///
  /// Untrusted: a backtracking pattern can run for minutes. Never match it on
  /// the UI isolate without a bound: use QuickJS with the run interrupt, or a
  /// short-lived isolate with a timeout, and cap the input length.
  final String? regexp;

  /// The `translate` block; set exactly for a translate-family plugin.
  final TranslateSpec? translate;

  /// The `chat` block; set exactly for an `ai-chat` plugin.
  final ChatSpec? chat;

  /// `metadata.license` (1 to 64 characters); read and required for a
  /// seekbar plugin only, '' for every other kind.
  final String license;

  /// The `seekbar` block; set exactly for a seekbar plugin.
  final SeekbarSpec? seekbar;

  /// Config fields in manifest order.
  final List<ConfigField> config;

  /// Every file name `scripts` points at, each once.
  Set<String> get scriptFiles => scripts.values.toSet();

  /// Fields the user types a web address into (`format: url`, as an input or
  /// a list): the install screen tells the user the plugin will contact it.
  List<ConfigField> get userEndpointFields => [
    for (final field in config)
      if ((field is InputField && field.format == InputFormat.url) ||
          (field is ListField && field.format == ListFormat.url))
        field,
  ];
}
