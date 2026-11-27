import '../config/config_field.dart';
import 'chat_spec.dart';
import 'host_rules.dart';
import 'json_read.dart';
import 'package_problem.dart';
import 'plugin_kind.dart';

const maxHosts = 20;
const maxScripts = 50;
const maxRegexpLength = 500;

final _scriptKey = RegExp(r'^[A-Za-z0-9_.-]{1,64}$');
final _scriptFile = RegExp(r'^[A-Za-z0-9_.-]{1,100}\.js$');

/// `metadata.hosts`: 1 to 20 strings, trimmed, lower-cased and deduplicated,
/// then checked by [hostListProblem].
List<String> readHosts(Object? value, {required PluginKind kind}) {
  if (value is! List || value.isEmpty || value.length > maxHosts) {
    invalid('metadata.hosts');
  }
  final hosts = <String>{};
  for (final item in value) {
    if (item is! String) invalid('metadata.hosts');
    hosts.add(item.trim().toLowerCase());
  }
  final problem = hostListProblem(
    hosts.toList(),
    wildcardsAllowed: kind.allowsWildcardHosts,
  );
  if (problem != null) {
    final entry = problem.entry;
    throw PackageProblemError(switch (problem.reason) {
      HostRefusal.notPublic => InvalidHost(entry),
      HostRefusal.badWildcard => InvalidWildcardHost(entry),
      HostRefusal.wildcardNotAllowed => WildcardHostNotAllowed(entry),
      HostRefusal.sharedHostingWildcard => SharedHostingWildcard(entry),
      HostRefusal.tooManyWildcards => TooManyWildcardHosts(entry),
    });
  }
  return List.unmodifiable(hosts);
}

/// `metadata.hosts` of a seekbar plugin: absent or empty, nothing else.
List<String> readNoHosts(JsonObject metadata) {
  if (!metadata.containsKey('hosts')) return const [];
  final value = metadata['hosts'];
  if (value is! List || value.isNotEmpty) invalid('metadata.hosts');
  return const [];
}

/// `config` of a seekbar plugin: absent or empty, nothing else.
void requireNoConfig(Object? value) {
  final empty =
      value == null ||
      (value is Map && value.isEmpty) ||
      (value is List && value.isEmpty);
  if (!empty) invalid('config');
}

/// The `script` object: every key (`[A-Za-z0-9_.-]+`) maps to a file name
/// (`[A-Za-z0-9_.-]+.js`); at most 50 entries; the keys [kind] requires must
/// be there. Whether the files exist is checked against the unpacked package.
Map<String, String> readScripts(Object? value, {required PluginKind kind}) {
  final object = asObject(value);
  if (object == null || object.length > maxScripts) invalid('script');
  final scripts = <String, String>{};
  for (final entry in object.entries) {
    final file = entry.value;
    if (!_scriptKey.hasMatch(entry.key) ||
        file is! String ||
        !_scriptFile.hasMatch(file)) {
      invalid('script.${entry.key}');
    }
    scripts[entry.key] = file;
  }
  for (final key in kind.requiredScripts) {
    if (!scripts.containsKey(key)) invalid('script.$key');
  }
  return Map.unmodifiable(scripts);
}

/// `metadata.regexp`: optional text of at most 500 code points that compiles
/// as a Dart `RegExp`.
String? readRegexp(Object? value) {
  if (value == null) return null;
  if (value is! String || value.runes.length > maxRegexpLength) {
    invalid('metadata.regexp');
  }
  try {
    RegExp(value);
  } on FormatException {
    invalid('metadata.regexp');
  }
  return value;
}

/// An `ai-translate` plugin must declare the fields its settings screen is
/// built around: `model` and `style` (single selects with options, or `custom`
/// for the model) and `customInstruction` (a plain text input). A custom
/// `model` must be required, so an empty list reads as needing setup.
void requireTuneFields(List<ConfigField> config) {
  ConfigField? find(String key) {
    for (final field in config) {
      if (field.key == key) return field;
    }
    return null;
  }

  for (final key in const ['model', 'style']) {
    final field = find(key);
    if (field is! SelectField ||
        field.format != SelectFormat.single ||
        (field.options.isEmpty && !field.custom)) {
      invalid('config.$key');
    }
  }
  final model = find('model') as SelectField;
  if (model.custom && !model.required) invalid('config.model.required');
  final instruction = find('customInstruction');
  if (instruction is! InputField || instruction.format != InputFormat.text) {
    invalid('config.customInstruction');
  }
}

/// An `ai-chat` plugin must declare `model` as a single select with options
/// and/or `custom: true`. It need not be `required`: the composer always
/// passes the conversation's model, the stored value only seeds new
/// conversations. `chat.keyField`, when set, must name a `required` input or
/// list field.
void requireChatFields(List<ConfigField> config, ChatSpec chat) {
  ConfigField? find(String key) {
    for (final field in config) {
      if (field.key == key) return field;
    }
    return null;
  }

  final model = find('model');
  if (model is! SelectField ||
      model.format != SelectFormat.single ||
      (model.options.isEmpty && !model.custom)) {
    invalid('config.model');
  }
  final keyField = chat.keyField;
  if (keyField == null) return;
  final key = find(keyField);
  if (key == null ||
      !key.required ||
      !(key is InputField || key is ListField)) {
    invalid('chat.keyField');
  }
}
