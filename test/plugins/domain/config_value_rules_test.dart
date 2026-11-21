import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/config/config_number_text.dart';
import 'package:kanaru/src/plugins/domain/config/config_required.dart';
import 'package:kanaru/src/plugins/domain/config/config_value_rules.dart';

InputField _input(
  InputFormat format, {
  int? minLength,
  int? maxLength,
  num? min,
  num? max,
}) => InputField(
  key: 'k',
  title: 'K',
  format: format,
  minLength: minLength,
  maxLength: maxLength,
  min: min,
  max: max,
);

ListField _list(ListFormat format, {int? minItems, int? maxItems}) => ListField(
  key: 'k',
  title: 'K',
  format: format,
  minItems: minItems,
  maxItems: maxItems,
);

const _opts = [
  ConfigOption(value: 'a', title: 'A'),
  ConfigOption(value: 'b', title: 'B'),
  ConfigOption(value: 'c', title: 'C'),
];

const _map = MapField(key: 'k', title: 'K', maxItems: 2);

/// A zero-width space (a format character), spelled out so it stays visible.
final _zwsp = String.fromCharCode(0x200b);

void main() {
  void expectProblem(ConfigField f, Object? value, ValueProblem? problem) =>
      expect(valueProblem(f, value), problem, reason: '$value');

  test('valueFits is "no problem"', () {
    expect(valueFits(_input(InputFormat.text), 'a'), isTrue);
    expect(valueFits(_input(InputFormat.text), 1), isFalse);
  });

  group('text', () {
    final f = _input(InputFormat.text, minLength: 2, maxLength: 4);

    test('lengths count code points', () {
      expectProblem(f, 'ab', null);
      expectProblem(f, '😀😀', null);
      expectProblem(f, 'a', ValueProblem.tooShort);
      expectProblem(f, '😀' * 5, ValueProblem.tooLong);
      expectProblem(f, 1, ValueProblem.wrongType);
    });

    test('the default cap is 2000', () {
      final plain = _input(InputFormat.multiline);
      expectProblem(plain, 'x' * 2000, null);
      expectProblem(plain, 'x' * 2001, ValueProblem.tooLong);
    });
  });

  group('numbers', () {
    final n = _input(InputFormat.number, min: -1, max: 10);
    final i = _input(InputFormat.integer, min: 0, max: 10);

    test('number', () {
      expectProblem(n, 2.5, null);
      expectProblem(n, -2, ValueProblem.belowMin);
      expectProblem(n, 11, ValueProblem.aboveMax);
      expectProblem(n, double.nan, ValueProblem.wrongType);
      expectProblem(n, double.infinity, ValueProblem.wrongType);
      expectProblem(n, true, ValueProblem.wrongType);
    });

    test('integer', () {
      final free = _input(InputFormat.integer);
      expectProblem(i, 3, null);
      expectProblem(i, 3.5, ValueProblem.notInteger);
      expectProblem(i, 3.0, ValueProblem.notInteger);
      expectProblem(i, -1, ValueProblem.belowMin);
      expectProblem(free, 9007199254740992, ValueProblem.aboveMax);
      expectProblem(free, -9007199254740992, ValueProblem.belowMin);
      expectProblem(free, 9007199254740991, null);
    });

    test('text is never read as a number', () {
      expectProblem(n, '2.5', ValueProblem.wrongType);
      expectProblem(n, 'x', ValueProblem.wrongType);
      expectProblem(i, '3', ValueProblem.wrongType);
    });
  });

  group('url', () {
    final f = _input(InputFormat.url);

    test('https with a host only', () {
      expectProblem(f, 'https://example.com:8443/a?b=1', null);
      expectProblem(f, 'HTTPS://example.com', null);
      expectProblem(f, 'http://example.com', ValueProblem.badUrl);
      expectProblem(f, 'ftp://example.com', ValueProblem.badUrl);
      expectProblem(f, 'https://', ValueProblem.badUrl);
      expectProblem(f, 'https://u:p@example.com', ValueProblem.badUrl);
      expectProblem(f, 'https://exa mple.com', ValueProblem.badUrl);
      expectProblem(f, 'https://@example.com', ValueProblem.badUrl);
      expectProblem(f, 'https://exam${_zwsp}ple.com', ValueProblem.badUrl);
      expectProblem(f, 'example.com', ValueProblem.badUrl);
      expectProblem(f, 'https://a.io/${'x' * 2000}', ValueProblem.tooLong);
    });

    test('an @ after the authority is not user info', () {
      for (final url in [
        'https://medium.com/@user',
        'https://host?x=@y',
        'https://host#@y',
      ]) {
        expect(urlProblem(url), isNull, reason: url);
      }
      for (final url in ['https://user@host', 'https://@host']) {
        expect(urlProblem(url), ValueProblem.badUrl, reason: url);
      }
    });
  });

  group('select', () {
    test('single', () {
      const f = SelectField(key: 'k', title: 'K', options: _opts);
      expectProblem(f, 'a', null);
      expectProblem(f, 'z', ValueProblem.notOption);
      expectProblem(f, 1, ValueProblem.wrongType);
    });

    test('multiple', () {
      const f = SelectField(
        key: 'k',
        title: 'K',
        format: SelectFormat.multiple,
        options: _opts,
        minItems: 1,
        maxItems: 2,
      );
      expectProblem(f, <dynamic>['a', 'b'], null);
      expectProblem(f, <String>[], ValueProblem.tooFewItems);
      expectProblem(f, ['a', 'b', 'c'], ValueProblem.tooManyItems);
      expectProblem(f, ['z'], ValueProblem.notOption);
      expectProblem(f, ['a', 'a'], ValueProblem.badItem);
      expectProblem(f, [1], ValueProblem.badItem);
      expectProblem(f, 'a', ValueProblem.wrongType);
    });
  });

  test('toggle', () {
    const f = ToggleField(key: 'k', title: 'K');
    expectProblem(f, false, null);
    expectProblem(f, 'true', ValueProblem.wrongType);
  });

  group('list', () {
    test('text items are non-empty and short', () {
      final f = _list(ListFormat.text, minItems: 1, maxItems: 2);
      expectProblem(f, <dynamic>['a', 'b'], null);
      expectProblem(f, <String>[], ValueProblem.tooFewItems);
      expectProblem(f, ['a', 'b', 'c'], ValueProblem.tooManyItems);
      expectProblem(f, [''], ValueProblem.badItem);
      expectProblem(f, ['  '], ValueProblem.badItem);
      expectProblem(f, ['x' * 2001], ValueProblem.badItem);
      expectProblem(f, [1], ValueProblem.badItem);
      expectProblem(f, 'a', ValueProblem.wrongType);
    });

    test('50 items pass and 51 do not', () {
      final f = _list(ListFormat.text);
      expectProblem(f, List.filled(50, 'a'), null);
      expectProblem(f, List.filled(51, 'a'), ValueProblem.tooManyItems);
    });

    test('number and integer items', () {
      final n = _list(ListFormat.number);
      expectProblem(n, [1, 2.5], null);
      expectProblem(n, ['1'], ValueProblem.badItem);
      expectProblem(n, [double.nan], ValueProblem.badItem);
      final i = _list(ListFormat.integer);
      expectProblem(i, [1, 2], null);
      expectProblem(i, [1.5], ValueProblem.badItem);
      expectProblem(i, [9007199254740992], ValueProblem.badItem);
    });

    test('url items', () {
      final f = _list(ListFormat.url);
      expectProblem(f, ['https://a.io'], null);
      expectProblem(f, ['http://a.io'], ValueProblem.badItem);
    });
  });

  group('map', () {
    test('keys and values', () {
      expectProblem(_map, <String, dynamic>{'a': 'x', 'b': ''}, null);
      expectProblem(_map, {'': 'x'}, ValueProblem.badKey);
      expectProblem(_map, {'k' * 101: 'x'}, ValueProblem.badKey);
      expectProblem(_map, {'k' * 100: 'x'}, null);
      expectProblem(_map, {' a': 'x'}, ValueProblem.badKey);
      expectProblem(_map, {'a ': 'x'}, ValueProblem.badKey);
      expectProblem(_map, {'a\u0000': 'x'}, ValueProblem.badKey);
      expectProblem(_map, {'a$_zwsp': 'x'}, ValueProblem.badKey);
      expectProblem(_map, {'__proto__': 'x'}, ValueProblem.badKey);
      expectProblem(_map, {'a': 1}, ValueProblem.badItem);
      expectProblem(_map, {'a': 'x' * 2001}, ValueProblem.badItem);
      expectProblem(_map, ['a'], ValueProblem.wrongType);
    });

    test('keys are case sensitive and counted', () {
      expectProblem(_map, {'a': '1', 'A': '2'}, null);
      expectProblem(_map, {
        'a': '1',
        'b': '2',
        'c': '3',
      }, ValueProblem.tooManyItems);
      expectProblem(const MapField(key: 'k', title: 'K'), {
        for (var i = 0; i < 51; i++) 'k$i': 'v',
      }, ValueProblem.tooManyItems);
    });

    test('key validity helper agrees', () {
      expect(mapKeyIsValid('ok'), isTrue);
      expect(mapKeyIsValid('__proto__'), isFalse);
      expect(mapKeyIsValid(' x'), isFalse);
    });
  });

  group('parseNumberText', () {
    const accepted = {
      '0': 0,
      '-1': -1,
      '1.5': 1.5,
      '1e5': 1e5,
      '1E-3': 1e-3,
      '-2.5e+3': -2500,
    };
    accepted.forEach((text, value) {
      test('accepts $text', () => expect(parseNumberText(text), value));
    });
    for (final text in [
      '+5',
      '.5',
      '5.',
      '0x10',
      ' 1',
      '1 ',
      '1\n',
      'Infinity',
      'NaN',
      '',
      '-',
      '1e',
      '1e+',
      '--1',
      '1.2.3',
      '1e400',
      '١٢',
    ]) {
      test('rejects "$text"', () => expect(parseNumberText(text), isNull));
    }

    test('whole mode takes integers only', () {
      expect(parseNumberText('12', whole: true), 12);
      expect(parseNumberText('-7', whole: true), -7);
      expect(parseNumberText('1.5', whole: true), isNull);
    });

    test('a very long near-miss returns quickly', () {
      final text = '${'1' * 100000}x';
      final watch = Stopwatch()..start();
      expect(parseNumberText(text), isNull);
      expect(watch.elapsedMilliseconds, lessThan(500));
    });
  });

  group('missingRequiredConfig', () {
    ConfigField field(String key, {bool required = true}) =>
        InputField(key: key, title: key, required: required);
    const toggle = ToggleField(key: 't', title: 't', required: true);

    test('an absent required value is missing', () {
      final f = field('a');
      expect(missingRequiredConfig([f], const {}), [f]);
    });

    test('empty string, list and map are missing', () {
      const fields = <ConfigField>[
        InputField(key: 's', title: 's', required: true),
        ListField(key: 'l', title: 'l', required: true),
        MapField(key: 'm', title: 'm', required: true),
      ];
      final missing = missingRequiredConfig(fields, {
        's': '',
        'l': <String>[],
        'm': <String, String>{},
      });
      expect(missing.map((f) => f.key), ['s', 'l', 'm']);
    });

    test('a value, a number zero and a filled collection are present', () {
      const fields = <ConfigField>[
        InputField(key: 's', title: 's', required: true),
        InputField(key: 'n', title: 'n', required: true),
        ListField(key: 'l', title: 'l', required: true),
      ];
      expect(
        missingRequiredConfig(fields, {
          's': 'x',
          'n': 0,
          'l': ['a'],
        }),
        isEmpty,
      );
    });

    test('a toggle is never missing', () {
      expect(missingRequiredConfig([toggle], const {}), isEmpty);
      expect(missingRequiredConfig([toggle], {'t': false}), isEmpty);
    });

    test('an optional field is never missing', () {
      expect(
        missingRequiredConfig([field('a', required: false)], const {}),
        isEmpty,
      );
    });

    test('whitespace-only text is missing, text around spaces is not', () {
      final f = field('t');
      expect(missingRequiredConfig([f], {'t': '  \n'}), [f]);
      expect(missingRequiredConfig([f], {'t': ' x '}), isEmpty);
    });
  });
}
