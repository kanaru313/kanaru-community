import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';

import 'config_test_support.dart';

void main() {
  group('input', () {
    test('text keeps length bounds and placeholder', () {
      final f = cfgOne<InputField>(
        cfgInput('text', {
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
      expect(cfgOne<InputField>(cfgField('input')).format, InputFormat.text);
    });

    test('multiline takes rows', () {
      final f = cfgOne<InputField>(
        cfgInput('multiline', {'rows': 6, 'maxLength': 100}),
      );
      expect(f.format, InputFormat.multiline);
      expect(f.rows, 6);
      expect(f.maxLength, 100);
    });

    test('number keeps min, max, step and a typed default', () {
      final f = cfgOne<InputField>(
        cfgInput('number', {
          'min': -1.5,
          'max': 9,
          'step': 0.5,
          'default': 2.5,
        }),
      );
      expect((f.min, f.max, f.step, f.defaultValue), (-1.5, 9, 0.5, 2.5));
    });

    test('a number default may be a decimal string and becomes a number', () {
      for (final (text, value) in [('5', 5), ('-2.5', -2.5), ('1e3', 1000)]) {
        expect(
          cfgOne<InputField>(cfgInput('number', {'default': text}))
              .defaultValue,
          value,
        );
      }
    });

    test('integer', () {
      final f = cfgOne<InputField>(
        cfgInput('integer', {'min': 1, 'max': 10, 'step': 2, 'default': 4}),
      );
      expect((f.min, f.max, f.step, f.defaultValue), (1, 10, 2, 4));
    });

    test('url', () {
      final f = cfgOne<InputField>(
        cfgInput('url', {'default': 'https://example.com/a'}),
      );
      expect(f.format, InputFormat.url);
      expect(f.defaultValue, 'https://example.com/a');
    });

    test('attributes that do not apply are ignored', () {
      final f = cfgOne<InputField>(
        cfgInput('url', {'min': 'x', 'rows': 99, 'step': 0, 'minLength': -4}),
      );
      expect((f.min, f.rows, f.step, f.minLength), (null, null, null, null));
    });

    test('integer accepts the safe limits', () {
      final f = cfgOne<InputField>(
        cfgInput('integer', {
          'min': -9007199254740991,
          'max': 9007199254740991,
        }),
      );
      expect(f.max, 9007199254740991);
    });

    cfgBadFormat('format date', cfgInput('date'));
    cfgBadFormat('format secret', cfgInput('secret'));
    cfgBadFormat(
      'format secret with a default',
      cfgInput('secret', {'default': ''}),
    );
    cfgBadFormat('format Text (case matters)', cfgInput('Text'));
    cfgBadFormat('a non-string format', cfgField('input', {'format': 3}));
    cfgBad(
      'required not a bool',
      cfgField('input', {'required': 'yes'}),
      'required',
    );
    cfgBad(
      'placeholder over 200',
      cfgInput('text', {'placeholder': 'x' * 201}),
      'placeholder',
    );
    cfgBad(
      'placeholder not a string',
      cfgInput('text', {'placeholder': 1}),
      'placeholder',
    );
    cfgBad(
      'minLength negative',
      cfgInput('text', {'minLength': -1}),
      'minLength',
    );
    cfgBad('maxLength 0', cfgInput('text', {'maxLength': 0}), 'maxLength');
    cfgBad(
      'maxLength over 2000',
      cfgInput('text', {'maxLength': 2001}),
      'maxLength',
    );
    cfgBad(
      'minLength above maxLength',
      cfgInput('text', {'minLength': 5, 'maxLength': 3}),
      'minLength',
    );
    cfgBad(
      'minLength not an int',
      cfgInput('text', {'minLength': 1.5}),
      'minLength',
    );
    cfgBad(
      'text default of wrong type',
      cfgInput('text', {'default': 1}),
      'default',
    );
    cfgBad(
      'text default too long',
      cfgInput('text', {'default': 'x' * 2001}),
      'default',
    );
    cfgBad(
      'text default under minLength',
      cfgInput('text', {'minLength': 3, 'default': 'a'}),
      'default',
    );
    cfgBad(
      'text default over maxLength',
      cfgInput('text', {'maxLength': 3, 'default': 'abcd'}),
      'default',
    );
    cfgBad('rows 0', cfgInput('multiline', {'rows': 0}), 'rows');
    cfgBad('rows 11', cfgInput('multiline', {'rows': 11}), 'rows');
    cfgBad('number min not a number', cfgInput('number', {'min': 'a'}), 'min');
    cfgBad(
      'number max not finite',
      cfgInput('number', {'max': double.infinity}),
      'max',
    );
    cfgBad(
      'number min above max',
      cfgInput('number', {'min': 5, 'max': 1}),
      'min',
    );
    cfgBad('number step 0', cfgInput('number', {'step': 0}), 'step');
    cfgBad('number step negative', cfgInput('number', {'step': -1}), 'step');
    cfgBad(
      'number default below min',
      cfgInput('number', {'min': 1, 'default': 0}),
      'default',
    );
    cfgBad(
      'number default above max',
      cfgInput('number', {'max': 1, 'default': 2}),
      'default',
    );
    cfgBad(
      'number default bool',
      cfgInput('number', {'default': true}),
      'default',
    );
    for (final bad in ['x', 'NaN', 'Infinity', '0x10', ' 5', '1e999', '']) {
      cfgBad(
        'number default string "$bad"',
        cfgInput('number', {'default': bad}),
        'default',
      );
    }
    cfgBad('integer min fractional', cfgInput('integer', {'min': 1.5}), 'min');
    cfgBad('integer step 0', cfgInput('integer', {'step': 0}), 'step');
    cfgBad(
      'integer step fractional',
      cfgInput('integer', {'step': 0.5}),
      'step',
    );
    cfgBad(
      'integer unsafe max',
      cfgInput('integer', {'max': 9007199254740992}),
      'max',
    );
    cfgBad(
      'integer unsafe default',
      cfgInput('integer', {'default': 9007199254740992}),
      'default',
    );
    cfgBad(
      'integer fractional default',
      cfgInput('integer', {'default': 1.5}),
      'default',
    );
    cfgBad(
      'integer default as string',
      cfgInput('integer', {'default': '5'}),
      'default',
    );
    cfgBad(
      'url default http',
      cfgInput('url', {'default': 'http://example.com'}),
      'default',
    );
    cfgBad(
      'url default with userinfo',
      cfgInput('url', {'default': 'https://u@example.com'}),
      'default',
    );
    cfgBad(
      'url default without host',
      cfgInput('url', {'default': 'https://'}),
      'default',
    );
  });
}
