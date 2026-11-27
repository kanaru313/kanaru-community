import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/data/contract/autocomplete_reader.dart';
import 'package:kanaru/src/online/domain/contract/online_output_exception.dart';

List<String> read(Object? v) => readAutocompleteOutput(jsonEncode(v));

void main() {
  test('reads an array', () {
    expect(read(['shape', 'blinding']), ['shape', 'blinding']);
  });

  test('an object is refused', () {
    expect(
      () => read({
        'suggestions': ['a'],
      }),
      throwsA(isA<OnlineOutputException>()),
    );
    expect(
      () => readAutocompleteOutput('nope'),
      throwsA(isA<OnlineOutputException>()),
    );
  });

  test('keeps the first 10', () {
    expect(read([for (var i = 0; i < 11; i++) 's$i']), hasLength(10));
  });

  test('drops duplicates, non-strings and empty', () {
    expect(read(['a', 'a', 1, null, '', ' ', 'b']), ['a', 'b']);
  });

  test('skips over-long entries', () {
    expect(read(['a' * 201, 'a' * 200]), ['a' * 200]);
  });

  test('cleans control characters', () {
    expect(read(['\u202Ehel\u200Blo\u0000']), ['hello']);
  });
}
