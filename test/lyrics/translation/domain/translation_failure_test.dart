import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';

void main() {
  test('failures compare by value', () {
    expect(const TranslationFailure.quota(), const TranslationFailure.quota());
    expect(
      const TranslationFailure.quota(),
      isNot(const TranslationFailure.badKey()),
    );
    expect(
      const TranslationFailure.needsConfig(['Key']),
      const TranslationFailure.needsConfig(['Key']),
    );
    expect(
      const TranslationFailure.needsConfig(['Key']),
      isNot(const TranslationFailure.needsConfig(['Model'])),
    );
    final t = DateTime(2026);
    expect(
      TranslationFailure.rateLimited(t),
      TranslationFailure.rateLimited(t),
    );
    expect(
      TranslationFailure.rateLimited(t),
      isNot(TranslationFailure.rateLimited(t.add(const Duration(seconds: 1)))),
    );
  });

  test('statuses compare by value', () {
    expect(
      const TranslationStatus.loading(1, 3),
      const TranslationStatus.loading(1, 3),
    );
    expect(
      const TranslationStatus.loading(1, 3),
      isNot(const TranslationStatus.loading(1, 3, background: true)),
    );
    expect(
      const TranslationStatus.other('a'),
      const TranslationStatus.other('a'),
    );
    expect(
      const TranslationStatus.same('en'),
      isNot(const TranslationStatus.same('vi')),
    );
    expect(
      const TranslationStatus.failed(TranslationFailure.network()),
      const TranslationStatus.failed(TranslationFailure.network()),
    );
    expect(
      const TranslationStatus.idle(),
      isNot(const TranslationStatus.ready()),
    );
  });
}
