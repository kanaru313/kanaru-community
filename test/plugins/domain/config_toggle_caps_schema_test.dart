import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';

import 'config_test_support.dart';
import 'plugin_test_support.dart';

void main() {
  group('toggle and common', () {
    test('toggle with a bool default', () {
      final f = cfgOne<ToggleField>(
        cfgField('toggle', {'default': true, 'required': true}),
      );
      expect(f.defaultValue, true);
      expect(f.required, isTrue);
    });

    test('required defaults to false', () {
      expect(cfgOne<ToggleField>(cfgField('toggle')).required, isFalse);
    });

    cfgBadFormat(
      'toggle with a format',
      cfgField('toggle', {'format': 'text'}),
    );
    cfgBad(
      'toggle default of wrong type',
      cfgField('toggle', {'default': 'yes'}),
      'default',
    );
    cfgBad('unknown mode', cfgField('slider'), 'mode');
    cfgBad('empty title', {'title': ' ', 'mode': 'toggle'}, 'title');
    cfgBad('title over 80', cfgField('toggle', {'title': 't' * 81}), 'title');
    cfgBad(
      'subtitle over 300',
      cfgField('toggle', {'subtitle': 'x' * 301}),
      'subtitle',
    );
    cfgBad(
      'custom on a toggle',
      cfgField('toggle', {'custom': true}),
      'custom',
    );
    cfgBad('custom on an input', cfgField('input', {'custom': true}), 'custom');
    cfgBad('custom on a list', cfgField('list', {'custom': true}), 'custom');
    cfgBad('custom on a map', cfgField('map', {'custom': true}), 'custom');

    test('a subtitle keeps newlines and a blank one is none', () {
      expect(
        cfgOne<ToggleField>(cfgField('toggle', {'subtitle': 'a\nb'})).subtitle,
        'a\nb',
      );
      expect(
        cfgOne<ToggleField>(cfgField('toggle', {'subtitle': '  '})).subtitle,
        isNull,
      );
    });

    test('fields keep the manifest order', () {
      final fields = configOk({
        'z': cfgField('toggle'),
        'a': cfgField('input'),
        'm': cfgField('list'),
      });
      expect(fields.map((f) => f.key), ['z', 'a', 'm']);
    });
  });

  group('caps', () {
    Map<String, Object?> many(int n) => {
      for (var i = 0; i < n; i++) 'k$i': cfgField('toggle'),
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
        final problem = configProblem({key: cfgField('toggle')});
        expect(problem.detail, 'config.$key');
      });
    }

    test('a field that is not an object is refused', () {
      expect(configProblem({'a': 'toggle'}).detail, 'config.a');
    });
  });
}
