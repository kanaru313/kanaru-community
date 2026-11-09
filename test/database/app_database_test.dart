import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  Future<int> pragma(AppDatabase d, String name) async =>
      (await d.customSelect('PRAGMA $name').getSingle()).read<int>(name);

  test('enables foreign keys and recursive triggers on the test helper', () async {
    expect(await pragma(db, 'foreign_keys'), 1);
    expect(await pragma(db, 'recursive_triggers'), 1);
  });

  test('creates extension_schema and stores a version', () async {
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(tables.map((r) => r.read<String>('name')), contains('extension_schema'));

    await db.into(db.extensionSchema).insert(
          ExtensionSchemaCompanion.insert(extensionId: 'pro', version: 3),
        );
    final stored = await db.select(db.extensionSchema).getSingle();
    expect(stored.extensionId, 'pro');
    expect(stored.version, 3);
  });

  group('file database', () {
    late Directory dir;
    late File file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('kanaru_db_');
      file = File('${dir.path}/kanaru.db');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('enables both pragmas on AppDatabase.file', () async {
      final d = AppDatabase.file(file);
      addTearDown(d.close);
      expect(await pragma(d, 'foreign_keys'), 1);
      expect(await pragma(d, 'recursive_triggers'), 1);
    });

    test('reopening keeps data and passes the schema guard', () async {
      final first = AppDatabase.file(file);
      await first.into(first.extensionSchema).insert(
            ExtensionSchemaCompanion.insert(extensionId: 'pro', version: 2),
          );
      await first.close();

      final second = AppDatabase.file(file);
      addTearDown(second.close);
      final stored = await second.select(second.extensionSchema).getSingle();
      expect(stored.version, 2);
    });

    test('the guard names an index dropped from an older file', () async {
      final first = AppDatabase.file(file);
      await first.customStatement('DROP INDEX tracks_song_key');
      await first.close();

      final second = AppDatabase.file(file);
      addTearDown(second.close);
      await expectLater(
        second.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('delete it'), contains('index:tracks_song_key')),
        )),
      );
    });

    test('the guard names a stale trigger on a public table', () async {
      final first = AppDatabase.file(file);
      await first.customStatement(
          'CREATE TRIGGER stale_tr AFTER INSERT ON tracks BEGIN SELECT 1; END');
      await first.close();

      final second = AppDatabase.file(file);
      addTearDown(second.close);
      await expectLater(
        second.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            allOf(contains('extra trigger:stale_tr'), contains(file.path)))),
      );
    });

    test('the guard ignores tables added by an extension', () async {
      final first = AppDatabase.file(file);
      await first.customStatement('CREATE TABLE pro_extra (id INTEGER PRIMARY KEY)');
      await first.close();

      final second = AppDatabase.file(file);
      addTearDown(second.close);
      await second.customSelect('SELECT 1').get();
    });
  });
}
