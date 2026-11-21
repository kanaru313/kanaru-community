import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';

import '../fixtures/catalog_support.dart';

void main() {
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
      final catalog = okCatalog(
        catalogJson([
          for (final s in slugs) entryJson({'slug': s}),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['a', 'a-b_c9', 'x' * 64]);
      expect(catalog.dropped, 6);
    });

    test('a repeated slug keeps the first one', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'name': 'First'}),
          entryJson({'name': 'Second'}),
        ]),
      );
      expect(catalog.entries.single.name, 'First');
      expect(catalog.dropped, 1);
    });

    test('the four kinds are known', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'slug': 'a', 'type': 'lyrics'}),
          entryJson({'slug': 'b', 'type': 'translate'}),
          entryJson({'slug': 'c', 'type': 'ai-translate'}),
          entryJson({'slug': 'd', 'type': 'streaming'}),
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
      final catalog = okCatalog(
        catalogJson([
          entryJson({'slug': 'chat', 'type': 'chat'}),
          entryJson({'slug': 'old', 'type': 'source'}),
          entryJson(),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['chat', 'old', 'netease']);
      expect(catalog.entries.first.kind, isNull);
      expect(catalog.entries.first.needsNewerApp, isTrue);
      expect(catalog.entries.last.needsNewerApp, isFalse);
      expect(catalog.dropped, 0);
    });

    test('a type that is not a string drops the entry', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'slug': 'x', 'type': null}),
          entryJson({'slug': 'y', 'type': 7}),
          entryJson(),
        ]),
      );
      expect(catalog.entries.map((e) => e.slug), ['netease']);
      expect(catalog.dropped, 2);
    });

    test('an entry for a newer apiVersion is kept and flagged', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'apiVersion': 9}),
        ]),
      );
      expect(catalog.entries.single.apiVersion, 9);
      expect(catalog.entries.single.needsNewerApp, isTrue);
    });

    test('only a streaming entry may list wildcard hosts', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({
            'slug': 'yt',
            'type': 'streaming',
            'hosts': ['www.youtube.com', '*.googlevideo.com'],
          }),
          entryJson({
            'slug': 'bad',
            'hosts': ['*.googlevideo.com'],
          }),
          entryJson({
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
        final catalog = okCatalog(
          catalogJson([
            entryJson({'slug': 'bad', 'type': 'streaming', 'hosts': hosts}),
            entryJson(),
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
        final catalog = okCatalog(
          catalogJson([
            entryJson({'slug': 'bad', ...over}),
            entryJson(),
          ]),
        );
        expect(catalog.entries.map((e) => e.slug), [
          'netease',
        ], reason: '$over');
        expect(catalog.dropped, 1, reason: '$over');
      }
    });

    test('sha256 and size are optional', () {
      final e = okCatalog(catalogJson([entryJson()])).entries.single;
      expect(e.sha256, isNull);
      expect(e.size, isNull);
    });

    test('text is cleaned like manifest text', () {
      final bidi = String.fromCharCode(0x202e);
      final catalog = okCatalog(
        catalogJson([
          entryJson({'name': '  Net${bidi}Ease\u0000  '}),
        ]),
      );
      expect(catalog.entries.single.name, 'NetEase');
    });

    test('an entry that is not an object is dropped', () {
      final catalog = okCatalog(catalogJson([5, null, 'x', entryJson()]));
      expect(catalog.entries, hasLength(1));
      expect(catalog.dropped, 3);
    });

    test('a bad languages value keeps the entry and makes it global', () {
      final catalog = okCatalog(
        catalogJson([
          entryJson({'languages': 'vi'}),
        ]),
      );
      expect(catalog.entries.single.languages, isEmpty);
    });
  });
}
