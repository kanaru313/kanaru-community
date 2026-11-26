import 'dart:convert';

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

  Future<AiMessageRow> row(int id) =>
      (db.select(db.aiMessages)..where((m) => m.id.equals(id))).getSingle();

  group('completeRound', () {
    test(
      'inserts cards and completes the message in one transaction',
      () async {
        await addUser(store, chat);
        final a = await addStreaming(store, chat, live: 'partial');
        final r = await store.completeRound(
          messageId: a,
          finalParts: [const TextPart('done'), call('c1'), call('c2')],
          blob: '{"sig":1}',
          calls: [
            ToolCardDraft(call: call('c1'), needsConfirm: true),
            ToolCardDraft(call: call('c2'), needsConfirm: false),
          ],
        );
        expect(r.won, isTrue);
        expect(r.cardIds, hasLength(2));
        final msg = await row(a);
        expect(msg.state, 'complete');
        expect(msg.liveText, isNull);
        expect(msg.providerJson, '{"sig":1}');
        final ask = (await store.message(r.cardIds[0]))!;
        final auto = (await store.message(r.cardIds[1]))!;
        expect(ask.message.state, AiMessageState.pending);
        expect(ask.message.role, AiMessageRole.tool);
        expect(ask.message.parts, [
          call('c1'),
          const ConfirmPart(callId: 'c1', status: ConfirmStatus.pending),
        ]);
        expect(auto.message.state, AiMessageState.allowed);
        expect(auto.message.parts, [call('c2')]);
        expect(auto.message.seq, ask.message.seq + 1);
      },
    );

    test('a second completeRound on the same message is lost', () async {
      final a = await addStreaming(store, chat);
      await store.completeRound(
        messageId: a,
        finalParts: const [TextPart('1')],
      );
      final again = await store.completeRound(
        messageId: a,
        finalParts: const [TextPart('2')],
        calls: [ToolCardDraft(call: call('c'), needsConfirm: false)],
      );
      expect(again.won, isFalse);
      expect((await store.message(a))!.message.parts, [const TextPart('1')]);
      expect(await store.messages(chat), hasLength(1));
    });

    test('kill after completeRound, before any tool: cards present, nothing running', () async {
      final a = await addStreaming(store, chat);
      await store.completeRound(
        messageId: a,
        finalParts: [call('c1')],
        blob: '{"b":1}',
        calls: [ToolCardDraft(call: call('c1'), needsConfirm: false)],
      );
      final sweep = await store.sweepAfterCrash();
      expect((sweep.stopped, sweep.unknown), (0, 0));
      final states = [
        for (final m in await store.messages(chat)) m.message.state,
      ];
      expect(states, [AiMessageState.complete, AiMessageState.allowed]);
    });

    test('blob over 256 KiB is replaced by a marker and flagged', () async {
      final a = await addStreaming(store, chat);
      final r = await store.completeRound(
        messageId: a,
        finalParts: const [TextPart('x')],
        blob: 'b' * (256 * 1024 + 1),
      );
      expect(r.blobTooLarge, isTrue);
      final m = (await store.message(a))!;
      expect(m.blobTooLarge, isTrue);
      expect(m.message.state, AiMessageState.complete);
    });

    test(
      'row over 1 MiB raises AiStoreTooLarge and marks the turn error',
      () async {
        await addUser(store, chat);
        final a = await addStreaming(store, chat);
        await expectLater(
          store.completeRound(
            messageId: a,
            finalParts: [TextPart('x' * (1024 * 1024 + 10))],
            calls: [ToolCardDraft(call: call('c'), needsConfirm: false)],
          ),
          throwsA(isA<AiStoreTooLarge>()),
        );
        final m = (await store.message(a))!;
        expect(m.message.state, AiMessageState.error);
        expect(m.error?.code, 'too_large');
        expect(await store.messages(chat), hasLength(2), reason: 'no card');
      },
    );

    test('blobs that cannot fit roll the round back and mark error', () async {
      final tiny = ConversationStore(
        db,
        limits: const ConversationStoreLimits(
          blobBytes: 100,
          conversationBlobBytes: 150,
        ),
      );
      addTearDown(tiny.dispose);
      await addUser(tiny, chat);
      final a = await addStreaming(tiny, chat);
      // One turn only: nothing older to flatten, so 200 B cannot fit in 150.
      final first = await addStreaming(tiny, chat);
      await tiny.completeRound(
        messageId: first,
        finalParts: const [],
        blob: 'a' * 90,
      );
      await expectLater(
        tiny.completeRound(
          messageId: a,
          finalParts: [call('c')],
          blob: 'b' * 90,
          calls: [ToolCardDraft(call: call('c'), needsConfirm: false)],
        ),
        throwsA(isA<AiStoreTooLarge>()),
      );
      expect((await tiny.message(a))!.message.state, AiMessageState.error);
      expect(
        (await tiny.messages(chat))
            .where((m) => m.message.role == AiMessageRole.tool),
        isEmpty,
      );
    });
  });

  group('live text', () {
    test('update after completion does not change the row', () async {
      final a = await addStreaming(store, chat, live: 'a');
      expect(await store.updateLiveText(a, 'ab'), isTrue);
      await store.completeRound(
        messageId: a,
        finalParts: const [TextPart('ab')],
      );
      expect(await store.updateLiveText(a, 'late'), isFalse);
      expect((await row(a)).liveText, isNull);
    });

    test(
      'over 256 KiB is truncated on a character boundary and marked',
      () async {
        final a = await addStreaming(store, chat);
        await store.updateLiveText(a, 'ạ' * 200000);
        final m = (await store.message(a))!;
        expect(m.liveTextTruncated, isTrue);
        final text = m.message.liveText!;
        expect(utf8.encode(text).length, lessThanOrEqualTo(256 * 1024));
        expect(text, endsWith(liveTextTruncationMarker));
        expect(text.contains('�'), isFalse);
        // A longer text later stores the same cut text.
        await store.updateLiveText(a, 'ạ' * 300000);
        expect((await store.message(a))!.message.liveText, text);
      },
    );

    test('a short text is stored as it is', () async {
      final a = await addStreaming(store, chat);
      await store.updateLiveText(a, 'xin chào');
      final m = (await store.message(a))!;
      expect(m.message.liveText, 'xin chào');
      expect(m.liveTextTruncated, isFalse);
    });
  });

  group('transitions', () {
    test('pending to allowed succeeds once for two callers', () async {
      final a = await addStreaming(store, chat);
      final r = await store.completeRound(
        messageId: a,
        finalParts: [call('c')],
        calls: [ToolCardDraft(call: call('c'), needsConfirm: true)],
      );
      final id = r.cardIds.single;
      final results = await Future.wait([
        store.resolveConfirm(id, ConfirmStatus.allowed),
        store.transition(
          id,
          from: AiMessageState.pending,
          to: AiMessageState.allowed,
        ),
      ]);
      expect(results.where((x) => x), hasLength(1));
      expect((await store.message(id))!.message.state, AiMessageState.allowed);
    });

    test('a denied answer skips the card and keeps the reason', () async {
      final a = await addStreaming(store, chat);
      final r = await store.completeRound(
        messageId: a,
        finalParts: [call('c')],
        calls: [ToolCardDraft(call: call('c'), needsConfirm: true)],
      );
      final id = r.cardIds.single;
      expect(
        await store.resolveConfirm(id, ConfirmStatus.deniedByNewMessage),
        isTrue,
      );
      expect(await store.resolveConfirm(id, ConfirmStatus.allowed), isFalse);
      final m = (await store.message(id))!.message;
      expect(m.state, AiMessageState.skipped);
      expect(
        m.parts.whereType<ConfirmPart>().single.status,
        ConfirmStatus.deniedByNewMessage,
      );
    });

    test('allowed runs to done once; the result is stored', () async {
      final a = await addStreaming(store, chat);
      final r = await store.completeRound(
        messageId: a,
        finalParts: [call('c')],
        calls: [ToolCardDraft(call: call('c'), needsConfirm: false)],
      );
      final id = r.cardIds.single;
      expect(
        await store.transition(
          id,
          from: AiMessageState.allowed,
          to: AiMessageState.running,
        ),
        isTrue,
      );
      expect(
        await store.transition(
          id,
          from: AiMessageState.allowed,
          to: AiMessageState.skipped,
        ),
        isFalse,
      );
      final result = ToolResultPart(
        id: 'c',
        name: 'search_library',
        content: const [TextPart('ok')],
      );
      expect(
        await store.transition(
          id,
          from: AiMessageState.running,
          to: AiMessageState.done,
          parts: [result],
        ),
        isTrue,
      );
      expect(
        await store.transition(
          id,
          from: AiMessageState.running,
          to: AiMessageState.done,
        ),
        isFalse,
      );
      expect((await store.message(id))!.message.parts, [result]);
    });

    test('an illegal move throws', () async {
      final a = await addStreaming(store, chat);
      expect(
        () => store.transition(
          a,
          from: AiMessageState.streaming,
          to: AiMessageState.running,
        ),
        throwsArgumentError,
      );
      expect(
        () => store.transition(
          a,
          from: AiMessageState.complete,
          to: AiMessageState.error,
        ),
        throwsArgumentError,
      );
    });

    test('a tool result over 1 MiB marks the row error and throws', () async {
      final a = await addStreaming(store, chat);
      final r = await store.completeRound(
        messageId: a,
        finalParts: [call('c')],
        calls: [ToolCardDraft(call: call('c'), needsConfirm: false)],
      );
      final id = r.cardIds.single;
      await store.transition(
        id,
        from: AiMessageState.allowed,
        to: AiMessageState.running,
      );
      await expectLater(
        store.transition(
          id,
          from: AiMessageState.running,
          to: AiMessageState.done,
          parts: [
            ToolResultPart(
              id: 'c',
              name: 'n',
              content: [TextPart('y' * (1024 * 1024))],
            ),
          ],
        ),
        throwsA(isA<AiStoreTooLarge>()),
      );
      final m = (await store.message(id))!;
      expect(m.message.state, AiMessageState.error);
      expect(m.error?.code, 'too_large');
    });

    test('streaming ends as stopped keeping its live text', () async {
      final a = await addStreaming(store, chat, live: 'half');
      expect(
        await store.transition(
          a,
          from: AiMessageState.streaming,
          to: AiMessageState.stopped,
        ),
        isTrue,
      );
      final m = (await store.message(a))!.message;
      expect((m.state, m.liveText), (AiMessageState.stopped, 'half'));
    });
  });

  group('errors', () {
    test('error text after the code is not persisted', () async {
      final a = await addStreaming(store, chat);
      final err = AiStoredError.fromPlugin(
        'ai:rate_limit: quota exceeded for key sk-SECRET123 in project p',
        kind: 'rateLimited',
        retryAfterSec: 30,
      );
      expect(
        await store.transition(
          a,
          from: AiMessageState.streaming,
          to: AiMessageState.error,
          error: err,
        ),
        isTrue,
      );
      final raw = (await row(a)).errorJson!;
      expect(raw, isNot(contains('SECRET')));
      expect(raw, isNot(contains('quota exceeded')));
      expect(jsonDecode(raw), {
        'code': 'rate_limit',
        'kind': 'rateLimited',
        'retryAfterSec': 30,
      });
      expect((await store.message(a))!.error, err);
    });

    test('unknown code or kind becomes server; a bad retry is dropped', () {
      final e = AiStoredError.fromPlugin(
        'ai:weird_thing: text',
        kind: 'bogus',
        retryAfterSec: -1,
      );
      expect((e.code, e.kind, e.retryAfterSec), ('server', 'server', null));
      expect(AiStoredError.fromPlugin('no prefix').code, 'server');
      expect(AiStoredError.tryParse('not json'), isNull);
    });
  });
}
