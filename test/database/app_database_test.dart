import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('enables foreign keys on open', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
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

  test('schemaVersion is 1', () {
    expect(db.schemaVersion, 1);
  });
}
