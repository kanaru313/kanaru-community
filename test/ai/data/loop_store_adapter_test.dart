import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/data/loop_store_adapter.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/input/chat_input_builder.dart';
import 'package:kanaru/src/ai/domain/loop/loop_ports.dart';
import 'package:kanaru/src/database/database.dart';

import 'conversation_store_fixtures.dart';

const _binding = ChatBinding(
  installId: 'plug',
  installGeneration: 1,
  pluginVersion: 3,
  model: 'm1',
);

void main() {
  late AppDatabase db;
  late ConversationStore store;
  late LoopStoreAdapter adapter;
  late int chat;

  setUp(() async {
    db = openDb();
    store = ConversationStore(
      db,
      limits: const ConversationStoreLimits(partsJsonBytes: 2000),
    );
    adapter = LoopStoreAdapter(store);
    chat = (await newChat(store)).id;
  });
  tearDown(() async {
    store.dispose();
    await db.close();
  });

  test('beginRound appends only when the transcript has not moved', () async {
    await adapter.appendUser(chat, const [TextPart('hi')]);
    final revision = await store.latestSeq(chat);
    expect(revision, 1);

    final id = await adapter.beginRound(
      chat,
      expectedRevision: revision,
      binding: _binding,
    );
    expect(id, isNotNull);
    final stored = (await store.message(id!))!.message;
    expect(stored.state, AiMessageState.streaming);
    expect(stored.installId, 'plug');
    expect(stored.pluginVersion, 3);
    expect(stored.model, 'm1');

    // The same revision is stale now: a second round is refused.
    expect(
      await adapter.beginRound(
        chat,
        expectedRevision: revision,
        binding: _binding,
      ),
      isNull,
    );
    expect(await store.latestSeq(chat), 2);
  });

  test('two rounds racing for one revision: exactly one wins', () async {
    await adapter.appendUser(chat, const [TextPart('hi')]);
    final results = await Future.wait([
      for (var i = 0; i < 4; i++)
        adapter.beginRound(chat, expectedRevision: 1, binding: _binding),
    ]);
    expect(results.where((id) => id != null), hasLength(1));
    expect(await store.messages(chat), hasLength(2));
  });

  test('history carries the blob text of every row', () async {
    await adapter.appendUser(chat, const [TextPart('hi')]);
    final id = (await adapter.beginRound(
      chat,
      expectedRevision: 1,
      binding: _binding,
    ))!;
    await adapter.completeRound(
      id,
      parts: const [TextPart('yo')],
      blob: '{"b":1}',
    );
    final history = await adapter.history(chat);
    expect(history.map((r) => r.message.role), [
      AiMessageRole.user,
      AiMessageRole.assistant,
    ]);
    expect(history.last.providerJson, '{"b":1}');
  });

  test('completeRound returns null once the message left streaming', () async {
    await adapter.appendUser(chat, const [TextPart('hi')]);
    final id = (await adapter.beginRound(
      chat,
      expectedRevision: 1,
      binding: _binding,
    ))!;
    expect(await adapter.endRound(id, to: AiMessageState.stopped), isTrue);
    expect(
      await adapter.completeRound(id, parts: const [TextPart('x')]),
      isNull,
    );
    expect(await adapter.updateLiveText(id, 'late'), isFalse);
  });

  test('a row over the size cap throws LoopStoreTooLarge', () async {
    await adapter.appendUser(chat, const [TextPart('hi')]);
    final id = (await adapter.beginRound(
      chat,
      expectedRevision: 1,
      binding: _binding,
    ))!;
    await expectLater(
      adapter.completeRound(id, parts: [TextPart('x' * 5000)]),
      throwsA(isA<LoopStoreTooLarge>()),
    );
    expect((await store.message(id))!.message.state, AiMessageState.error);
  });

  test('transition stores the error code and kind only', () async {
    final round = await toolRound(store, chat, callId: 'c1');
    await adapter.transition(
      round.card,
      from: AiMessageState.allowed,
      to: AiMessageState.running,
    );
    await adapter.transition(
      round.card,
      from: AiMessageState.running,
      to: AiMessageState.error,
      error: const LoopError(code: 'limit_reached', kind: 'invalidResponse'),
    );
    final row = (await store.message(round.card))!;
    expect(row.error?.code, 'limit_reached');
    expect(row.error?.kind, 'invalidResponse');
  });

  test('stampPluginVersion updates the stored version', () async {
    final id = await addStreaming(store, chat);
    expect(await adapter.stampPluginVersion(id, 9), isTrue);
    expect((await store.message(id))!.message.pluginVersion, 9);
    expect(await adapter.stampPluginVersion(id + 100, 9), isFalse);
  });

  test('approve moves only a pending card', () async {
    final round = await toolRound(
      store,
      chat,
      callId: 'c1',
      needsConfirm: true,
    );
    expect(await adapter.approve(round.card), isTrue);
    expect(await adapter.approve(round.card), isFalse);
    final card = (await store.message(round.card))!.message;
    expect(card.state, AiMessageState.allowed);
    expect(
      card.parts.whereType<ConfirmPart>().single.status,
      ConfirmStatus.allowed,
    );
  });
}
