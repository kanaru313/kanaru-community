import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';

import 'plugin_test_support.dart';

void main() {
  test('all three tune fields are accepted', () {
    final manifest = parseOk(aiManifest());
    expect(manifest.config.map((f) => f.key), [
      'model',
      'style',
      'customInstruction',
    ]);
  });

  for (final key in ['model', 'style', 'customInstruction']) {
    test('missing $key is refused', () {
      expectInvalid(aiManifest((c) => c.remove(key)), 'config.$key');
    });
  }

  test('model as an input is refused', () {
    expectInvalid(
      aiManifest((c) => c['model'] = {'title': 'Model', 'mode': 'input'}),
      'config.model',
    );
  });

  test('a multiple style is refused', () {
    expectInvalid(
      aiManifest((c) => (c['style']! as Map)['format'] = 'multiple'),
      'config.style',
    );
  });

  for (final key in ['model', 'style']) {
    test('$key without options is refused', () {
      expectInvalid(
        aiManifest((c) => (c[key]! as Map)['options'] = []),
        'config.$key.options',
      );
    });
  }

  test('customInstruction as multiline is refused', () {
    expectInvalid(
      aiManifest(
        (c) => (c['customInstruction']! as Map)['format'] = 'multiline',
      ),
      'config.customInstruction',
    );
  });

  test('customInstruction with format text is accepted', () {
    parseOk(
      aiManifest((c) => (c['customInstruction']! as Map)['format'] = 'text'),
    );
  });

  test('a translate plugin needs no tune field', () {
    final manifest = parseOk(aiManifest((c) => c.clear(), 'translate'));
    expect(manifest.kind, PluginKind.translate);
  });

  group('custom model', () {
    void custom(Map<String, Object?> c, {bool required = true}) {
      final model = c['model']! as Map<String, Object?>;
      model['options'] = <Object?>[];
      model['custom'] = true;
      if (required) model['required'] = true;
    }

    test('custom with no options and required is accepted', () {
      final model = parseOk(aiManifest(custom)).config.first as SelectField;
      expect(model.custom, isTrue);
      expect(model.options, isEmpty);
    });

    test('custom may leave options out', () {
      parseOk(
        aiManifest((c) {
          custom(c);
          (c['model']! as Map).remove('options');
        }),
      );
    });

    test('custom with some options is accepted', () {
      parseOk(
        aiManifest((c) {
          (c['model']! as Map)['custom'] = true;
          (c['model']! as Map)['required'] = true;
        }),
      );
    });

    test('custom without required is refused', () {
      expectInvalid(
        aiManifest((c) => custom(c, required: false)),
        'config.model.required',
      );
    });

    test('custom on a single select is accepted for any kind and field', () {
      parseOk(aiManifest((c) => (c['style']! as Map)['custom'] = true));
      parseOk(
        aiManifest((c) => (c['model']! as Map)['custom'] = true, 'translate'),
      );
      parseOk(
        validManifest()
          ..['config'] = {
            'region': {
              'title': 'Region',
              'mode': 'select',
              'custom': true,
              'options': [
                {'value': 'a', 'title': 'A'},
              ],
            },
          },
      );
    });

    for (final field in {
      'input': {'mode': 'input'},
      'list': {'mode': 'list'},
      'toggle': {'mode': 'toggle'},
      'map': {'mode': 'map'},
    }.entries) {
      test('custom on a ${field.key} field is refused', () {
        expectInvalid(
          aiManifest(
            (c) =>
                c['extra'] = {'title': 'Extra', ...field.value, 'custom': true},
          ),
          'config.extra.custom',
        );
      });
    }

    test('custom that is not a bool is refused', () {
      expectInvalid(
        aiManifest((c) => (c['model']! as Map)['custom'] = 'yes'),
        'config.model.custom',
      );
    });

    test('custom on a multiple select is refused', () {
      expectInvalid(
        aiManifest((c) {
          custom(c);
          (c['model']! as Map)['format'] = 'multiple';
        }),
        'config.model.custom',
      );
    });
  });
}
