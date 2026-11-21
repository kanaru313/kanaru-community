import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/host_rules.dart';
import 'package:kanaru/src/plugins/domain/package/manifest_parser.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';

import 'plugin_test_support.dart';

final _rlo = String.fromCharCode(0x202e);
final _zwsp = String.fromCharCode(0x200b);
final _lri = String.fromCharCode(0x2066);
final _bom = String.fromCharCode(0xfeff);
final _ps = String.fromCharCode(0x2029);

void main() {
  test('parses a full manifest, ignores unknown fields and keeps every '
      'script key', () {
    final json = validManifest()
      ..['future'] = 1
      ..['script'] = {
        'search': 'search.js',
        'lyrics': 'lyrics.js',
        'extra': 'extra.js',
      };
    (json['metadata']! as Map)
      ..['extra'] = true
      ..['network'] = {'anything': 1}
      ..['changelog'] = 'ignored'
      ..['regexp'] = r'^https://music\.example\.com/';
    final manifest = parseOk(json);
    expect(manifest.apiVersion, 1);
    expect(manifest.kind, PluginKind.lyrics);
    expect(manifest.name, 'Demo');
    expect(manifest.version, 3);
    expect(manifest.author, 'someone');
    expect(manifest.hosts, ['music.example.com']);
    expect(manifest.scripts.keys, ['search', 'lyrics', 'extra']);
    expect(manifest.scriptFiles, {'search.js', 'lyrics.js', 'extra.js'});
    expect(manifest.regexp, r'^https://music\.example\.com/');
    expect(manifest.translate, isNull);
    expect(manifest.config, isEmpty);
  });

  test('accepts a UTF-8 byte order mark', () {
    final text = '$_bom${jsonEncode(validManifest())}';
    expect(switch (parseManifest(text)) {
      Ok(:final value) => value.name,
      Err() => null,
    }, 'Demo');
  });

  group('plugin.json shape', () {
    for (final text in ['{nope', '', '[]', '"x"', 'null', '5']) {
      test('refuses "$text"', () {
        final result = parseManifest(text);
        expect(result, isA<Err<Object?, List<PackageProblem>>>());
        final problem = (result as Err<Object?, List<PackageProblem>>).error;
        expect(problem.single, isA<InvalidManifest>());
        expect(problem.single.detail, 'plugin.json');
      });
    }

    test('refuses missing metadata and script objects', () {
      expectInvalid({'script': <String, Object?>{}}, 'metadata');
      expectInvalid(validManifest()..remove('script'), 'script');
      expectInvalid(validManifest()..['script'] = 'search.js', 'script');
    });
  });

  group('apiVersion and type', () {
    test('apiVersion 2 needs a newer app', () {
      final problem = problemOf(withMeta((m) => m['apiVersion'] = 2));
      expect(problem, isA<NeedsNewerApp>());
      expect(problem.detail, '2');
    });

    for (final bad in [0, -1, '1', 1.0, null, true]) {
      test('apiVersion $bad is invalid', () {
        expectInvalid(
          withMeta((m) => m['apiVersion'] = bad),
          'metadata.apiVersion',
        );
      });
    }

    for (final type in ['lyrics', 'translate', 'ai-translate', 'streaming']) {
      test('type $type is a kind', () {
        expect(PluginKind.fromWire(type)!.wire, type);
      });
    }

    for (final type in ['theme', 'source', 'chat', '', null, 5]) {
      test('type $type is an unsupported kind', () {
        final problem = problemOf(withMeta((m) => m['type'] = type));
        expect(problem, isA<UnsupportedKind>());
        expect(problem.detail, type is String ? type : '');
      });
    }

    test('an unsupported kind does not echo a non-string type', () {
      final problem = problemOf(withMeta((m) => m['type'] = {'a': 'x' * 1000}));
      expect(problem, isA<UnsupportedKind>());
      expect(problem.detail, '');
    });

    test('apiVersion is checked before the type', () {
      final problem = problemOf(
        withMeta((m) {
          m['apiVersion'] = 2;
          m['type'] = 'theme';
        }),
      );
      expect(problem, isA<NeedsNewerApp>());
    });
  });

  group('languages', () {
    test('are normalized keys', () {
      final m = parseOk(withMeta((m) => m['languages'] = ['vi', 'zh-Hant']));
      expect(m.languages, ['vie', 'zho']);
    });

    test('missing means global', () {
      expect(parseOk(validManifest()).languages, isEmpty);
    });

    for (final bad in [
      5,
      <String, Object?>{},
      'vi',
      [1, null],
    ]) {
      test('a bad value $bad keeps the package, global', () {
        expect(
          parseOk(withMeta((m) => m['languages'] = bad)).languages,
          isEmpty,
        );
      });
    }
  });

  group('name, version, author, description', () {
    test('name is trimmed and stripped of control characters', () {
      final m = parseOk(withMeta((m) => m['name'] = '  A\u0007B\n '));
      expect(m.name, 'AB');
    });

    for (final bad in ['', '   ', '\u0001', 'x' * 81, 5, null]) {
      test(
        'refuses name ${bad is String && bad.length > 10 ? 'x*81' : bad}',
        () {
          expectInvalid(withMeta((m) => m['name'] = bad), 'metadata.name');
        },
      );
    }

    test('a name of 80 characters is accepted', () {
      expect(parseOk(withMeta((m) => m['name'] = 'x' * 80)).name.length, 80);
    });

    for (final bad in [0, -3, 2147483648, 1.5, '3', null]) {
      test('refuses version $bad', () {
        expectInvalid(withMeta((m) => m['version'] = bad), 'metadata.version');
      });
    }

    test('accepts version 1 and 2^31-1', () {
      expect(parseOk(withMeta((m) => m['version'] = 1)).version, 1);
      expect(
        parseOk(withMeta((m) => m['version'] = 2147483647)).version,
        2147483647,
      );
    });

    test('author and description are optional but length capped', () {
      final json = validManifest();
      (json['metadata']! as Map)
        ..remove('author')
        ..remove('description');
      final m = parseOk(json);
      expect(m.author, '');
      expect(m.description, '');
      expectInvalid(withMeta((m) => m['author'] = 'a' * 81), 'metadata.author');
      expectInvalid(
        withMeta((m) => m['description'] = 'd' * 501),
        'metadata.description',
      );
    });

    test('description keeps newlines', () {
      expect(
        parseOk(withMeta((m) => m['description'] = 'a\nb')).description,
        'a\nb',
      );
    });

    test('bidi controls and zero-width characters are removed', () {
      final m = parseOk(
        withMeta((m) {
          m['name'] = 'A${_rlo}B${_zwsp}C${_lri}D$_bom';
          m['author'] = 'x${_ps}y';
          m['description'] = 'a${_rlo}b\nc';
        }),
      );
      expect(m.name, 'ABCD');
      expect(m.author, 'xy');
      expect(m.description, 'ab\nc');
    });

    test('lengths count code points, not UTF-16 units', () {
      expect(
        parseOk(withMeta((m) => m['name'] = '😀' * 80)).name.runes.length,
        80,
      );
      expectInvalid(withMeta((m) => m['name'] = '😀' * 81), 'metadata.name');
    });

    test('a problem detail is cut and has no control characters', () {
      final long = InvalidManifest('${'a' * 300}\u0000\n');
      expect(long.detail.runes.length, 200);
      expect(InvalidManifest('a\u0000b$_rlo').detail, 'a?b?');
    });
  });

  group('hosts', () {
    test('are lower-cased, trimmed and deduplicated', () {
      final m = parseOk(
        withMeta(
          (m) => m['hosts'] = ['Music.Example.com', 'music.example.com '],
        ),
      );
      expect(m.hosts, ['music.example.com']);
    });

    for (final host in [
      '127.0.0.1',
      'localhost',
      'a.local',
      'http://x.com',
      'a.com:80',
    ]) {
      test('refuses host $host', () {
        final problem = problemOf(
          withMeta((m) => m['hosts'] = ['ok.example.com', host]),
        );
        expect(problem, isA<InvalidHost>());
        expect(problem.detail, host);
      });
    }

    for (final bad in [
      <String>[],
      'a.com',
      [1],
      List.filled(21, 'a.com'),
    ]) {
      test('refuses a hosts value of $bad', () {
        expectInvalid(withMeta((m) => m['hosts'] = bad), 'metadata.hosts');
      });
    }

    test('accepts 20 hosts', () {
      final hosts = [for (var i = 0; i < 20; i++) 'h$i.example.com'];
      expect(parseOk(withMeta((m) => m['hosts'] = hosts)).hosts, hasLength(20));
    });
  });

  group('script map', () {
    for (final bad in ['../x.js', 'a/b.js', '', 5, null, 'noext', 'a.txt']) {
      test('refuses script.search $bad', () {
        final json = validManifest();
        (json['script']! as Map)['search'] = bad;
        expectInvalid(json, 'script.search');
      });
    }

    test('refuses a key outside [A-Za-z0-9_.-]', () {
      final json = validManifest();
      (json['script']! as Map)['a/b'] = 'x.js';
      expectInvalid(json, 'script.a/b');
    });

    test('refuses a missing required key per kind', () {
      expectInvalid(
        validManifest()..['script'] = {'search': 'a.js'},
        'script.lyrics',
      );
      expectInvalid(
        translateManifest((j) => j['script'] = {'search': 'a.js'}),
        'script.translate',
      );
      expectInvalid(
        streamingManifest(script: {'search': 'search.js'}),
        'script.stream',
      );
      expectInvalid(
        streamingManifest(script: {'stream': 'stream.js'}),
        'script.search',
      );
    });

    test('refuses more than 50 entries', () {
      final script = {
        'search': 'search.js',
        'lyrics': 'lyrics.js',
        for (var i = 0; i < 49; i++) 'k$i': 'k$i.js',
      };
      expectInvalid(validManifest()..['script'] = script, 'script');
    });

    test('keeps a script the kind does not need', () {
      final json = validManifest();
      (json['script']! as Map)['stream'] = 'stream.js';
      expect(parseOk(json).scripts['stream'], 'stream.js');
    });
  });

  group('regexp', () {
    test('is optional', () {
      expect(parseOk(validManifest()).regexp, isNull);
    });

    test('refuses a pattern that does not compile', () {
      expectInvalid(withMeta((m) => m['regexp'] = '(['), 'metadata.regexp');
    });

    test('refuses a non-string or over-long pattern', () {
      expectInvalid(withMeta((m) => m['regexp'] = 5), 'metadata.regexp');
      expectInvalid(
        withMeta((m) => m['regexp'] = 'a' * 501),
        'metadata.regexp',
      );
      expect(
        parseOk(withMeta((m) => m['regexp'] = 'a' * 500)).regexp,
        hasLength(500),
      );
    });
  });

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
