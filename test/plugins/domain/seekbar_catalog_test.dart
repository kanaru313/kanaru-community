import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';

import '../fixtures/catalog_support.dart';

Map<String, Object?> seekbarEntry([Map<String, Object?> over = const {}]) => {
  'slug': 'neon',
  'name': 'Neon',
  'version': 1,
  'apiVersion': 1,
  'type': 'seekbar',
  'path': 'dist/neon/plugin.zip',
  ...over,
};

void main() {
  test('the published seekbar entries are all kept, none need a newer app '
      'except the Lottie one', () {
    final json = jsonDecode(
      File('test/plugins/fixtures/seekbar/catalog_seekbar.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    final catalog = okCatalog(json);
    expect(catalog.entries, hasLength(22));
    expect(catalog.dropped, 0);
    for (final e in catalog.entries) {
      expect(e.kind, PluginKind.seekbar);
      expect(e.hosts, isEmpty);
      expect(e.needsNewerApp, e.slug == 'vinyl', reason: e.slug);
    }
    expect(catalog.entries.singleWhere((e) => e.slug == 'vinyl').features, [
      'seekbar.lottie',
    ]);
  });

  test('hosts may be absent or empty for a seekbar entry', () {
    final catalog = okCatalog(
      catalogJson([
        seekbarEntry(),
        seekbarEntry({'slug': 'other', 'hosts': <Object?>[]}),
      ]),
    );
    expect(catalog.entries, hasLength(2));
    expect(catalog.entries.every((e) => e.hosts.isEmpty), isTrue);
  });

  test('a seekbar entry with hosts is dropped', () {
    final catalog = okCatalog(
      catalogJson([
        seekbarEntry({
          'hosts': ['a.example.com'],
        }),
        seekbarEntry({'slug': 'ok'}),
      ]),
    );
    expect(catalog.entries.single.slug, 'ok');
    expect(catalog.dropped, 1);
  });

  test('other kinds still need hosts', () {
    expect(
      problemOfCatalog(
        catalogJson([
          entryJson({'hosts': <Object?>[]}),
        ]),
      ),
      CatalogProblem.invalidCatalog,
    );
  });

  group('features', () {
    test('an unsupported feature counts as needing a newer app', () {
      final e = okCatalog(
        catalogJson([
          seekbarEntry({
            'features': ['seekbar.lottie'],
          }),
        ]),
      ).entries.single;
      expect(e.features, ['seekbar.lottie']);
      expect(e.needsNewerApp, isTrue);
      expect(e.kind, PluginKind.seekbar);
    });

    test('an unknown feature does too', () {
      final e = okCatalog(
        catalogJson([
          entryJson({
            'features': ['made.up'],
          }),
        ]),
      ).entries.single;
      expect(e.needsNewerApp, isTrue);
    });

    test('absent or empty is none', () {
      for (final over in <Map<String, Object?>>[
        {},
        {'features': <Object?>[]},
      ]) {
        final e = okCatalog(catalogJson([seekbarEntry(over)])).entries.single;
        expect(e.features, isEmpty);
        expect(e.needsNewerApp, isFalse);
      }
    });

    final bad = <String, Object?>{
      'not a list': 'seekbar.lottie',
      'a number': [1],
      'empty name': [''],
      'name over 40': ['x' * 41],
      'nine names': [for (var i = 0; i < 9; i++) 'f$i'],
    };
    bad.forEach((name, value) {
      test('drops the entry for $name', () {
        final catalog = okCatalog(
          catalogJson([
            seekbarEntry({'features': value}),
            seekbarEntry({'slug': 'ok'}),
          ]),
        );
        expect(catalog.entries.single.slug, 'ok');
        expect(catalog.dropped, 1);
      });
    });

    test('eight names of 40 characters are fine', () {
      final e = okCatalog(
        catalogJson([
          seekbarEntry({
            'features': [for (var i = 0; i < 8; i++) '${'x' * 39}$i'],
          }),
        ]),
      ).entries.single;
      expect(e.features, hasLength(8));
    });
  });
}
