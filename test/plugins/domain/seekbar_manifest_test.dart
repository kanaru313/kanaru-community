import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/package/manifest_parser.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_manifest.dart';
import 'package:kanaru/src/plugins/domain/package/seekbar_spec.dart';

import 'plugin_test_support.dart';

Map<String, Object?> seekbarManifest([
  void Function(Map<String, Object?> json)? edit,
]) {
  final json = <String, Object?>{
    'metadata': <String, Object?>{
      'apiVersion': 1,
      'type': 'seekbar',
      'name': 'Neon',
      'version': 2,
      'author': 'someone',
      'license': 'CC0-1.0',
    },
    'seekbar': <String, Object?>{
      'track': {'kind': 'flat'},
    },
  };
  edit?.call(json);
  return json;
}

Map<String, Object?> _meta(Map<String, Object?> json) =>
    json['metadata']! as Map<String, Object?>;

PluginManifest _ok(Map<String, Object?> json) =>
    switch (parseManifest(jsonEncode(json))) {
      Ok(:final value) => value,
      Err(:final error) => fail('refused: $error'),
    };

PackageProblem _problem(String text) => switch (parseManifest(text)) {
  Ok() => fail('accepted'),
  Err(:final error) => error.single,
};

void _expectInvalid(Map<String, Object?> json, String path) {
  final problem = _problem(jsonEncode(json));
  expect(problem, isA<InvalidManifest>());
  expect(problem.detail, path);
}

void main() {
  test('seekbar kind has no scripts and no code', () {
    expect(PluginKind.fromWire('seekbar'), PluginKind.seekbar);
    expect(PluginKind.seekbar.requiredScripts, isEmpty);
    expect(PluginKind.seekbar.hasCode, isFalse);
    expect(PluginKind.seekbar.allowsWildcardHosts, isFalse);
    for (final kind in PluginKind.values.where(
      (k) => k != PluginKind.seekbar,
    )) {
      expect(kind.hasCode, isTrue, reason: kind.wire);
    }
  });

  group('a seekbar manifest', () {
    test('parses with no hosts, scripts or config', () {
      final m = _ok(seekbarManifest());
      expect(m.kind, PluginKind.seekbar);
      expect(m.hosts, isEmpty);
      expect(m.scripts, isEmpty);
      expect(m.config, isEmpty);
      expect(m.license, 'CC0-1.0');
      expect(m.seekbar!.track, isA<FlatTrack>());
      expect(m.translate, isNull);
      expect(m.chat, isNull);
    });

    test('accepts empty hosts and an empty config', () {
      final m = _ok(
        seekbarManifest((j) {
          _meta(j)['hosts'] = <Object?>[];
          j['config'] = <String, Object?>{};
        }),
      );
      expect(m.hosts, isEmpty);
      expect(_ok(seekbarManifest((j) => j['config'] = [])).config, isEmpty);
    });

    final refusals = <String, (void Function(Map<String, Object?>), String)>{
      'hosts': ((j) => _meta(j)['hosts'] = ['a.example.com'], 'metadata.hosts'),
      'hosts not a list': ((j) => _meta(j)['hosts'] = 'x', 'metadata.hosts'),
      'hosts null': ((j) => _meta(j)['hosts'] = null, 'metadata.hosts'),
      'script': ((j) => j['script'] = <String, Object?>{}, 'script'),
      'script with files': ((j) => j['script'] = {'search': 'a.js'}, 'script'),
      'config': (
        (j) => j['config'] = {
          'k': {'title': 'T', 'mode': 'input', 'format': 'text'},
        },
        'config',
      ),
      'no license': ((j) => _meta(j).remove('license'), 'metadata.license'),
      'empty license': ((j) => _meta(j)['license'] = '  ', 'metadata.license'),
      'long license': (
        (j) => _meta(j)['license'] = 'x' * 65,
        'metadata.license',
      ),
      'license number': ((j) => _meta(j)['license'] = 1, 'metadata.license'),
      'no seekbar block': ((j) => j.remove('seekbar'), 'seekbar'),
      'seekbar not object': ((j) => j['seekbar'] = 'x', 'seekbar'),
      'no track': ((j) => j['seekbar'] = <String, Object?>{}, 'seekbar.track'),
      'chat block': ((j) => j['chat'] = <String, Object?>{}, 'chat'),
      'bad name': ((j) => _meta(j)['name'] = '', 'metadata.name'),
      'apiVersion': ((j) => _meta(j)['apiVersion'] = 0, 'metadata.apiVersion'),
    };
    refusals.forEach((name, c) {
      test('refuses $name', () => _expectInvalid(seekbarManifest(c.$1), c.$2));
    });

    test('a newer apiVersion is still reported as such', () {
      expect(
        _problem(
          jsonEncode(seekbarManifest((j) => _meta(j)['apiVersion'] = 2)),
        ),
        isA<NeedsNewerApp>(),
      );
    });

    test('a bad seekbar value names its full path', () {
      _expectInvalid(
        seekbarManifest(
          (j) => (j['seekbar']! as Map<String, Object?>)['thumb'] = {
            'image': 'assets/a.png',
            'size': [1, 1],
          },
        ),
        'seekbar.thumb.size',
      );
    });
  });

  group('other kinds', () {
    test('a seekbar block is refused', () {
      _expectInvalid(
        validManifest()
          ..['seekbar'] = {
            'track': {'kind': 'flat'},
          },
        'seekbar',
      );
    });

    test('still need hosts and a script', () {
      _expectInvalid(
        withMeta((m) => m['hosts'] = <Object?>[]),
        'metadata.hosts',
      );
      _expectInvalid(validManifest()..remove('script'), 'script');
    });

    test('ignore a long license entirely', () {
      final m = _ok(withMeta((m) => m['license'] = 'x' * 200));
      expect(m.license, isEmpty);
      expect(m.kind, PluginKind.lyrics);
      expect(m.seekbar, isNull);
    });
  });

  group('sample plugins of the repository', () {
    final dir = Directory('test/plugins/fixtures/seekbar/manifests');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('22 samples are there', () => expect(files, hasLength(22)));

    for (final file in files) {
      final slug = file.uri.pathSegments.last.replaceFirst('.json', '');
      if (slug == 'vinyl') continue;
      test('$slug parses strict', () {
        final m = _ok(
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
        );
        expect(m.kind, PluginKind.seekbar);
        expect(m.hosts, isEmpty);
        expect(m.license, isNotEmpty);
        expect(m.seekbar, isNotNull);
      });
    }

    test('vinyl is refused as an unsupported feature', () {
      final text = File('test/plugins/fixtures/seekbar/manifests/vinyl.json')
          .readAsStringSync();
      final problem = _problem(text);
      expect(problem, isA<UnsupportedFeature>());
      expect(problem.detail, 'seekbar.thumb.lottie');
    });
  });
}
