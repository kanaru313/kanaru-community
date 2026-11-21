import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/config/config_schema_parser.dart';
import 'package:kanaru/src/plugins/domain/package/manifest_parser.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_manifest.dart';

/// A lyrics manifest that passes every rule; tests copy it and change one
/// thing.
Map<String, Object?> validManifest() => <String, Object?>{
  'metadata': <String, Object?>{
    'apiVersion': 1,
    'type': 'lyrics',
    'name': 'Demo',
    'version': 3,
    'hosts': ['music.example.com'],
    'author': 'someone',
    'description': 'Demo plugin',
  },
  'script': <String, Object?>{'search': 'search.js', 'lyrics': 'lyrics.js'},
};

/// A valid manifest with [change] applied to its `metadata`.
Map<String, Object?> withMeta(void Function(Map<String, Object?>) change) {
  final json = validManifest();
  change(json['metadata']! as Map<String, Object?>);
  return json;
}

Map<String, Object?> withConfig(Object config) =>
    validManifest()..['config'] = config;

/// A translate manifest (Gemini-like) with [change] applied.
Map<String, Object?> translateManifest([
  void Function(Map<String, Object?> json)? change,
]) {
  final json = <String, Object?>{
    'metadata': {
      'apiVersion': 1,
      'type': 'translate',
      'name': 'Gemini Translate',
      'version': 1,
      'hosts': ['generativelanguage.googleapis.com'],
    },
    'script': {'translate': 'translate.js'},
    'translate': {
      'languages': ['vi', 'en', 'zz'],
      'maxLines': 60,
      'maxChars': 6000,
      'timeoutSec': 60,
    },
    'config': {
      'apiKeys': {
        'title': 'Keys',
        'subtitle': 'one\nper line',
        'mode': 'input',
        'format': 'text',
      },
    },
  };
  change?.call(json);
  return json;
}

/// A streaming manifest with the two required scripts.
Map<String, Object?> streamingManifest({
  List<String> hosts = const ['www.youtube.com', '*.googlevideo.com'],
  Map<String, Object?>? script,
}) => <String, Object?>{
  'metadata': {
    'apiVersion': 1,
    'type': 'streaming',
    'name': 'YouTube',
    'version': 1,
    'hosts': hosts,
  },
  'script': script ?? {'search': 'search.js', 'stream': 'stream.js'},
};

/// The `config` entries an `ai-translate` manifest must declare.
Map<String, Object?> aiTuneConfig() => <String, Object?>{
  'model': {
    'title': 'Model',
    'mode': 'select',
    'options': [
      {'value': 'fast', 'title': 'Fast'},
      {'value': 'smart', 'title': 'Smart', 'subtitle': 'slower'},
    ],
  },
  'style': {
    'title': 'Style',
    'mode': 'select',
    'options': [
      {'value': 'plain', 'title': 'Plain'},
    ],
  },
  'customInstruction': {'title': 'Instruction', 'mode': 'input'},
};

/// An `ai-translate` manifest whose config [change] may edit.
Map<String, Object?> aiManifest([
  void Function(Map<String, Object?> config)? change,
  String type = 'ai-translate',
]) {
  final config = aiTuneConfig();
  change?.call(config);
  return {
    'metadata': {
      'apiVersion': 1,
      'type': type,
      'name': 'AI',
      'version': 1,
      'hosts': ['api.example.com'],
    },
    'script': {'translate': 'translate.js'},
    'translate': {
      'languages': ['vi', 'en'],
    },
    'config': config,
  };
}

/// Parses [json] (encoded to text), failing the test when it is refused.
PluginManifest parseOk(Map<String, Object?> json) {
  return switch (parseManifest(jsonEncode(json))) {
    Ok(:final value) => value,
    Err(:final error) => fail('refused: $error'),
  };
}

/// The one problem [json] is refused with; fails when it parses.
PackageProblem problemOf(Map<String, Object?> json) {
  return switch (parseManifest(jsonEncode(json))) {
    Ok() => fail('expected a problem, the manifest parsed'),
    Err(:final error) => error.single,
  };
}

/// Expects [json] to be refused as `InvalidManifest` naming [field].
void expectInvalid(Map<String, Object?> json, String field) {
  final problem = problemOf(json);
  expect(problem, isA<InvalidManifest>(), reason: '$problem');
  expect(problem.detail, field);
}

/// Parses a `config` object, failing the test when it is refused.
List<ConfigField> configOk(Map<String, Object?> config) {
  return switch (parseConfigSchema(config)) {
    Ok(:final value) => value,
    Err(:final error) => fail('refused: $error'),
  };
}

/// The problem a `config` object is refused with.
PackageProblem configProblem(Object? config) {
  return switch (parseConfigSchema(config)) {
    Ok() => fail('expected a problem, the config parsed'),
    Err(:final error) => error,
  };
}
