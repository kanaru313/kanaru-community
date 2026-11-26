import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/driver_results.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/state/chat_attachments.dart';
import 'package:kanaru/src/ai/state/chat_messages_provider.dart';

import 'chat_harness.dart';

Future<T> settle<T>(T Function() read, bool Function(T) ready) async {
  for (var i = 0; i < 400; i++) {
    final v = read();
    if (ready(v)) return v;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('never settled');
}

ScriptedRound twoPlaylists() => ScriptedRound.calls([
  {
    'name': 'create_playlist',
    'args': {'name': 'A', 'trackIds': <int>[]},
  },
  {
    'name': 'create_playlist',
    'args': {'name': 'B', 'trackIds': <int>[]},
  },
]);

void main() {
  late ChatHarness t;

  setUp(() async => t = await ChatHarness.create());
  tearDown(() async => t.dispose());

  int openId() => t.session.state.conversationId!;

  Future<List<AiMessage>> cards() async => [
    for (final m in await t.store.messages(openId()))
      if (m.message.role == AiMessageRole.tool) m.message,
  ];

  List<AiMessageState> shown(AsyncValue<ChatMessages> v) => [
    for (final m in v.requireValue.messages)
      if (m.role == AiMessageRole.tool) m.state,
  ];

  group('the message list follows answered cards', () {
    test('denying one of two pending cards shows it skipped', () async {
      t.engine.rounds.add(twoPlaylists());
      await t.sendAndWait('go');
      final id = openId();
      final sub = t.container.listen(chatMessagesProvider(id), (_, _) {});
      addTearDown(sub.close);
      await settle(
        () => t.container.read(chatMessagesProvider(id)),
        (v) => v.hasValue && shown(v).length == 2,
      );
      final first = (await cards()).first.parts.whereType<ToolCallPart>().first;

      expect(await t.session.deny(first.id), CardAnswer.accepted);

      // The turn still waits on the other card: its state does not change,
      // yet the answered card must leave "pending" on screen.
      expect(t.session.state.turnState, TurnState.awaitingConfirm);
      await settle(
        () => t.container.read(chatMessagesProvider(id)),
        (v) =>
            shown(v).toString() ==
            [AiMessageState.skipped, AiMessageState.pending].toString(),
      );
    });

    test('switching to read-only shows the denied cards at once', () async {
      t.engine.rounds.add(twoPlaylists());
      await t.sendAndWait('go');
      final id = openId();
      final sub = t.container.listen(chatMessagesProvider(id), (_, _) {});
      addTearDown(sub.close);
      await settle(
        () => t.container.read(chatMessagesProvider(id)),
        (v) => v.hasValue && shown(v).length == 2,
      );

      await t.session.setPermission(AiPermission.readOnly);

      await settle(
        () => t.container.read(chatMessagesProvider(id)),
        (v) => shown(v).every((s) => s == AiMessageState.skipped),
      );
    });
  });

  group('a turn that only waits on cards', () {
    test('keeps them pending when another chat is opened', () async {
      t.engine.rounds.add(twoPlaylists());
      await t.sendAndWait('go');
      final first = openId();

      final second = await t.session.newConversation();
      expect(second, isNot(first));

      final stored = [
        for (final m in await t.store.messages(first))
          if (m.message.role == AiMessageRole.tool) m.message.state,
      ];
      expect(stored, [AiMessageState.pending, AiMessageState.pending]);

      // Back in the first chat the cards still wait for an answer.
      await t.session.open(first);
      await settle(
        () => t.session.state.turnState,
        (s) => s == TurnState.awaitingConfirm,
      );
    });

    test('keeps them pending when the model is switched', () async {
      t.engine.rounds.add(twoPlaylists());
      await t.sendAndWait('go');

      await t.session.switchModel('other-model');

      expect((await cards()).map((c) => c.state), [
        AiMessageState.pending,
        AiMessageState.pending,
      ]);
      expect(t.session.state.turnState, TurnState.awaitingConfirm);
    });

    test('Stop still denies them', () async {
      t.engine.rounds.add(twoPlaylists());
      await t.sendAndWait('go');

      await t.session.stop();

      expect((await cards()).map((c) => c.state), [
        AiMessageState.skipped,
        AiMessageState.skipped,
      ]);
    });
  });

  group('chips of a send', () {
    const a = ChipPart(kind: ChipKind.genre, ref: 'pop', label: 'Pop');
    const b = ChipPart(kind: ChipKind.genre, ref: 'rock', label: 'Rock');

    test('only the chips that were sent are cleared', () {
      final notifier = t.container.read(chatAttachmentsProvider.notifier)
        ..attach(a)
        ..attach(b);

      // `a` was attached when the send started; `b` came in while it was
      // being prepared.
      notifier.clearAttached([a]);

      expect(t.container.read(chatAttachmentsProvider).attached, [b]);
    });

    test('without an argument every chip is cleared', () {
      final notifier = t.container.read(chatAttachmentsProvider.notifier)
        ..attach(a)
        ..attach(b);

      notifier.clearAttached();

      expect(t.container.read(chatAttachmentsProvider).attached, isEmpty);
    });
  });
}
