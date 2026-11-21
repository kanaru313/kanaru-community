import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/translate_spec.dart';

void main() {
  Map<String, Object?> block([Map<String, Object?> extra = const {}]) => {
    'languages': ['vi', 'en'],
    ...extra,
  };

  void expectField(Object? value, String field) {
    expect(
      () => readTranslateSpec(value),
      throwsA(
        isA<PackageProblemError>()
            .having((e) => e.problem, 'problem', isA<InvalidManifest>())
            .having((e) => e.problem.detail, 'detail', field),
      ),
    );
  }

  test('missing limits get the defaults', () {
    final spec = readTranslateSpec(block()).spec;
    expect(spec.languages, ['vi', 'en']);
    expect(spec.maxLines, 50);
    expect(spec.maxChars, 4000);
    expect(spec.timeoutSec, 15);
  });

  test('unknown and repeated language codes are dropped and counted', () {
    final parsed = readTranslateSpec({
      'languages': ['vi', 'xx', 'vi', 'ja'],
    });
    expect(parsed.spec.languages, ['vi', 'ja']);
    expect(parsed.droppedLanguages, 2);
  });

  test('Chinese scripts are known codes', () {
    expect(
      readTranslateSpec({
        'languages': ['zh-Hans', 'zh-Hant', 'zh'],
      }).spec.languages,
      ['zh-Hans', 'zh-Hant'],
    );
  });

  test('no usable language is refused', () {
    for (final languages in [
      <Object?>[],
      ['xx'],
      [1],
      'vi',
      List.filled(201, 'vi'),
    ]) {
      expectField({'languages': languages}, 'translate.languages');
    }
  });

  test('a block that is not an object is refused', () {
    expectField(null, 'translate');
    expectField('vi', 'translate');
  });

  test('timeout above the host cap is clamped, not refused', () {
    expect(readTranslateSpec(block({'timeoutSec': 200})).spec.timeoutSec, 90);
    expect(readTranslateSpec(block({'timeoutSec': 600})).spec.timeoutSec, 90);
  });

  test('values outside their bounds name the field', () {
    final cases = {
      'maxLines': [9, 201, '50'],
      'maxChars': [999, 20001],
      'timeoutSec': [0, 601],
    };
    cases.forEach((key, values) {
      for (final value in values) {
        expectField(block({key: value}), 'translate.$key');
      }
    });
  });

  test('bounds are accepted at the edges', () {
    final spec = readTranslateSpec(
      block({'maxLines': 10, 'maxChars': 20000, 'timeoutSec': 1}),
    ).spec;
    expect((spec.maxLines, spec.maxChars, spec.timeoutSec), (10, 20000, 1));
  });
}
