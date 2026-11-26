import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/schema_guard.dart';

import 'support/test_db.dart';

Future<int> _conversation(AppDatabase db, {String title = 'Chat'}) async {
  await db.customStatement(
    'INSERT INTO ai_conversations '
    '(title, permission, created_at, updated_at, last_message_at) '
    "VALUES (?, 'ask', 1, 1, 1)",
    [title],
  );
  final rows = await db.customSelect('SELECT last_insert_rowid() AS id').get();
  return rows.single.read<int>('id');
}

Future<void> _message(AppDatabase db, int conversationId, int seq) {
  return db.customStatement(
    'INSERT INTO ai_messages '
    '(conversation_id, seq, role, parts_json, state, created_at) '
    "VALUES (?, ?, 'user', '[]', 'complete', 1)",
    [conversationId, seq],
  );
}

Future<int> _messageCount(AppDatabase db) async {
  final rows = await db
      .customSelect('SELECT COUNT(*) AS n FROM ai_messages')
      .get();
  return rows.single.read<int>('n');
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  test('deleting a conversation cascades its messages', () async {
    final a = await _conversation(db);
    final b = await _conversation(db, title: 'Other');
    await _message(db, a, 0);
    await _message(db, a, 1);
    await _message(db, b, 0);

    await db.customStatement('DELETE FROM ai_conversations WHERE id = ?', [a]);

    expect(await _messageCount(db), 1);
  });

  test('seq is unique per conversation', () async {
    final a = await _conversation(db);
    await _message(db, a, 0);
    await expectLater(_message(db, a, 0), throwsConstraint('UNIQUE'));
  });

  test('messages of two conversations may share seq', () async {
    final a = await _conversation(db);
    final b = await _conversation(db, title: 'Other');
    await _message(db, a, 0);
    await _message(db, b, 0);
    expect(await _messageCount(db), 2);
  });

  test('a message needs an existing conversation', () async {
    await expectLater(_message(db, 999, 0), throwsConstraint('FOREIGN KEY'));
  });

  test('fresh database passes the schema guard', () async {
    final dir = await Directory.systemTemp.createTemp('kanaru-ai-tables');
    addTearDown(() => dir.delete(recursive: true));
    final file = AppDatabase(NativeDatabase(File('${dir.path}/kanaru.db')));
    addTearDown(file.close);
    await file.openedConnection();

    await verifyDevSchema(
      file,
      openReference: () => AppDatabase(NativeDatabase.memory()),
    );
  });
}
