import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/manifest_parser.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_manifest.dart';

import 'plugin_test_support.dart';

const _streamingKeys = [
  'search',
  'stream',
  'home',
  'genre',
  'album',
  'playlist',
  'artist',
  'related',
  'autocomplete',
  'resolve',
];

Map<String, String> _fixtureTexts() => {
  for (final file in Directory(
    'test/plugins/fixtures/manifests',
  ).listSync().whereType<File>())
    if (file.path.endsWith('.json'))
      file.uri.pathSegments.last: file.readAsStringSync(),
};

PluginManifest _parsed(String name, String text) {
  final result = parseManifest(text);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => fail('$name refused: $error'),
  };
}

Map<String, Object?> streamingManifestWith(Map<String, Object?> config) =>
    streamingManifest()..['config'] = config;

void main() {
  final texts = _fixtureTexts();

  test('all 44 shipped manifests are present', () {
    expect(texts, hasLength(44));
  });

  group('every shipped manifest', () {
    for (final MapEntry(key: name, value: text) in texts.entries) {
      test('$name parses with no problem and keeps its kind', () {
        final manifest = _parsed(name, text);
        // The file name is `<type>__<slug>.json`; the type is the plugin's.
        expect(manifest.kind.wire, name.split('__').first);
        expect(manifest.hosts, isNotEmpty);
        for (final key in manifest.kind.requiredScripts) {
          expect(manifest.scripts, contains(key));
        }
      });
    }
  });

  test('streaming manifests keep all 10 script keys and the regexp', () {
    final streaming = {
      for (final e in texts.entries)
        if (e.key.startsWith('streaming__')) e.key: _parsed(e.key, e.value),
    };
    expect(streaming, hasLength(13));
    for (final MapEntry(key: name, value: manifest) in streaming.entries) {
      expect(manifest.kind, PluginKind.streaming, reason: name);
      expect(manifest.scripts.keys, _streamingKeys, reason: name);
      expect(manifest.regexp, isNotNull, reason: name);
      // The model keeps the files exactly as declared.
      final raw = jsonDecode(texts[name]!) as Map<String, Object?>;
      expect(manifest.scripts, raw['script'], reason: name);
    }
  });

  test('no shipped manifest uses the secret input format', () {
    for (final MapEntry(key: name, value: text) in texts.entries) {
      expect(text, isNot(contains('"secret"')), reason: name);
    }
  });

  test('shipped shapes that older parsers never saw are accepted', () {
    final manifests = {
      for (final e in texts.entries) e.key: _parsed(e.key, e.value),
    };
    final fields = [for (final m in manifests.values) ...m.config];
    expect(fields.whereType<ListField>(), isNotEmpty);
    expect(
      fields.whereType<InputField>().any(
        (f) => f.format == InputFormat.multiline,
      ),
      isTrue,
    );
    expect(
      manifests.values.any((m) => m.languages.isEmpty),
      isTrue,
      reason: 'a plugin listing "*" is global',
    );
    expect(manifests.values.any((m) => m.hosts.length == 20), isTrue);
  });

  group('synthetic manifests', () {
    Map<String, Object?> withField(Map<String, Object?> field) =>
        streamingManifestWith({'f': field});

    test('a format secret field is refused as an unknown format', () {
      final result = parseManifest(
        jsonEncode(
          withField({'title': 'Key', 'mode': 'input', 'format': 'secret'}),
        ),
      );
      final problem =
          (result as Err<PluginManifest, List<PackageProblem>>).error.single;
      expect(problem, isA<UnknownConfigFormat>());
      expect(problem.detail, 'config.f.format');
    });

    test('a map field is parsed', () {
      final manifest = _parsed(
        'map',
        jsonEncode(
          withField({
            'title': 'Headers',
            'mode': 'map',
            'default': {'a': 'b'},
          }),
        ),
      );
      final field = manifest.config.single as MapField;
      expect(field.defaultValue, {'a': 'b'});
    });

    test('a select and an input without a format get their defaults', () {
      final manifest = _parsed(
        'defaults',
        jsonEncode(
          streamingManifestWith({
            'quality': {
              'title': 'Quality',
              'mode': 'select',
              'options': [
                {'value': 'hi', 'title': 'High'},
              ],
            },
            'user': {'title': 'User', 'mode': 'input'},
          }),
        ),
      );
      expect((manifest.config[0] as SelectField).format, SelectFormat.single);
      expect((manifest.config[1] as InputField).format, InputFormat.text);
    });
  });
}
