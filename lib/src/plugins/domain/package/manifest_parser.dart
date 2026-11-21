import 'dart:convert';

import '../../../foundation/result.dart';
import '../config/config_schema_parser.dart';
import 'json_read.dart';
import 'manifest_rules.dart';
import 'package_problem.dart';
import 'plugin_kind.dart';
import 'plugin_languages.dart';
import 'plugin_manifest.dart';
import 'translate_spec.dart';

/// The newest `metadata.apiVersion` this app understands.
const supportedApiVersion = 1;

/// Parses and checks the text of a `plugin.json`. Reads only: it never
/// re-encodes, so the caller stores [text] itself and unknown fields survive.
/// A leading BOM is dropped; unknown fields are ignored.
///
/// Stops at the first problem and returns it as the single list item. Whether
/// the script files exist is checked by the caller against the unpacked
/// package.
Result<PluginManifest, List<PackageProblem>> parseManifest(String text) {
  try {
    return Ok(_read(text));
  } on PackageProblemError catch (e) {
    return Err([e.problem]);
  }
}

PluginManifest _read(String text) {
  final Object? json;
  try {
    json = jsonDecode(text.startsWith('\uFEFF') ? text.substring(1) : text);
  } on FormatException {
    invalid('plugin.json');
  }
  final root = asObject(json);
  if (root == null) invalid('plugin.json');
  final metadata = asObject(root['metadata']);
  if (metadata == null) invalid('metadata');

  final apiVersion = metadata['apiVersion'];
  if (apiVersion is! int || apiVersion < 1) invalid('metadata.apiVersion');
  if (apiVersion > supportedApiVersion) {
    throw PackageProblemError(NeedsNewerApp('$apiVersion'));
  }
  final type = metadata['type'];
  final kind = PluginKind.fromWire(type);
  if (kind == null) {
    throw PackageProblemError(UnsupportedKind(type is String ? type : ''));
  }
  final name = readText(metadata['name'], 'metadata.name', min: 1, max: 80);
  final version = metadata['version'];
  if (version is! int || version < 1 || version > 2147483647) {
    invalid('metadata.version');
  }
  final hosts = readHosts(metadata['hosts'], kind: kind);
  final author = readText(
    metadata['author'],
    'metadata.author',
    max: 80,
    optional: true,
  );
  final description = readText(
    metadata['description'],
    'metadata.description',
    max: 500,
    optional: true,
    keepNewlines: true,
  );
  final regexp = readRegexp(metadata['regexp']);
  final scripts = readScripts(root['script'], kind: kind);
  final translate = kind.isTranslation
      ? readTranslateSpec(root['translate']).spec
      : null;
  final config = readConfigSchema(root['config']);
  if (kind == PluginKind.aiTranslate) requireTuneFields(config);
  return PluginManifest(
    apiVersion: apiVersion,
    kind: kind,
    name: name,
    version: version,
    author: author,
    description: description,
    hosts: hosts,
    languages: parsePluginLanguages(metadata['languages']),
    scripts: scripts,
    regexp: regexp,
    translate: translate,
    config: config,
  );
}
