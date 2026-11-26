// Re-exported so chat tests import one support file.
export 'plugin_test_support.dart'
    show aiManifest, expectInvalid, parseOk, problemOf, withMeta;

/// An `ai-chat` manifest that passes every rule; [change] edits the manifest
/// before it is returned.
Map<String, Object?> chatManifest([
  void Function(Map<String, Object?> json)? change,
]) {
  final json = <String, Object?>{
    'metadata': {
      'apiVersion': 1,
      'type': 'ai-chat',
      'name': 'Chat',
      'version': 1,
      'hosts': ['api.example.com'],
    },
    'script': {'chat': 'chat.js'},
    'chat': {
      'models': [
        {
          'id': 'gemini-2.5-flash',
          'title': 'Gemini 2.5 Flash',
          'tools': true,
          'vision': true,
          'context': 1048576,
        },
      ],
      'custom': {'tools': true, 'vision': false, 'context': 65536},
      'keyField': 'apiKeys',
      'idleTimeoutSec': 60,
    },
    'config': {
      'model': {
        'title': 'Model',
        'mode': 'select',
        'custom': true,
        'options': [
          {'value': 'gemini-2.5-flash', 'title': 'Flash'},
        ],
      },
      'apiKeys': {
        'title': 'Keys',
        'mode': 'input',
        'format': 'text',
        'required': true,
      },
    },
  };
  change?.call(json);
  return json;
}

/// The `chat` block of [json].
Map<String, Object?> chatBlock(Map<String, Object?> json) =>
    json['chat']! as Map<String, Object?>;

/// The `config` of [json].
Map<String, Object?> chatConfig(Map<String, Object?> json) =>
    json['config']! as Map<String, Object?>;
