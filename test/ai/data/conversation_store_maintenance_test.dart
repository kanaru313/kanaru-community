import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/database/database.dart';

import 'conversation_store_fixtures.dart';

void main() {
  late AppDatabase db;
  late ConversationStore store;
  late int chat;

  setUp(() async {
    db = openDb();
    store = ConversationStore(db);
    chat = (await newChat(store)).id;
  });
  tearDown(() async {
    store.dispose();
    await db.close();
  });

  Future<List<StoredMessage>> all() => store.messages(chat, limit: 1000);

  /// A turn with one tool round (blob [blob]) and a closing text answer.
  Future<int> turnWithTools(
    String tag, {
    String blob = '{"b":1}',
    String install = 'plug',
  }) async {
    final u = await addUser(store, chat, 'q-$tag');
    final round = await toolRound(
      store,
      chat,
      callId: 'c-$tag',
      blob: blob,
      install: install,
    );
    await finishCard(store, round.card, 'c-$tag');
    final end = await addStreaming(store, chat, install: install);
    await store.completeRound(
      messageId: end,
      finalParts: [TextPart('answer-$tag')],
      blob: '{"end":1}',
    );
    return u;
  }

  group('startup sweep', () {
    test('running row becomes unknown', () async {
      final r = await toolRound(store, chat, callId: 'c');
      await store.transition(
        r.card,
        from: AiMessageState.allowed,
        to: AiMessageState.running,
      );
      final sweep = await store.sweepAfterCrash();
      expect(sweep.unknown, 1);
      expect(
        (await store.message(r.card))!.message.state,
        AiMessageState.unknown,
      );
    });

    test('keeps provider blobs and leaves unanswered cards alone', () async {
      final r = await toolRound(
        store,
        chat,
        callId: 'c',
        blob: '{"keep":1}',
        needsConfirm: true,
      );
      await store.sweepAfterCrash();
      expect((await store.message(r.assistant))!.providerJson, '{"keep":1}');
      expect(
        (await store.message(r.card))!.message.state,
        AiMessageState.pending,
      );
    });

    test(
      'streaming row becomes stopped and keeps truncated live text',
      () async {
        final a = await addStreaming(store, chat, live: 'short');
        final big = await addStreaming(store, chat);
        // Written by a build with a larger cap: the sweep cuts it.
        await (db.update(db.aiMessages)..where((m) => m.id.equals(big))).write(
          AiMessagesCompanion(liveText: Value('z' * (300 * 1024))),
        );
        final sweep = await store.sweepAfterCrash();
        expect(sweep.stopped, 2);
        final m = (await store.message(a))!;
        expect(m.message.state, AiMessageState.stopped);
        expect(m.message.liveText, 'short');
        expect(m.message.parts, [
          const ErrorPart(code: cutOffByCloseCode, kind: 'closed'),
        ]);
        final b = (await store.message(big))!;
        expect(b.liveTextTruncated, isTrue);
        expect(b.message.liveText!.length, lessThanOrEqualTo(256 * 1024));
      },
    );

    test('a second sweep changes nothing', () async {
      await addStreaming(store, chat, live: 'x');
      await store.sweepAfterCrash();
      final again = await store.sweepAfterCrash();
      expect((again.stopped, again.unknown), (0, 0));
    });
  });

  group('flattening', () {
    test('blob over 256 KiB flattens its turn at turn end', () async {
      final u = await addUser(store, chat);
      final round = await toolRound(
        store,
        chat,
        callId: 'c',
        blob: 'b' * (256 * 1024 + 1),
      );
      await finishCard(store, round.card, 'c');
      final end = await addStreaming(store, chat);
      await store.completeRound(
        messageId: end,
        finalParts: const [TextPart('final')],
      );

      expect(await store.endTurn(u), isTrue);
      final rows = await all();
      expect(
        [for (final m in rows) m.message.role],
        [AiMessageRole.user, AiMessageRole.assistant, AiMessageRole.assistant],
      );
      expect(rows[1].message.parts, [const TextPart('t-c')]);
      expect(rows[2].message.parts, [const TextPart('final')]);
      expect(rows.every((m) => m.providerJson == null), isTrue);
    });

    test('a normal turn is not flattened at turn end', () async {
      final u = await turnWithTools('a');
      expect(await store.endTurn(u), isFalse);
      expect(
        (await all()).any((m) => m.message.role == AiMessageRole.tool),
        isTrue,
      );
    });

    test(
      'conversation over 4 MiB of blobs flattens oldest turns atomically',
      () async {
        final turns = <int>[];
        // 17 turns of 250 KiB blobs: the last one pushes the total over 4 MiB.
        for (var i = 0; i < 17; i++) {
          turns.add(await turnWithTools('t$i', blob: 'x' * (250 * 1024)));
        }
        final rows = await all();
        bool flat(int turn) {
          final idx = rows.indexWhere((m) => m.message.id == turn);
          var j = idx + 1;
          while (j < rows.length &&
              rows[j].message.role != AiMessageRole.user) {
            final m = rows[j];
            if (m.message.role == AiMessageRole.tool ||
                m.message.parts.any((p) => p is ToolCallPart) ||
                m.providerJson != null) {
              return false;
            }
            j++;
          }
          return true;
        }

        expect(flat(turns.first), isTrue);
        expect(flat(turns.last), isFalse);
        // Only as many turns as needed: the second turn is still whole.
        expect(flat(turns[1]), isFalse);
        final bytes = rows.fold<int>(
          0,
          (s, m) => s + (m.providerJson?.length ?? 0),
        );
        expect(bytes, lessThanOrEqualTo(4 * 1024 * 1024));
        // The flattened turn keeps its text.
        expect(
          rows.any(
            (m) => m.message.parts.contains(const TextPart('answer-t0')),
          ),
          isTrue,
        );
      },
    );

    test('flattened turn keeps no tool call without its blob', () async {
      final u = await turnWithTools('a');
      await turnWithTools('b');
      expect(await store.flattenTurn(u), isTrue);
      final rows = await all();
      for (final m in rows) {
        if (m.message.role == AiMessageRole.assistant &&
            m.message.parts.any((p) => p is ToolCallPart)) {
          expect(m.providerJson, isNotNull, reason: 'call kept only with blob');
        }
      }
      // Turn a: text kept, calls, results and blobs gone.
      final a = rows
          .where((m) => m.message.role == AiMessageRole.assistant)
          .first;
      expect(a.message.parts, [const TextPart('t-c-a')]);
      expect(a.providerJson, isNull);
      // Turn b is untouched: its tool row is the only one left.
      expect(
        rows.where((m) => m.message.role == AiMessageRole.tool),
        hasLength(1),
      );
    });

    test('a running turn is not flattened', () async {
      final u = await addUser(store, chat);
      await toolRound(store, chat, callId: 'c', needsConfirm: true);
      expect(await store.flattenTurn(u), isFalse);
      expect(
        (await all()).any((m) => m.message.role == AiMessageRole.tool),
        isTrue,
      );
    });

    test('only a user message opens a turn', () async {
      final a = await addStreaming(store, chat);
      expect(await store.flattenTurn(a), isFalse);
      expect(await store.turnIdOf(a), isNull);
    });

    test(
      'clearProviderBlobs flattens the turns of that install only',
      () async {
        await turnWithTools('a', install: 'old');
        await turnWithTools('b', install: 'other');
        expect(await store.clearProviderBlobs(installId: 'old'), 1);
        final rows = await all();
        expect(
          rows.where((m) => m.providerJson != null),
          hasLength(2),
          reason: 'the other install keeps its blobs',
        );
        expect(
          rows.where(
            (m) => m.message.installId == 'old' && m.providerJson != null,
          ),
          isEmpty,
        );
        expect(
          rows.where((m) => m.message.role == AiMessageRole.tool),
          hasLength(1),
        );
      },
    );
  });
}
