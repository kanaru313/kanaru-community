import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/foundation/app_logger.dart';
import 'package:logging/logging.dart';

import 'chat_harness.dart';

const _secret = 'SECRET-chat-text';

class _FailingStore extends ConversationStore {
  _FailingStore(super.db);

  @override
  Future<bool> hasUserMessage(int conversationId) async =>
      throw StateError(_secret);
}

void main() {
  late ChatHarness t;
  late List<LogRecord> records;
  late Level before;

  setUp(() async {
    before = Logger.root.level;
    Logger.root.level = Level.ALL;
    records = [];
    Logger.root.onRecord.listen(records.add);
    t = await ChatHarness.create(
      makeStore: (AppDatabase db) => _FailingStore(db),
    );
  });
  tearDown(() async {
    Logger.root.level = before;
    await t.dispose();
  });

  test('a failed send keeps the error text out of the release line', () async {
    final result = await t.session.send('hi');

    expect(result, isA<SendFailed>());
    final sendLogs = records.where((r) => r.message.startsWith('send failed'));
    final warning = sendLogs.singleWhere((r) => r.level == Level.WARNING);
    final printed = formatLogLine(warning, release: true);
    expect(printed, contains('StateError'));
    expect(printed, isNot(contains(_secret)));
    // The full text is only at FINE, which release does not print.
    final detail = sendLogs.singleWhere((r) => r.level == Level.FINE);
    expect(detail.message, contains(_secret));
  });
}
