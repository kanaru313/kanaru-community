import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';

import 'config_test_support.dart';

void main() {
  group('select', () {
    test('single with option subtitles', () {
      final f = cfgOne<SelectField>(
        cfgField('select', {'options': cfgOpts, 'default': 'b'}),
      );
      expect(f.format, SelectFormat.single);
      expect(f.options.first.subtitle, 'first');
      expect(f.options[1].subtitle, isNull);
      expect(f.defaultValue, 'b');
    });

    test('a missing format means single', () {
      expect(
        cfgOne<SelectField>(cfgField('select', {'options': cfgOpts})).format,
        SelectFormat.single,
      );
    });

    test('multiple keeps bounds and a typed default', () {
      final f = cfgOne<SelectField>(
        cfgField('select', {
          'format': 'multiple',
          'options': cfgOpts,
          'minItems': 1,
          'maxItems': 2,
          'default': ['a', 'c'],
        }),
      );
      expect(f.format, SelectFormat.multiple);
      expect((f.minItems, f.maxItems), (1, 2));
      expect(f.defaultValue, isA<List<String>>());
      expect(f.defaultValue, ['a', 'c']);
    });

    test('custom may have no options', () {
      final f = cfgOne<SelectField>(cfgField('select', {'custom': true}));
      expect(f.custom, isTrue);
      expect(f.options, isEmpty);
    });

    cfgBadFormat(
      'unknown format',
      cfgField('select', {'format': 'multi', 'options': cfgOpts}),
    );
    cfgBad(
      'single default not an option',
      cfgField('select', {'options': cfgOpts, 'default': 'z'}),
      'default',
    );
    cfgBad(
      'multiple default not a list',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'default': 'a',
      }),
      'default',
    );
    cfgBad(
      'multiple default has a stranger',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'default': ['z'],
      }),
      'default',
    );
    cfgBad(
      'multiple default repeats',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'default': ['a', 'a'],
      }),
      'default',
    );
    cfgBad(
      'multiple default above maxItems',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'maxItems': 1,
        'default': ['a', 'b'],
      }),
      'default',
    );
    cfgBad(
      'multiple default under minItems',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'minItems': 2,
        'default': ['a'],
      }),
      'default',
    );
    cfgBad(
      'maxItems above option count',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'maxItems': 4,
      }),
      'maxItems',
    );
    cfgBad(
      'minItems above option count',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'minItems': 4,
      }),
      'minItems',
    );
    cfgBad(
      'minItems above maxItems',
      cfgField('select', {
        'format': 'multiple',
        'options': cfgOpts,
        'minItems': 3,
        'maxItems': 2,
      }),
      'minItems',
    );
    cfgBad('no options', cfgField('select'), 'options');
    cfgBad(
      'empty options',
      cfgField('select', {'options': <Object?>[]}),
      'options',
    );
    cfgBad(
      'option subtitle over 300',
      cfgField('select', {
        'options': [
          {'value': 'a', 'title': 'A', 'subtitle': 'x' * 301},
        ],
      }),
      'options',
    );
    cfgBad(
      '51 options',
      cfgField('select', {
        'options': [
          for (var i = 0; i < 51; i++) {'value': 'v$i', 'title': 't'},
        ],
      }),
      'options',
    );
    cfgBad(
      'option without a title',
      cfgField('select', {
        'options': [
          {'value': 'v'},
        ],
      }),
      'options',
    );
    cfgBad(
      'duplicate option values',
      cfgField('select', {
        'options': [
          {'value': 'v', 'title': 'a'},
          {'value': 'v', 'title': 'b'},
        ],
      }),
      'options',
    );
    cfgBad(
      'custom on a multiple select',
      cfgField('select', {'format': 'multiple', 'custom': true}),
      'custom',
    );
  });
}
