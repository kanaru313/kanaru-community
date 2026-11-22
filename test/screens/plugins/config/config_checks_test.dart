import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/screens/plugins/config/config_checks.dart';

ConfigIssueKind? _kind(ConfigCheck c) => c.issue?.kind;

void main() {
  group('input text', () {
    const text = InputField(key: 'k', title: 'K', minLength: 3, maxLength: 5);
    test('whitespace only is cleared', () {
      expect(checkInputText(text, '   ').cleared, isTrue);
    });
    test('length bounds count code points', () {
      expect(_kind(checkInputText(text, 'ab')), ConfigIssueKind.tooShort);
      expect(_kind(checkInputText(text, 'abcdef')), ConfigIssueKind.tooLong);
      expect(checkInputText(text, 'abcd').value, 'abcd');
      // Five code points, two UTF-16 units each for the last.
      expect(checkInputText(text, 'abcd😀').ok, isTrue);
    });
    test('text keeps its spaces', () {
      expect(
        checkInputText(const InputField(key: 'k', title: 'K'), ' a b ').value,
        ' a b ',
      );
    });
  });

  group('numbers', () {
    const number = InputField(
      key: 'n',
      title: 'N',
      format: InputFormat.number,
      min: 0,
      max: 2,
    );
    const whole = InputField(key: 'i', title: 'I', format: InputFormat.integer);
    test('parse, range and kind', () {
      expect(checkInputText(number, '1.5').value, 1.5);
      expect(_kind(checkInputText(number, 'abc')), ConfigIssueKind.notNumber);
      expect(_kind(checkInputText(number, '-1')), ConfigIssueKind.belowMin);
      expect(_kind(checkInputText(number, '3')), ConfigIssueKind.aboveMax);
      expect(checkInputText(number, '3').issue!.n, 2);
      expect(checkInputText(whole, '7').value, 7);
      expect(_kind(checkInputText(whole, '1.5')), ConfigIssueKind.notInteger);
      expect(_kind(checkInputText(whole, 'x')), ConfigIssueKind.notInteger);
    });
    test('a number past the safe range is refused', () {
      expect(checkInputText(whole, '99999999999999999').ok, isFalse);
    });
    test('number text has no float noise or point', () {
      expect(configNumberText(0.1 + 0.2), '0.3');
      expect(configNumberText(2.0), '2');
      expect(configNumberText(7), '7');
    });
  });

  group('url', () {
    const url = InputField(key: 'u', title: 'U', format: InputFormat.url);
    test('https only, trimmed', () {
      expect(
        checkInputText(url, ' https://a.example.com/x ').value,
        'https://a.example.com/x',
      );
      expect(
        _kind(checkInputText(url, 'http://a.example.com')),
        ConfigIssueKind.badUrl,
      );
      expect(
        _kind(checkInputText(url, 'a.example.com')),
        ConfigIssueKind.badUrl,
      );
    });
  });

  group('list', () {
    const urls = ListField(
      key: 'l',
      title: 'L',
      format: ListFormat.url,
      maxItems: 2,
    );
    test('bad items are named by position', () {
      final check = checkList(urls, [
        'https://a.example.com',
        'http://b.example.com',
      ]);
      expect(check.bad, {1});
      expect(check.issue!.kind, ConfigIssueKind.badItem);
      expect(check.canSend, isFalse);
    });
    test('too many items blocks, empty required is shown but sent', () {
      expect(
        checkList(urls, [
          'https://a.example.com',
          'https://b.example.com',
          'https://c.example.com',
        ]).issue!.kind,
        ConfigIssueKind.tooManyItems,
      );
      final empty = checkList(
        const ListField(key: 'l', title: 'L', required: true),
        [],
      );
      expect(empty.issue!.kind, ConfigIssueKind.required);
      expect(empty.canSend, isTrue);
    });
    test('numbers become numbers', () {
      expect(
        checkList(
          const ListField(key: 'l', title: 'L', format: ListFormat.integer),
          ['1', '2'],
        ).value,
        [1, 2],
      );
    });
  });

  group('map', () {
    const map = MapField(key: 'm', title: 'M');
    test('names are checked, repeated ones named on the later row', () {
      final check = checkMap(map, [(' a', '1'), ('b', '2'), ('b', '3')]);
      expect(check.rowIssues[0]!.kind, ConfigIssueKind.badName);
      expect(check.rowIssues[2]!.kind, ConfigIssueKind.duplicateName);
      expect(check.canSend, isFalse);
    });
    test('a good table is a map', () {
      final check = checkMap(map, [('a', '1'), ('b', '')]);
      expect(check.canSend, isTrue);
      expect(check.value, {'a': '1', 'b': ''});
    });
  });

  test('chips: below the minimum blocks', () {
    const field = SelectField(
      key: 's',
      title: 'S',
      format: SelectFormat.multiple,
      minItems: 2,
    );
    expect(checkChoices(field, 1)!.blocks, isTrue);
    expect(checkChoices(field, 2), isNull);
  });
}
