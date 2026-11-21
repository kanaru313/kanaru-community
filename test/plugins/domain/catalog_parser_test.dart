import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog_parser.dart';

Map<String, Object?> _entry([Map<String, Object?> over = const {}]) => {
  'slug': 'netease',
  'name': 'NetEase Cloud Music',
  'version': 3,
  'apiVersion': 1,
  'type': 'lyrics',
  'hosts': ['music.163.com'],
  'path': 'https://cdn.example.com/netease/plugin.zip',
  ...over,
};

Uint8List _json(Object? value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));

Map<String, Object?> _catalog(List<Object?> data) => {
  'metadata': {'name': 'Kho của hieu05', 'author': 'hieu05'},
  'data': data,
};

final _url = Uri.parse('https://repo.example.com/plugins.json');

Result<Catalog, CatalogProblem> _parse(
  Object? json, {
  Uri? url,
  bool Function(Uri)? allowed,
}) => parseCatalog(_json(json), url ?? _url, isReferenceAllowed: allowed);

Catalog _ok(Object? json, {Uri? url, bool Function(Uri)? allowed}) =>
    switch (_parse(json, url: url, allowed: allowed)) {
      Ok(:final value) => value,
      Err(:final error) => fail('refused: $error'),
    };

CatalogProblem _problem(Object? json) => switch (_parse(json)) {
  Ok() => fail('the catalog was accepted'),
  Err(:final error) => error,
};

void main() {
  test('parses a full entry', () {
    final catalog = _ok(
      _catalog([
        _entry({
          'icon': 'https://cdn.example.com/netease/icon.png',
          'description': 'Lời từ NetEase',
          'author': 'hieu05',
          'hosts': ['Music.163.com ', 'interface.music.163.com'],
          'languages': ['zh', 'vi'],
          'sha256': 'AB' * 32,
          'size': 4096,
        }),
      ]),
    );
    expect(catalog.name, 'Kho của hieu05');
    expect(catalog.author, 'hieu05');
    expect(catalog.dropped, 0);
    final e = catalog.entries.single;
    expect(e.slug, 'netease');
    expect(e.kind, PluginKind.lyrics);
    expect(e.name, 'NetEase Cloud Music');
    expect(e.version, 3);
    expect(e.apiVersion, 1);
    expect(e.hosts, ['music.163.com', 'interface.music.163.com']);
    expect(e.path, Uri.parse('https://cdn.example.com/netease/plugin.zip'));
    expect(e.icon, Uri.parse('https://cdn.example.com/netease/icon.png'));
    expect(e.description, 'Lời từ NetEase');
    expect(e.author, 'hieu05');
    expect(e.languages, ['zho', 'vie']);
    expect(e.sha256, 'ab' * 32);
    expect(e.size, 4096);
    expect(e.needsNewerApp, isFalse);
  });

  test('author is optional; an empty data list is a valid empty catalog', () {
    final catalog = _ok({
      'metadata': {'name': 'Rỗng'},
      'data': <Object?>[],
    });
    expect(catalog.author, '');
    expect(catalog.entries, isEmpty);
  });

  group('references', () {
    test('path and icon resolve against the catalog address', () {
      final catalog = _ok(
        _catalog([
          _entry({'path': 'dist/netease/plugin.zip', 'icon': '../icons/n.png'}),
        ]),
        url: Uri.parse('https://repo.example.com/store/plugins.json'),
      );
      final e = catalog.entries.single;
      expect(
        e.path,
        Uri.parse('https://repo.example.com/store/dist/netease/plugin.zip'),
      );
      expect(e.icon, Uri.parse('https://repo.example.com/icons/n.png'));
    });

    test('a root-relative path keeps the port of a local catalog', () {
      final catalog = _ok(
        _catalog([
          _entry({'path': '/z/plugin.zip'}),
        ]),
        url: Uri.parse('http://192.168.1.5:8765/plugins.json'),
      );
      expect(
        catalog.entries.single.path,
        Uri.parse('http://192.168.1.5:8765/z/plugin.zip'),
      );
    });

    test('a fragment is dropped', () {
      final catalog = _ok(
        _catalog([
          _entry({'path': 'a.zip#frag'}),
        ]),
      );
      expect(catalog.entries.single.path.hasFragment, isFalse);
    });

    test(
      'a path that is not an http(s) address with a host drops the entry',
      () {
        for (final path in [
          'ftp://cdn.example.com/a.zip',
          'file:///etc/passwd',
          'https://user:pw@cdn.example.com/a.zip',
          'javascript:alert(1)',
          'https:///a.zip',
        ]) {
          final catalog = _ok(
            _catalog([
              _entry({'slug': 'bad', 'path': path}),
              _entry(),
            ]),
          );
          expect(catalog.entries.map((e) => e.slug), ['netease'], reason: path);
          expect(catalog.dropped, 1, reason: path);
        }
      },
    );

    test(
      'the address policy decides: path drops the entry, icon only the icon',
      () {
        bool onlyCdn(Uri u) => u.host == 'cdn.example.com';
        final catalog = _ok(
          _catalog([
            _entry({'slug': 'a', 'path': 'https://other.example.com/a.zip'}),
            _entry({'slug': 'b', 'icon': 'https://other.example.com/i.png'}),
          ]),
          allowed: onlyCdn,
        );
        expect(catalog.entries.map((e) => e.slug), ['b']);
        expect(catalog.entries.single.icon, isNull);
        expect(catalog.dropped, 1);
      },
    );

    test('an address over 2048 characters once absolute is dropped', () {
      final catalog = _ok(
        _catalog([
          _entry(),
          _entry({
            'slug': 'long',
            'path': 'https://cdn.example.com/z?${'a' * 2040}',
          }),
          // 2033 characters relative, longer once resolved.
          _entry({'slug': 'rel', 'path': '/z?${'b' * 2030}'}),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['netease']);
      expect(catalog.dropped, 2);
    });

    test('a long icon only drops the icon', () {
      final catalog = _ok(
        _catalog([
          _entry({'icon': 'https://cdn.example.com/i.png?${'a' * 2040}'}),
        ]),
      );
      expect(catalog.entries.single.icon, isNull);
      expect(catalog.dropped, 0);
    });
  });

  group('entry rules', () {
    test('slug pattern', () {
      final slugs = [
        'a',
        'a-b_c9',
        'x' * 64,
        'Upper',
        'has space',
        'dot.dot',
        '',
        'x' * 65,
        'ü',
      ];
      final catalog = _ok(
        _catalog([
          for (final s in slugs) _entry({'slug': s}),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['a', 'a-b_c9', 'x' * 64]);
      expect(catalog.dropped, 6);
    });

    test('a repeated slug keeps the first one', () {
      final catalog = _ok(
        _catalog([
          _entry({'name': 'First'}),
          _entry({'name': 'Second'}),
        ]),
      );
      expect(catalog.entries.single.name, 'First');
      expect(catalog.dropped, 1);
    });

    test('the four kinds are known', () {
      final catalog = _ok(
        _catalog([
          _entry({'slug': 'a', 'type': 'lyrics'}),
          _entry({'slug': 'b', 'type': 'translate'}),
          _entry({'slug': 'c', 'type': 'ai-translate'}),
          _entry({'slug': 'd', 'type': 'streaming'}),
        ]),
      );
      expect(catalog.entries.map((e) => e.kind), [
        PluginKind.lyrics,
        PluginKind.translate,
        PluginKind.aiTranslate,
        PluginKind.streaming,
      ]);
      expect(catalog.entries.every((e) => !e.needsNewerApp), isTrue);
    });

    test('an unknown type is kept and needs a newer app', () {
      final catalog = _ok(
        _catalog([
          _entry({'slug': 'chat', 'type': 'chat'}),
          _entry({'slug': 'old', 'type': 'source'}),
          _entry(),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['chat', 'old', 'netease']);
      expect(catalog.entries.first.kind, isNull);
      expect(catalog.entries.first.needsNewerApp, isTrue);
      expect(catalog.entries.last.needsNewerApp, isFalse);
      expect(catalog.dropped, 0);
    });

    test('a type that is not a string drops the entry', () {
      final catalog = _ok(
        _catalog([
          _entry({'slug': 'x', 'type': null}),
          _entry({'slug': 'y', 'type': 7}),
          _entry(),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['netease']);
      expect(catalog.dropped, 2);
    });

    test('an entry for a newer apiVersion is kept and flagged', () {
      final catalog = _ok(
        _catalog([
          _entry({'apiVersion': 9}),
        ]),
      );
      expect(catalog.entries.single.apiVersion, 9);
      expect(catalog.entries.single.needsNewerApp, isTrue);
    });

    test('only a streaming entry may list wildcard hosts', () {
      final catalog = _ok(
        _catalog([
          _entry({
            'slug': 'yt',
            'type': 'streaming',
            'hosts': ['www.youtube.com', '*.googlevideo.com'],
          }),
          _entry({
            'slug': 'bad',
            'hosts': ['*.googlevideo.com'],
          }),
          _entry({
            'slug': 'bad2',
            'type': 'translate',
            'hosts': ['*.googlevideo.com'],
          }),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['yt']);
      expect(catalog.entries.single.hosts, [
        'www.youtube.com',
        '*.googlevideo.com',
      ]);
      expect(catalog.dropped, 2);
    });

    test('a streaming entry with a refused wildcard is dropped', () {
      final bad = <List<String>>[
        ['*.workers.dev'],
        ['*.com'],
        ['a.*.example.com'],
        [for (var i = 0; i <= 10; i++) '*.h$i.example.com'],
      ];
      for (final hosts in bad) {
        final catalog = _ok(
          _catalog([
            _entry({'slug': 'bad', 'type': 'streaming', 'hosts': hosts}),
            _entry(),
          ]),
        );
        expect(catalog.entries.map((e) => e.slug), [
          'netease',
        ], reason: '$hosts');
      }
    });

    test('invalid fields drop the entry', () {
      final bad = <Map<String, Object?>>[
        {'name': ''},
        {'name': 'x' * 81},
        {'name': 5},
        {'version': 0},
        {'version': '3'},
        {'version': 2147483648},
        {'apiVersion': 0},
        {'apiVersion': 'one'},
        {'hosts': <Object?>[]},
        {'hosts': 'music.163.com'},
        {
          'hosts': ['localhost'],
        },
        {
          'hosts': ['192.168.1.1'],
        },
        {
          'hosts': ['single'],
        },
        {
          'hosts': ['ok.example.com', 5],
        },
        {'hosts': List.generate(21, (i) => 'h$i.example.com')},
        {'description': 'x' * 501},
        {'author': 'x' * 81},
        {'path': null},
        {'path': ''},
        {'path': 7},
        {'sha256': 'abc'},
        {'sha256': 'z' * 64},
        {'sha256': 5},
        {'size': 0},
        {'size': 5 * 1024 * 1024 + 1},
        {'size': '10'},
      ];
      for (final over in bad) {
        final catalog = _ok(
          _catalog([
            _entry({'slug': 'bad', ...over}),
            _entry(),
          ]),
        );
        expect(catalog.entries.map((e) => e.slug), [
          'netease',
        ], reason: '$over');
        expect(catalog.dropped, 1, reason: '$over');
      }
    });

    test('sha256 and size are optional', () {
      final e = _ok(_catalog([_entry()])).entries.single;
      expect(e.sha256, isNull);
      expect(e.size, isNull);
    });

    test('text is cleaned like manifest text', () {
      final bidi = String.fromCharCode(0x202e);
      final catalog = _ok(
        _catalog([
          _entry({'name': '  Net${bidi}Ease\u0000  '}),
        ]),
      );
      expect(catalog.entries.single.name, 'NetEase');
    });

    test('an entry that is not an object is dropped', () {
      final catalog = _ok(_catalog([5, null, 'x', _entry()]));
      expect(catalog.entries, hasLength(1));
      expect(catalog.dropped, 3);
    });

    test('a bad languages value keeps the entry and makes it global', () {
      final catalog = _ok(
        _catalog([
          _entry({'languages': 'vi'}),
        ]),
      );
      expect(catalog.entries.single.languages, isEmpty);
    });
  });

  group('catalog rules', () {
    test('no usable entry in a non-empty data is invalid', () {
      expect(
        _problem(
          _catalog([
            _entry({'slug': 'BAD'}),
          ]),
        ),
        CatalogProblem.invalidCatalog,
      );
      expect(_problem(_catalog([1, 2])), CatalogProblem.invalidCatalog);
    });

    test('at most 500 entries', () {
      List<Object?> many(int n) => [
        for (var i = 0; i < n; i++) _entry({'slug': 's$i'}),
      ];
      expect(_ok(_catalog(many(500))).entries, hasLength(500));
      expect(_problem(_catalog(many(501))), CatalogProblem.invalidCatalog);
    });

    test('shape errors', () {
      for (final json in <Object?>[
        [],
        'text',
        {'data': <Object?>[]},
        {
          'metadata': {'name': 'x'},
        },
        {'metadata': 'x', 'data': <Object?>[]},
        {'metadata': {}, 'data': <Object?>[]},
        {
          'metadata': {'name': ''},
          'data': <Object?>[],
        },
        {
          'metadata': {'name': 'x' * 81},
          'data': <Object?>[],
        },
        {
          'metadata': {'name': 'x', 'author': 3},
          'data': <Object?>[],
        },
        {
          'metadata': {'name': 'x'},
          'data': <String, Object?>{},
        },
      ]) {
        expect(_problem(json), CatalogProblem.invalidCatalog, reason: '$json');
      }
    });

    test('not JSON or not UTF-8', () {
      expect(
        parseCatalog(Uint8List.fromList(utf8.encode('{nope')), _url),
        isA<Err<Catalog, CatalogProblem>>(),
      );
      final bad = parseCatalog(Uint8List.fromList([0xff, 0xfe]), _url);
      expect(
        (bad as Err<Catalog, CatalogProblem>).error,
        CatalogProblem.invalidCatalog,
      );
    });

    test('a leading BOM is tolerated', () {
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(jsonEncode(_catalog([_entry()]))),
      ]);
      final result = parseCatalog(bytes, _url);
      expect(
        (result as Ok<Catalog, CatalogProblem>).value.entries,
        hasLength(1),
      );
    });

    test('over 1 MiB is too large', () {
      final result = parseCatalog(Uint8List(maxCatalogBytes + 1), _url);
      expect(
        (result as Err<Catalog, CatalogProblem>).error,
        CatalogProblem.tooLarge,
      );
      expect(
        parseCatalog(Uint8List(maxCatalogBytes), _url),
        isA<Err<Catalog, CatalogProblem>>(),
      );
    });
  });
}
