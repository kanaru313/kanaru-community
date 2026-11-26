import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_conversation.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/conversation/parts_codec.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/state/ai_chat_stats_provider.dart';
import 'package:kanaru/src/ai/state/ai_conversation_store_provider.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';

import 'conversation_store_fixtures.dart';

void main() {
  late AppDatabase db;
  late ConversationStore store;

  setUp(() {
    db = openDb();
    store = ConversationStore(db);
  });
  tearDown(() async {
    store.dispose();
    await db.close();
  });

  test('append assigns increasing seq under concurrent appends', () async {
    final chat = await newChat(store);
    final made = await Future.wait([
      for (var i = 0; i < 20; i++) addUser(store, chat.id, 'm$i'),
    ]);
    expect(made.toSet(), hasLength(20));
    final seqs = [
      for (final m in await store.messages(chat.id, limit: 100)) m.message.seq,
    ];
    expect(seqs, [for (var i = 1; i <= 20; i++) i]);
  });

  test('append over the row cap writes nothing and throws', () async {
    final chat = await newChat(store);
    await expectLater(
      store.append(
        NewAiMessage(
          conversationId: chat.id,
          role: AiMessageRole.user,
          parts: [TextPart('x' * (1024 * 1024 + 1))],
        ),
      ),
      throwsA(isA<AiStoreTooLarge>()),
    );
    expect(await store.messages(chat.id), isEmpty);
  });

  test('list orders by last message and rename stops auto titles', () async {
    var now = 1000;
    store = ConversationStore(db, clock: () => now++);
    final a = await newChat(store, title: 'A');
    final b = await newChat(store, title: 'B');
    await addUser(store, a.id);
    expect([for (final c in await store.list()) c.title], ['A', 'B']);
    expect(await store.setAutoTitle(b.id, 'Generated'), isTrue);
    await store.rename(b.id, 'Mine');
    expect(await store.setAutoTitle(b.id, 'Again'), isFalse);
    final got = (await store.conversation(b.id))!;
    expect(got.title, 'Mine');
    expect(got.titleAuto, isFalse);
  });

  test('deleteAll removes conversations and messages', () async {
    final a = await newChat(store);
    final b = await newChat(store);
    await addUser(store, a.id);
    await addUser(store, b.id);
    await store.deleteAll();
    expect(await store.list(), isEmpty);
    expect(await db.select(db.aiMessages).get(), isEmpty);
  });

  test('delete removes one conversation and its messages only', () async {
    final a = await newChat(store);
    final b = await newChat(store);
    await addUser(store, a.id);
    await addUser(store, b.id);
    await store.delete(a.id);
    expect([for (final c in await store.list()) c.id], [b.id]);
    expect(await db.select(db.aiMessages).get(), hasLength(1));
  });

  test('search matches title and text', () async {
    final a = await newChat(store, title: 'Nhạc buồn');
    final b = await newChat(store, title: 'Other');
    final c = await newChat(store, title: 'Third');
    await addUser(store, b.id, 'Tìm bài về MÙA ĐÔNG');
    await store.append(
      NewAiMessage(
        conversationId: c.id,
        role: AiMessageRole.assistant,
        state: AiMessageState.streaming,
        liveText: 'Winter is coming',
      ),
    );
    Set<int> ids(List<AiConversation> l) => {for (final x in l) x.id};
    expect(ids(await store.search('buồn')), {a.id});
    expect(ids(await store.search('mùa đông')), {b.id});
    expect(ids(await store.search('WINTER')), {c.id});
    expect(await store.search('absent'), isEmpty);
    expect(await store.search('  '), isEmpty);
  });

  test('search ignores json syntax and tool rows', () async {
    final a = await newChat(store);
    await addUser(store, a.id, 'hello');
    expect(await store.search('tool_call'), isEmpty);
    expect(await store.search('"t"'), isEmpty);
  });

  test('paged read returns one page before seq', () async {
    final chat = await newChat(store);
    for (var i = 0; i < 120; i++) {
      await addUser(store, chat.id, 'm$i');
    }
    final last = await store.messages(chat.id, limit: 50);
    expect([last.first.message.seq, last.last.message.seq], [71, 120]);
    final before = await store.messages(
      chat.id,
      beforeSeq: last.first.message.seq,
      limit: 50,
    );
    expect([before.first.message.seq, before.last.message.seq], [21, 70]);
    final first = await store.messages(chat.id, beforeSeq: 21, limit: 50);
    expect(first, hasLength(20));
  });

  test('stats counts bytes and refreshes on delete', () async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final s = container.read(aiConversationStoreProvider);
    container.listen(aiChatStatsProvider, (_, _) {});

    final chat = await s.create(title: 'T', permission: AiPermission.auto);
    final parts = encodeParts(const [TextPart('héllo')]);
    await s.append(
      NewAiMessage(
        conversationId: chat.id,
        role: AiMessageRole.assistant,
        state: AiMessageState.streaming,
        parts: const [TextPart('héllo')],
        liveText: 'tạ',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    var stats = await container.read(aiChatStatsProvider.future);
    expect(stats.conversations, 1);
    // parts JSON + live text, counted in UTF-8 bytes ('ạ' is 3 bytes).
    expect(stats.bytes, utf8Size(parts) + utf8Size('tạ'));

    await s.delete(chat.id);
    await Future<void>.delayed(Duration.zero);
    stats = await container.read(aiChatStatsProvider.future);
    expect((stats.conversations, stats.bytes), (0, 0));
  });
}
