import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/host_rules.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';

import 'plugin_test_support.dart';

final _rlo = String.fromCharCode(0x202e);
final _zwsp = String.fromCharCode(0x200b);

void main() {
  group('config in a manifest', () {
    test('is optional', () => expect(parseOk(validManifest()).config, isEmpty));

    test('parses input, select and toggle with defaults, in order', () {
      final m = parseOk(
        withConfig({
          'name': {'title': 'Name', 'mode': 'input', 'default': 'x'},
          'limit': {
            'title': 'Limit',
            'mode': 'input',
            'format': 'number',
            'default': 5,
          },
          'region': {
            'title': 'Region',
            'mode': 'select',
            'format': 'single',
            'options': [
              {'value': 'us', 'title': 'US'},
              {'value': 'vn', 'title': 'VN'},
            ],
            'default': 'vn',
          },
          'strict': {'title': 'Strict', 'mode': 'toggle', 'default': true},
        }),
      );
      expect(m.config.map((f) => f.key), ['name', 'limit', 'region', 'strict']);
      expect((m.config[0] as InputField).format, InputFormat.text);
      expect(m.config[1].defaultValue, 5);
      expect((m.config[2] as SelectField).options.map((o) => o.value), [
        'us',
        'vn',
      ]);
      expect(m.config[2].defaultValue, 'vn');
      expect(m.config[3].defaultValue, true);
    });

    test('a config problem names the field path', () {
      expectInvalid(withConfig([]), 'config');
      expectInvalid(
        withConfig({
          'a': {'title': 't', 'mode': 'slider'},
        }),
        'config.a.mode',
      );
    });

    test('config titles are cleaned too', () {
      final m = parseOk(
        withConfig({
          'a': {
            'title': 'T${_rlo}it\u0007le',
            'mode': 'select',
            'options': [
              {'value': 'v', 'title': 'O${_zwsp}k'},
            ],
          },
        }),
      );
      final field = m.config.single as SelectField;
      expect(field.title, 'Title');
      expect(field.options.single.title, 'Ok');
    });

    test('a field with format secret refuses the package', () {
      final problem = problemOf(
        withConfig({
          'cookie': {'title': 'Cookie', 'mode': 'input', 'format': 'secret'},
        }),
      );
      expect(problem, isA<UnknownConfigFormat>());
      expect(problem.detail, 'config.cookie.format');
    });

    test('user endpoint fields are the url inputs and url lists', () {
      final m = parseOk(
        withConfig({
          'server': {'title': 'Server', 'mode': 'input', 'format': 'url'},
          'mirrors': {'title': 'Mirrors', 'mode': 'list', 'format': 'url'},
          'name': {'title': 'Name', 'mode': 'input'},
          'tags': {'title': 'Tags', 'mode': 'list'},
        }),
      );
      expect(m.userEndpointFields.map((f) => f.key), ['server', 'mirrors']);
    });
  });

  group('translate plugins', () {
    test('a translate manifest is accepted', () {
      final manifest = parseOk(translateManifest());
      expect(manifest.kind, PluginKind.translate);
      expect(manifest.scripts, {'translate': 'translate.js'});
      expect(manifest.translate!.languages, ['vi', 'en']);
      expect(manifest.translate!.maxLines, 60);
      expect(manifest.config.single.subtitle, 'one\nper line');
    });

    test('an ai-translate manifest is accepted as aiTranslate', () {
      final manifest = parseOk(aiManifest());
      expect(manifest.kind, PluginKind.aiTranslate);
      expect(manifest.kind.isTranslation, isTrue);
      expect(manifest.translate!.languages, ['vi', 'en']);
    });

    test('a lyrics manifest has no translate block', () {
      final manifest = parseOk(validManifest());
      expect(manifest.kind, PluginKind.lyrics);
      expect(manifest.translate, isNull);
    });

    test('empty or unknown-only languages are refused', () {
      for (final languages in [
        <String>[],
        ['zz'],
      ]) {
        expectInvalid(
          translateManifest(
            (j) => (j['translate']! as Map)['languages'] = languages,
          ),
          'translate.languages',
        );
      }
    });

    test('a missing translate block is refused', () {
      expectInvalid(
        translateManifest((j) => j.remove('translate')),
        'translate',
      );
    });

    test('timeoutSec 200 is clamped to 90', () {
      final manifest = parseOk(
        translateManifest((j) => (j['translate']! as Map)['timeoutSec'] = 200),
      );
      expect(manifest.translate!.timeoutSec, 90);
    });

    test('a bad maxLines is refused', () {
      expectInvalid(
        translateManifest((j) => (j['translate']! as Map)['maxLines'] = 5),
        'translate.maxLines',
      );
    });

    test('an overlong config subtitle is refused', () {
      expectInvalid(
        translateManifest(
          (j) =>
              ((j['config']! as Map)['apiKeys'] as Map)['subtitle'] = 'x' * 301,
        ),
        'config.apiKeys.subtitle',
      );
    });

    test('a lyrics type with a translate script only is refused', () {
      expectInvalid(
        translateManifest((j) => (j['metadata']! as Map)['type'] = 'lyrics'),
        'script.search',
      );
    });
  });

  group('streaming plugins', () {
    test('a streaming manifest has search and stream', () {
      final manifest = parseOk(streamingManifest());
      expect(manifest.kind, PluginKind.streaming);
      expect(manifest.scripts.keys, ['search', 'stream']);
      expect(manifest.translate, isNull);
      expect(manifest.hosts, ['www.youtube.com', '*.googlevideo.com']);
    });

    for (final type in ['lyrics', 'translate', 'ai-translate']) {
      test('a $type manifest with a wildcard host is refused', () {
        final json = switch (type) {
          'lyrics' => validManifest(),
          'translate' => translateManifest(),
          _ => aiManifest(),
        };
        (json['metadata']! as Map)['hosts'] = ['*.googlevideo.com'];
        final problem = problemOf(json);
        expect(problem, isA<WildcardHostNotAllowed>());
        expect(problem.detail, '*.googlevideo.com');
      });
    }

    test('a wildcard over a shared-hosting suffix is refused', () {
      final problem = problemOf(streamingManifest(hosts: ['*.workers.dev']));
      expect(problem, isA<SharedHostingWildcard>());
      expect(problem.detail, '*.workers.dev');
    });

    test('a wildcard over the cap is refused', () {
      final problem = problemOf(
        streamingManifest(
          hosts: [
            for (var i = 0; i <= maxHostWildcards; i++) '*.h$i.example.com',
          ],
        ),
      );
      expect(problem, isA<TooManyWildcardHosts>());
      expect(problem.detail, '*.h$maxHostWildcards.example.com');
    });

    test('wildcards up to the cap are accepted', () {
      final hosts = [
        for (var i = 0; i < maxHostWildcards; i++) '*.h$i.example.com',
      ];
      expect(parseOk(streamingManifest(hosts: hosts)).hosts, hosts);
    });

    for (final host in ['*', '*.com', 'a.*.b.com', '*foo.com', '**.a.com']) {
      test('refuses host $host as a bad wildcard', () {
        final problem = problemOf(streamingManifest(hosts: [host]));
        expect(problem, isA<InvalidWildcardHost>());
        expect(problem.detail, host);
      });
    }
  });
}
