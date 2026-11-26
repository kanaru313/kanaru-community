import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/tools/schema_validator.dart';
import 'package:kanaru/src/ai/domain/tools/tool_args.dart';

void main() {
  final schema = objectSchema(
    {
      'query': {'type': 'string'},
      'limit': limitProperty(50),
      'ids': {
        'type': 'array',
        'items': {'type': 'integer'},
        'maxItems': 3,
      },
      'range': {
        'type': 'string',
        'enum': ['a', 'b'],
      },
    },
    required: const ['query'],
  );

  test('accepts a valid object, null counts as absent', () {
    expect(
      validateAgainstSchema(schema, {'query': 'x', 'limit': 5, 'range': null}),
      isNull,
    );
  });

  test('rejects missing required, wrong types and unknown arguments', () {
    expect(validateAgainstSchema(schema, {}), contains('query'));
    expect(validateAgainstSchema(schema, {'query': 1}), contains('string'));
    expect(
      validateAgainstSchema(schema, {'query': 'x', 'extra': 1}),
      contains('unknown'),
    );
    expect(validateAgainstSchema(schema, 'text'), contains('object'));
  });

  test('range, enum, array size and item type', () {
    expect(
      validateAgainstSchema(schema, {'query': 'x', 'limit': 51}),
      contains('at most 50'),
    );
    expect(
      validateAgainstSchema(schema, {'query': 'x', 'limit': 0}),
      contains('at least 1'),
    );
    expect(
      validateAgainstSchema(schema, {'query': 'x', 'limit': 1.5}),
      contains('integer'),
    );
    expect(
      validateAgainstSchema(schema, {'query': 'x', 'range': 'c'}),
      contains('one of'),
    );
    expect(
      validateAgainstSchema(schema, {
        'query': 'x',
        'ids': [1, 2, 3, 4],
      }),
      contains('at most 3'),
    );
    expect(
      validateAgainstSchema(schema, {
        'query': 'x',
        'ids': [1, 'a'],
      }),
      contains(r'ids[1]'),
    );
  });
}
