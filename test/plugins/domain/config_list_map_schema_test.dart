import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';

import 'config_test_support.dart';

void main() {
  group('list', () {
    test('text', () {
      final f = cfgOne<ListField>(
        cfgField('list', {
          'placeholder': 'item',
          'minItems': 1,
          'maxItems': 3,
          'default': ['a', 'b'],
        }),
      );
      expect(f.format, ListFormat.text);
      expect(f.placeholder, 'item');
      expect((f.minItems, f.maxItems), (1, 3));
      expect(f.defaultValue, isA<List<String>>());
    });

    test('number and integer defaults are typed lists', () {
      final n = cfgOne<ListField>(
        cfgField('list', {
          'format': 'number',
          'default': [1, 2.5],
        }),
      );
      expect(n.defaultValue, isA<List<num>>());
      final i = cfgOne<ListField>(
        cfgField('list', {
          'format': 'integer',
          'default': [1, 2],
        }),
      );
      expect(i.defaultValue, isA<List<int>>());
    });

    test('url', () {
      final f = cfgOne<ListField>(
        cfgField('list', {
          'format': 'url',
          'default': ['https://a.io'],
        }),
      );
      expect(f.format, ListFormat.url);
    });

    cfgBadFormat('unknown format', cfgField('list', {'format': 'date'}));
    cfgBad('default not a list', cfgField('list', {'default': 'a'}), 'default');
    cfgBad(
      'default has an empty item',
      cfgField('list', {
        'default': [''],
      }),
      'default',
    );
    cfgBad(
      'default has a long item',
      cfgField('list', {
        'default': ['x' * 2001],
      }),
      'default',
    );
    cfgBad(
      'default has 51 items',
      cfgField('list', {
        'default': [for (var i = 0; i < 51; i++) 'a'],
      }),
      'default',
    );
    cfgBad(
      'number default with text',
      cfgField('list', {
        'format': 'number',
        'default': ['1'],
      }),
      'default',
    );
    cfgBad(
      'integer default with fraction',
      cfgField('list', {
        'format': 'integer',
        'default': [1.5],
      }),
      'default',
    );
    cfgBad(
      'integer default unsafe',
      cfgField('list', {
        'format': 'integer',
        'default': [9007199254740992],
      }),
      'default',
    );
    cfgBad(
      'url default with http',
      cfgField('list', {
        'format': 'url',
        'default': ['http://a.io'],
      }),
      'default',
    );
    cfgBad(
      'default has a blank item',
      cfgField('list', {
        'default': ['  '],
      }),
      'default',
    );
    cfgBad('maxItems 51', cfgField('list', {'maxItems': 51}), 'maxItems');
    cfgBad(
      'minItems above maxItems',
      cfgField('list', {'minItems': 3, 'maxItems': 2}),
      'minItems',
    );
    cfgBad(
      'default under minItems',
      cfgField('list', {
        'minItems': 2,
        'default': ['a'],
      }),
      'default',
    );
  });

  group('map', () {
    test('default is a typed map', () {
      final f = cfgOne<MapField>(
        cfgField('map', {
          'maxItems': 5,
          'default': {'a': '1', 'b': ''},
        }),
      );
      expect(f.maxItems, 5);
      expect(f.defaultValue, isA<Map<String, String>>());
      expect(f.defaultValue, {'a': '1', 'b': ''});
    });

    test('format text and a missing format are accepted', () {
      expect(
        cfgOne<MapField>(cfgField('map', {'format': 'text'})),
        isA<MapField>(),
      );
      expect(cfgOne<MapField>(cfgField('map')), isA<MapField>());
    });

    cfgBadFormat('unknown format', cfgField('map', {'format': 'json'}));
    cfgBad('maxItems 0', cfgField('map', {'maxItems': 0}), 'maxItems');
    cfgBad('maxItems 51', cfgField('map', {'maxItems': 51}), 'maxItems');
    cfgBad(
      'default not a map',
      cfgField('map', {
        'default': ['a'],
      }),
      'default',
    );
    cfgBad(
      'default value not a string',
      cfgField('map', {
        'default': {'a': 1},
      }),
      'default',
    );
    cfgBad(
      'default value over 2000',
      cfgField('map', {
        'default': {'a': 'x' * 2001},
      }),
      'default',
    );
    for (final (name, key) in [
      ('empty', ''),
      ('over 100', 'k' * 101),
      ('with outer space', ' a'),
      ('with a control character', 'a\u0007'),
      ('__proto__', '__proto__'),
    ]) {
      cfgBad(
        'default key $name',
        cfgField('map', {
          'default': {key: 'v'},
        }),
        'default',
      );
    }
    cfgBad(
      'default above maxItems',
      cfgField('map', {
        'maxItems': 1,
        'default': {'a': '1', 'b': '2'},
      }),
      'default',
    );
  });
}
