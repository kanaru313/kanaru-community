import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';

import 'support/test_db.dart';

Future<void> _insertTranslation(
  AppDatabase db, {
  String lang = 'vi',
  String lines = '{}',
  int complete = 0,
  String hash = 'h1',
  String install = 'plugin-a',
}) => db.customStatement(
  'INSERT INTO lyrics_translations (content_hash, install_id, target_lang, '
  'lines_json, settings_json, complete, created_at) VALUES (?, ?, ?, ?, ?, ?, 1)',
  [hash, install, lang, lines, '{}', complete],
);

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  test('the cache row needs no track and no plugin row', () async {
    await _insertTranslation(db);
    expect(
      await db.customSelect('SELECT 1 FROM lyrics_translations').get(),
      hasLength(1),
    );
  });

  test('the primary key is hash, plugin and language', () async {
    await _insertTranslation(db);
    await _insertTranslation(db, lang: 'en');
    await _insertTranslation(db, install: 'plugin-b');
    await expectLater(_insertTranslation(db), throwsConstraint('UNIQUE'));
  });

  test('the target language must have the shape of a code', () async {
    await expectLater(
      _insertTranslation(db, lang: 'v'),
      throwsConstraint('CHECK'),
    );
    await expectLater(
      _insertTranslation(db, lang: 'abcdefgh'),
      throwsConstraint('CHECK'),
    );
    await _insertTranslation(db, lang: 'zh-Hans');
  });

  test('complete is 0 or 1 and lines_json is capped at 2 MiB', () async {
    await expectLater(
      _insertTranslation(db, complete: 2),
      throwsConstraint('CHECK'),
    );
    await _insertTranslation(
      db,
      lines: 'x' * TranslationLimits.maxLinesJsonLength,
    );
    await expectLater(
      _insertTranslation(
        db,
        hash: 'h2',
        lines: 'x' * (TranslationLimits.maxLinesJsonLength + 1),
      ),
      throwsConstraint('CHECK'),
    );
  });

  test('the prefs row refuses a bad code shape and an unknown track', () async {
    final source = await addSource(db);
    final track = await addTrack(db, source, locator: 'a');
    await expectLater(
      db.customStatement(
        "INSERT INTO track_translation_prefs (track_id, target_lang, updated_at) VALUES (?, 'x', 1)",
        [track],
      ),
      throwsConstraint('CHECK'),
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO track_translation_prefs (track_id, target_lang, updated_at) VALUES (999, 'vi', 1)",
      ),
      throwsConstraint('FOREIGN KEY'),
    );
  });
}
