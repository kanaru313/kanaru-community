import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/database/database.dart';

import 'conversation_store_fixtures.dart';

void main() {
  late AppDatabase db;
  late ConversationStore store;
  late int chat;
  late int events;
  late StreamSubscription<void> sub;

  setUp(() async {
    db = openDb();
    store = ConversationStore(db);
    chat = (await newChat(store)).id;
    await Future<void>.delayed(Duration.zero);
    events = 0;
    sub = store.changes.listen((_) => events++);
  });
  tearDown(() async {
    await sub.cancel();
    store.dispose();
    await db.close();
  });

  /// Lets the coalesced event of the last write arrive, and returns how many
  /// events [write] caused.
  Future<int> eventsOf(Future<void> Function() write) async {
    // Events of the set-up writes arrive first.
    await Future<void>.delayed(Duration.zero);
    events = 0;
    await write();
    await Future<void>.delayed(Duration.zero);
    return events;
  }

  group('changes fires for', () {
    test('a card moving to another state', () async {
      await addUser(store, chat);
      final r = await toolRound(store, chat, callId: 'c1');
      expect(
        await eventsOf(
          () => store.transition(
            r.card,
            from: AiMessageState.allowed,
            to: AiMessageState.running,
          ),
        ),
        1,
      );
    });

    test('an answer to a pending card', () async {
      await addUser(store, chat);
      final r = await toolRound(store, chat, callId: 'c1', needsConfirm: true);
      expect(
        await eventsOf(
          () => store.resolveConfirm(r.card, ConfirmStatus.denied),
        ),
        1,
      );
    });

    test('a rename, an auto title, a permission and a binding', () async {
      expect(await eventsOf(() => store.rename(chat, 'Trip')), 1);
      final other = (await newChat(store)).id;
      expect(await eventsOf(() => store.setAutoTitle(other, 'Auto')), 1);
      expect(
        await eventsOf(() => store.setPermission(chat, AiPermission.auto)),
        1,
      );
      expect(
        await eventsOf(
          () => store.bind(
            chat,
            installId: 'p',
            installGeneration: 2,
            model: 'm',
          ),
        ),
        1,
      );
    });

    test('a turn ending flattened', () async {
      await addUser(store, chat);
      final r = await toolRound(
        store,
        chat,
        callId: 'c1',
        blob: '{"tooLarge":true}',
      );
      await finishCard(store, r.card, 'c1');
      final turn = await store.turnIdOf(r.assistant);
      expect(await eventsOf(() => store.flattenTurn(turn!)), 1);
    });
  });

  test('writes in a row wake the listeners at most once each', () async {
    await addUser(store, chat);
    final r = await toolRound(store, chat, callId: 'c1', needsConfirm: true);
    final n = await eventsOf(() async {
      await store.resolveConfirm(r.card, ConfirmStatus.denied);
      await store.rename(chat, 'Trip');
      await store.setPermission(chat, AiPermission.readOnly);
    });
    expect(n, inInclusiveRange(1, 3));
  });

  test('a lost card move and a live-text flush stay quiet', () async {
    await addUser(store, chat);
    final r = await toolRound(store, chat, callId: 'c1');
    final streaming = await addStreaming(store, chat);
    expect(
      await eventsOf(
        () => store.transition(
          r.card,
          from: AiMessageState.pending,
          to: AiMessageState.skipped,
        ),
      ),
      0,
    );
    expect(await eventsOf(() => store.updateLiveText(streaming, 'x')), 0);
  });

  group('startCall', () {
    Future<int> allowedCard() async {
      await addUser(store, chat);
      return (await toolRound(store, chat, callId: 'c1')).card;
    }

    test('refuses a write once the chat is read-only', () async {
      final card = await allowedCard();
      await store.setPermission(chat, AiPermission.readOnly);

      expect(await store.startCall(card, write: true), StartCall.readOnly);
      expect(
        (await store.message(card))!.message.state,
        AiMessageState.allowed,
      );
    });

    test('lets a read run while the chat is read-only', () async {
      final card = await allowedCard();
      await store.setPermission(chat, AiPermission.readOnly);

      expect(await store.startCall(card, write: false), StartCall.started);
      expect(
        (await store.message(card))!.message.state,
        AiMessageState.running,
      );
    });

    test('starts a write in an ask chat; a second start is moved', () async {
      final card = await allowedCard();

      expect(await store.startCall(card, write: true), StartCall.started);
      expect(await store.startCall(card, write: true), StartCall.moved);
    });
  });

  group('reads without blobs', () {
    test('messages(blobs: false) leaves out the provider blob only', () async {
      await addUser(store, chat);
      await toolRound(store, chat, callId: 'c1', blob: '{"big":1}');

      final all = await store.messages(chat);
      final lean = await store.messages(chat, blobs: false);

      expect(all.any((m) => m.providerJson != null), isTrue);
      expect(lean.every((m) => m.providerJson == null), isTrue);
      expect(
        [for (final m in lean) m.message.id],
        [for (final m in all) m.message.id],
      );
      expect(
        [for (final m in lean) m.message.parts.length],
        [for (final m in all) m.message.parts.length],
      );
    });

    test('a lean page honours beforeSeq and limit', () async {
      for (var i = 0; i < 5; i++) {
        await addUser(store, chat, 'm$i');
      }
      final page = await store.messages(
        chat,
        beforeSeq: 5,
        limit: 2,
        blobs: false,
      );
      expect([for (final m in page) m.message.seq], [3, 4]);
    });

    test('latestTurn holds the last user message and what follows', () async {
      await addUser(store, chat, 'first');
      await toolRound(store, chat, callId: 'old');
      final second = await addUser(store, chat, 'second');
      final r = await toolRound(store, chat, callId: 'new');

      final turn = await store.latestTurn(chat);

      expect(
        [for (final m in turn) m.message.id],
        [second, r.assistant, r.card],
      );
      expect(turn.every((m) => m.providerJson == null), isTrue);
    });

    test('latestTurn is empty without a user message', () async {
      expect(await store.latestTurn(chat), isEmpty);
    });

    test('openToolCards finds open cards of every turn', () async {
      await addUser(store, chat, 'first');
      final old = await toolRound(store, chat, callId: 'old');
      await addUser(store, chat, 'second');
      final fresh = await toolRound(
        store,
        chat,
        callId: 'new',
        needsConfirm: true,
      );
      final done = await toolRound(store, chat, callId: 'done');
      await finishCard(store, done.card, 'done');

      final open = await store.openToolCards(chat);

      expect([for (final m in open) m.message.id], [old.card, fresh.card]);
    });
  });
}
