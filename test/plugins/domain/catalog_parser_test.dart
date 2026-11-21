import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog_parser.dart';
import '../fixtures/catalog_support.dart';

void main() {
  test('parses a full entry', () {
    final catalog = okCatalog(
      catalogJson([
        entryJson({
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
    final catalog = okCatalog({
      'metadata': {'name': 'Rỗng'},
      'data': <Object?>[],
    });
    expect(catalog.author, '');
    expect(catalog.entries, isEmpty);
  });

  group('references', () {
    test('path and icon resolve against the catalog address', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'path': 'dist/netease/plugin.zip', 'icon': '../icons/n.png'}),
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
      final catalog = okCatalog(
        catalogJson([
          entryJson({'path': '/z/plugin.zip'}),
        ]),
        url: Uri.parse('http://192.168.1.5:8765/plugins.json'),
      );
      expect(
        catalog.entries.single.path,
        Uri.parse('http://192.168.1.5:8765/z/plugin.zip'),
      );
    });

    test('a fragment is dropped', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'path': 'a.zip#frag'}),
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
          final catalog = okCatalog(
            catalogJson([
              entryJson({'slug': 'bad', 'path': path}),
              entryJson(),
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
        final catalog = okCatalog(
          catalogJson([
            entryJson({'slug': 'a', 'path': 'https://other.example.com/a.zip'}),
            entryJson({'slug': 'b', 'icon': 'https://other.example.com/i.png'}),
          ]),
          allowed: onlyCdn,
        );
        expect(catalog.entries.map((e) => e.slug), ['b']);
        expect(catalog.entries.single.icon, isNull);
        expect(catalog.dropped, 1);
      },
    );

    test('an address over 2048 characters once absolute is dropped', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson(),
          entryJson({
            'slug': 'long',
            'path': 'https://cdn.example.com/z?${'a' * 2040}',
          }),
          // 2033 characters relative, longer once resolved.
          entryJson({'slug': 'rel', 'path': '/z?${'b' * 2030}'}),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['netease']);
      expect(catalog.dropped, 2);
    });

    test('a long icon only drops the icon', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'icon': 'https://cdn.example.com/i.png?${'a' * 2040}'}),
        ]),
      );
      expect(catalog.entries.single.icon, isNull);
      expect(catalog.dropped, 0);
    });
  });


  group('catalog rules', () {
    test('no usable entry in a non-empty data is invalid', () {
      expect(
        problemOfCatalog(
          catalogJson([
            entryJson({'slug': 'BAD'}),
          ]),
        ),
        CatalogProblem.invalidCatalog,
      );
      expect(problemOfCatalog(catalogJson([1, 2])), CatalogProblem.invalidCatalog);
    });

    test('at most 500 entries', () {
      List<Object?> many(int n) => [
        for (var i = 0; i < n; i++) entryJson({'slug': 's$i'}),
      ];
      expect(okCatalog(catalogJson(many(500))).entries, hasLength(500));
      expect(problemOfCatalog(catalogJson(many(501))), CatalogProblem.invalidCatalog);
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
        expect(problemOfCatalog(json), CatalogProblem.invalidCatalog, reason: '$json');
      }
    });

    test('not JSON or not UTF-8', () {
      expect(
        parseCatalog(Uint8List.fromList(utf8.encode('{nope')), catalogUrl, isReferenceAllowed: allowAll),
        isA<Err<Catalog, CatalogProblem>>(),
      );
      final bad = parseCatalog(Uint8List.fromList([0xff, 0xfe]), catalogUrl, isReferenceAllowed: allowAll);
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
        ...utf8.encode(jsonEncode(catalogJson([entryJson()]))),
      ]);
      final result = parseCatalog(bytes, catalogUrl, isReferenceAllowed: allowAll);
      expect(
        (result as Ok<Catalog, CatalogProblem>).value.entries,
        hasLength(1),
      );
    });

    test('the address policy is asked for every path and icon', () {
      final seen = <Uri>[];
      final catalog = okCatalog(
        catalogJson([
          entryJson({'icon': 'https://cdn.example.com/i.png'}),
          entryJson({'slug': 'other', 'path': 'https://evil.example.com/p.zip'}),
        ]),
        allowed: (uri) {
          seen.add(uri);
          return uri.host != 'evil.example.com';
        },
      );
      expect(catalog.entries.map((e) => e.slug), ['netease']);
      expect(seen.map((u) => u.host), contains('evil.example.com'));
      expect(seen.map((u) => u.path), contains('/i.png'));
    });

    test('a policy that refuses an icon only drops the icon', () {
      final catalog = okCatalog(
        catalogJson([entryJson({'icon': 'https://cdn.example.com/i.png'})]),
        allowed: (uri) => !uri.path.endsWith('.png'),
      );
      expect(catalog.entries.single.icon, isNull);
    });

    test('over 1 MiB is too large', () {
      final result = parseCatalog(Uint8List(maxCatalogBytes + 1), catalogUrl, isReferenceAllowed: allowAll);
      expect(
        (result as Err<Catalog, CatalogProblem>).error,
        CatalogProblem.tooLarge,
      );
      expect(
        parseCatalog(Uint8List(maxCatalogBytes), catalogUrl, isReferenceAllowed: allowAll),
        isA<Err<Catalog, CatalogProblem>>(),
      );
    });
  });
}
