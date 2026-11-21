import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';

import 'plugin_test_support.dart';

Map<String, Object?> _f(String mode, [Map<String, Object?>? more]) => {
  'title': 'T',
  'mode': mode,
  ...?more,
};

Map<String, Object?> _input(String format, [Map<String, Object?>? more]) =>
    _f('input', {'format': format, ...?more});

T _one<T extends ConfigField>(Map<String, Object?> field) =>
    configOk({'k': field}).single as T;

/// The field [field] is refused with `InvalidManifest('config.k.<attr>')`.
void _bad(String name, Map<String, Object?> field, String attr) {
  test(name, () {
    final problem = configProblem({'k': field});
    expect(problem, isA<InvalidManifest>(), reason: '$problem');
    expect(problem.detail, 'config.k.$attr');
  });
}

/// The field [field] is refused with `UnknownConfigFormat`.
void _badFormat(String name, Map<String, Object?> field) {
  test(name, () {
    final problem = configProblem({'k': field});
    expect(problem, isA<UnknownConfigFormat>(), reason: '$problem');
    expect(problem.detail, 'config.k.format');
  });
}

final _opts = [
  {'value': 'a', 'title': 'A', 'subtitle': 'first'},
  {'value': 'b', 'title': 'B'},
  {'value': 'c', 'title': 'C'},
];

void main() {
  group('input', () {
    test('text keeps length bounds and placeholder', () {
      final f = _one<InputField>(
        _input('text', {
          'placeholder': 'hint',
          'minLength': 2,
          'maxLength': 5,
          'default': 'abc',
          'required': true,
          'pattern': r'^a+$',
          'patternMessage': 'x',
        }),
      );
      expect(f.format, InputFormat.text);
      expect(f.placeholder, 'hint');
      expect((f.minLength, f.maxLength), (2, 5));
      expect(f.defaultValue, 'abc');
      expect(f.required, isTrue);
    });

    test('a missing format means text', () {
      expect(_one<InputField>(_f('input')).format, InputFormat.text);
    });

    test('multiline takes rows', () {
      final f = _one<InputField>(
        _input('multiline', {'rows': 6, 'maxLength': 100}),
      );
      expect(f.format, InputFormat.multiline);
      expect(f.rows, 6);
      expect(f.maxLength, 100);
    });

    test('number keeps min, max, step and a typed default', () {
      final f = _one<InputField>(
        _input('number', {'min': -1.5, 'max': 9, 'step': 0.5, 'default': 2.5}),
      );
      expect((f.min, f.max, f.step, f.defaultValue), (-1.5, 9, 0.5, 2.5));
    });

    test('a number default may be a decimal string and becomes a number', () {
      for (final (text, value) in [('5', 5), ('-2.5', -2.5), ('1e3', 1000)]) {
        expect(
          _one<InputField>(_input('number', {'default': text})).defaultValue,
          value,
        );
      }
    });

    test('integer', () {
      final f = _one<InputField>(
        _input('integer', {'min': 1, 'max': 10, 'step': 2, 'default': 4}),
      );
      expect((f.min, f.max, f.step, f.defaultValue), (1, 10, 2, 4));
    });

    test('url', () {
      final f = _one<InputField>(
        _input('url', {'default': 'https://example.com/a'}),
      );
      expect(f.format, InputFormat.url);
      expect(f.defaultValue, 'https://example.com/a');
    });

    test('attributes that do not apply are ignored', () {
      final f = _one<InputField>(
        _input('url', {'min': 'x', 'rows': 99, 'step': 0, 'minLength': -4}),
      );
      expect((f.min, f.rows, f.step, f.minLength), (null, null, null, null));
    });

    test('integer accepts the safe limits', () {
      final f = _one<InputField>(
        _input('integer', {'min': -9007199254740991, 'max': 9007199254740991}),
      );
      expect(f.max, 9007199254740991);
    });

    _badFormat('format date', _input('date'));
    _badFormat('format secret', _input('secret'));
    _badFormat(
      'format secret with a default',
      _input('secret', {'default': ''}),
    );
    _badFormat('format Text (case matters)', _input('Text'));
    _badFormat('a non-string format', _f('input', {'format': 3}));
    _bad('required not a bool', _f('input', {'required': 'yes'}), 'required');
    _bad(
      'placeholder over 200',
      _input('text', {'placeholder': 'x' * 201}),
      'placeholder',
    );
    _bad(
      'placeholder not a string',
      _input('text', {'placeholder': 1}),
      'placeholder',
    );
    _bad('minLength negative', _input('text', {'minLength': -1}), 'minLength');
    _bad('maxLength 0', _input('text', {'maxLength': 0}), 'maxLength');
    _bad(
      'maxLength over 2000',
      _input('text', {'maxLength': 2001}),
      'maxLength',
    );
    _bad(
      'minLength above maxLength',
      _input('text', {'minLength': 5, 'maxLength': 3}),
      'minLength',
    );
    _bad(
      'minLength not an int',
      _input('text', {'minLength': 1.5}),
      'minLength',
    );
    _bad(
      'text default of wrong type',
      _input('text', {'default': 1}),
      'default',
    );
    _bad(
      'text default too long',
      _input('text', {'default': 'x' * 2001}),
      'default',
    );
    _bad(
      'text default under minLength',
      _input('text', {'minLength': 3, 'default': 'a'}),
      'default',
    );
    _bad(
      'text default over maxLength',
      _input('text', {'maxLength': 3, 'default': 'abcd'}),
      'default',
    );
    _bad('rows 0', _input('multiline', {'rows': 0}), 'rows');
    _bad('rows 11', _input('multiline', {'rows': 11}), 'rows');
    _bad('number min not a number', _input('number', {'min': 'a'}), 'min');
    _bad(
      'number max not finite',
      _input('number', {'max': double.infinity}),
      'max',
    );
    _bad('number min above max', _input('number', {'min': 5, 'max': 1}), 'min');
    _bad('number step 0', _input('number', {'step': 0}), 'step');
    _bad('number step negative', _input('number', {'step': -1}), 'step');
    _bad(
      'number default below min',
      _input('number', {'min': 1, 'default': 0}),
      'default',
    );
    _bad(
      'number default above max',
      _input('number', {'max': 1, 'default': 2}),
      'default',
    );
    _bad('number default bool', _input('number', {'default': true}), 'default');
    for (final bad in ['x', 'NaN', 'Infinity', '0x10', ' 5', '1e999', '']) {
      _bad(
        'number default string "$bad"',
        _input('number', {'default': bad}),
        'default',
      );
    }
    _bad('integer min fractional', _input('integer', {'min': 1.5}), 'min');
    _bad('integer step 0', _input('integer', {'step': 0}), 'step');
    _bad('integer step fractional', _input('integer', {'step': 0.5}), 'step');
    _bad(
      'integer unsafe max',
      _input('integer', {'max': 9007199254740992}),
      'max',
    );
    _bad(
      'integer unsafe default',
      _input('integer', {'default': 9007199254740992}),
      'default',
    );
    _bad(
      'integer fractional default',
      _input('integer', {'default': 1.5}),
      'default',
    );
    _bad(
      'integer default as string',
      _input('integer', {'default': '5'}),
      'default',
    );
    _bad(
      'url default http',
      _input('url', {'default': 'http://example.com'}),
      'default',
    );
    _bad(
      'url default with userinfo',
      _input('url', {'default': 'https://u@example.com'}),
      'default',
    );
    _bad(
      'url default without host',
      _input('url', {'default': 'https://'}),
      'default',
    );
  });

  group('select', () {
    test('single with option subtitles', () {
      final f = _one<SelectField>(
        _f('select', {'options': _opts, 'default': 'b'}),
      );
      expect(f.format, SelectFormat.single);
      expect(f.options.first.subtitle, 'first');
      expect(f.options[1].subtitle, isNull);
      expect(f.defaultValue, 'b');
    });

    test('a missing format means single', () {
      expect(
        _one<SelectField>(_f('select', {'options': _opts})).format,
        SelectFormat.single,
      );
    });

    test('multiple keeps bounds and a typed default', () {
      final f = _one<SelectField>(
        _f('select', {
          'format': 'multiple',
          'options': _opts,
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
      final f = _one<SelectField>(_f('select', {'custom': true}));
      expect(f.custom, isTrue);
      expect(f.options, isEmpty);
    });

    _badFormat(
      'unknown format',
      _f('select', {'format': 'multi', 'options': _opts}),
    );
    _bad(
      'single default not an option',
      _f('select', {'options': _opts, 'default': 'z'}),
      'default',
    );
    _bad(
      'multiple default not a list',
      _f('select', {'format': 'multiple', 'options': _opts, 'default': 'a'}),
      'default',
    );
    _bad(
      'multiple default has a stranger',
      _f('select', {
        'format': 'multiple',
        'options': _opts,
        'default': ['z'],
      }),
      'default',
    );
    _bad(
      'multiple default repeats',
      _f('select', {
        'format': 'multiple',
        'options': _opts,
        'default': ['a', 'a'],
      }),
      'default',
    );
    _bad(
      'multiple default above maxItems',
      _f('select', {
        'format': 'multiple',
        'options': _opts,
        'maxItems': 1,
        'default': ['a', 'b'],
      }),
      'default',
    );
    _bad(
      'multiple default under minItems',
      _f('select', {
        'format': 'multiple',
        'options': _opts,
        'minItems': 2,
        'default': ['a'],
      }),
      'default',
    );
    _bad(
      'maxItems above option count',
      _f('select', {'format': 'multiple', 'options': _opts, 'maxItems': 4}),
      'maxItems',
    );
    _bad(
      'minItems above option count',
      _f('select', {'format': 'multiple', 'options': _opts, 'minItems': 4}),
      'minItems',
    );
    _bad(
      'minItems above maxItems',
      _f('select', {
        'format': 'multiple',
        'options': _opts,
        'minItems': 3,
        'maxItems': 2,
      }),
      'minItems',
    );
    _bad('no options', _f('select'), 'options');
    _bad('empty options', _f('select', {'options': <Object?>[]}), 'options');
    _bad(
      'option subtitle over 300',
      _f('select', {
        'options': [
          {'value': 'a', 'title': 'A', 'subtitle': 'x' * 301},
        ],
      }),
      'options',
    );
    _bad(
      '51 options',
      _f('select', {
        'options': [
          for (var i = 0; i < 51; i++) {'value': 'v$i', 'title': 't'},
        ],
      }),
      'options',
    );
    _bad(
      'option without a title',
      _f('select', {
        'options': [
          {'value': 'v'},
        ],
      }),
      'options',
    );
    _bad(
      'duplicate option values',
      _f('select', {
        'options': [
          {'value': 'v', 'title': 'a'},
          {'value': 'v', 'title': 'b'},
        ],
      }),
      'options',
    );
    _bad(
      'custom on a multiple select',
      _f('select', {'format': 'multiple', 'custom': true}),
      'custom',
    );
  });

  group('list', () {
    test('text', () {
      final f = _one<ListField>(
        _f('list', {
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
      final n = _one<ListField>(
        _f('list', {
          'format': 'number',
          'default': [1, 2.5],
        }),
      );
      expect(n.defaultValue, isA<List<num>>());
      final i = _one<ListField>(
        _f('list', {
          'format': 'integer',
          'default': [1, 2],
        }),
      );
      expect(i.defaultValue, isA<List<int>>());
    });

    test('url', () {
      final f = _one<ListField>(
        _f('list', {
          'format': 'url',
          'default': ['https://a.io'],
        }),
      );
      expect(f.format, ListFormat.url);
    });

    _badFormat('unknown format', _f('list', {'format': 'date'}));
    _bad('default not a list', _f('list', {'default': 'a'}), 'default');
    _bad(
      'default has an empty item',
      _f('list', {
        'default': [''],
      }),
      'default',
    );
    _bad(
      'default has a long item',
      _f('list', {
        'default': ['x' * 2001],
      }),
      'default',
    );
    _bad(
      'default has 51 items',
      _f('list', {
        'default': [for (var i = 0; i < 51; i++) 'a'],
      }),
      'default',
    );
    _bad(
      'number default with text',
      _f('list', {
        'format': 'number',
        'default': ['1'],
      }),
      'default',
    );
    _bad(
      'integer default with fraction',
      _f('list', {
        'format': 'integer',
        'default': [1.5],
      }),
      'default',
    );
    _bad(
      'integer default unsafe',
      _f('list', {
        'format': 'integer',
        'default': [9007199254740992],
      }),
      'default',
    );
    _bad(
      'url default with http',
      _f('list', {
        'format': 'url',
        'default': ['http://a.io'],
      }),
      'default',
    );
    _bad(
      'default has a blank item',
      _f('list', {
        'default': ['  '],
      }),
      'default',
    );
    _bad('maxItems 51', _f('list', {'maxItems': 51}), 'maxItems');
    _bad(
      'minItems above maxItems',
      _f('list', {'minItems': 3, 'maxItems': 2}),
      'minItems',
    );
    _bad(
      'default under minItems',
      _f('list', {
        'minItems': 2,
        'default': ['a'],
      }),
      'default',
    );
  });

  group('map', () {
    test('default is a typed map', () {
      final f = _one<MapField>(
        _f('map', {
          'maxItems': 5,
          'default': {'a': '1', 'b': ''},
        }),
      );
      expect(f.maxItems, 5);
      expect(f.defaultValue, isA<Map<String, String>>());
      expect(f.defaultValue, {'a': '1', 'b': ''});
    });

    test('format text and a missing format are accepted', () {
      expect(_one<MapField>(_f('map', {'format': 'text'})), isA<MapField>());
      expect(_one<MapField>(_f('map')), isA<MapField>());
    });

    _badFormat('unknown format', _f('map', {'format': 'json'}));
    _bad('maxItems 0', _f('map', {'maxItems': 0}), 'maxItems');
    _bad('maxItems 51', _f('map', {'maxItems': 51}), 'maxItems');
    _bad(
      'default not a map',
      _f('map', {
        'default': ['a'],
      }),
      'default',
    );
    _bad(
      'default value not a string',
      _f('map', {
        'default': {'a': 1},
      }),
      'default',
    );
    _bad(
      'default value over 2000',
      _f('map', {
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
      _bad(
        'default key $name',
        _f('map', {
          'default': {key: 'v'},
        }),
        'default',
      );
    }
    _bad(
      'default above maxItems',
      _f('map', {
        'maxItems': 1,
        'default': {'a': '1', 'b': '2'},
      }),
      'default',
    );
  });

  group('toggle and common', () {
    test('toggle with a bool default', () {
      final f = _one<ToggleField>(
        _f('toggle', {'default': true, 'required': true}),
      );
      expect(f.defaultValue, true);
      expect(f.required, isTrue);
    });

    test('required defaults to false', () {
      expect(_one<ToggleField>(_f('toggle')).required, isFalse);
    });

    _badFormat('toggle with a format', _f('toggle', {'format': 'text'}));
    _bad(
      'toggle default of wrong type',
      _f('toggle', {'default': 'yes'}),
      'default',
    );
    _bad('unknown mode', _f('slider'), 'mode');
    _bad('empty title', {'title': ' ', 'mode': 'toggle'}, 'title');
    _bad('title over 80', _f('toggle', {'title': 't' * 81}), 'title');
    _bad(
      'subtitle over 300',
      _f('toggle', {'subtitle': 'x' * 301}),
      'subtitle',
    );
    _bad('custom on a toggle', _f('toggle', {'custom': true}), 'custom');
    _bad('custom on an input', _f('input', {'custom': true}), 'custom');
    _bad('custom on a list', _f('list', {'custom': true}), 'custom');
    _bad('custom on a map', _f('map', {'custom': true}), 'custom');

    test('a subtitle keeps newlines and a blank one is none', () {
      expect(
        _one<ToggleField>(_f('toggle', {'subtitle': 'a\nb'})).subtitle,
        'a\nb',
      );
      expect(
        _one<ToggleField>(_f('toggle', {'subtitle': '  '})).subtitle,
        isNull,
      );
    });

    test('fields keep the manifest order', () {
      final fields = configOk({
        'z': _f('toggle'),
        'a': _f('input'),
        'm': _f('list'),
      });
      expect(fields.map((f) => f.key), ['z', 'a', 'm']);
    });
  });

  group('caps', () {
    Map<String, Object?> many(int n) => {
      for (var i = 0; i < n; i++) 'k$i': _f('toggle'),
    };

    test('20 fields pass and 21 do not', () {
      expect(configOk(many(20)), hasLength(20));
      expect(configProblem(many(21)).detail, 'config');
    });

    test('config must be an object', () {
      expect(configProblem([]), isA<InvalidManifest>());
      expect(configProblem('x').detail, 'config');
    });

    test('an absent config is empty', () {
      expect(configOk({}), isEmpty);
    });

    for (final key in ['a-b', 'k' * 41, '', 'a b']) {
      test('key "${key.length > 10 ? 'k*41' : key}" is refused', () {
        final problem = configProblem({key: _f('toggle')});
        expect(problem.detail, 'config.$key');
      });
    }

    test('a field that is not an object is refused', () {
      expect(configProblem({'a': 'toggle'}).detail, 'config.a');
    });
  });
}
