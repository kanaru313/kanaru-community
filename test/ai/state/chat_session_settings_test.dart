import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/permission.dart';

import 'chat_harness.dart';

void main() {
  late ChatHarness t;

  setUp(() async => t = await ChatHarness.create());
  tearDown(() async => t.dispose());

  int openId() => t.session.state.conversationId!;

  test('an empty open conversation is reused by newConversation', () async {
    final first = await t.session.newConversation();
    expect(await t.session.newConversation(), first);
    await t.sendAndWait('hi');
    expect(await t.session.newConversation(), isNot(first));
  });

  test('a new conversation takes the plugin and its model', () async {
    final id = await t.session.newConversation();
    final c = (await t.store.conversation(id))!;
    expect(c.installId, t.installId);
    expect(c.installGeneration, isNotNull);
    expect(c.model, 'gemini-2.5-flash');
  });

  test('switchModel binds the model; the next send uses it', () async {
    await t.session.newConversation();
    await t.session.switchModel('my-model');
    expect((await t.store.conversation(openId()))!.model, 'my-model');

    await t.sendAndWait('hi');

    expect(t.engine.inputs.single['model'], 'my-model');
    final assistant = (await t.store.messages(openId())).last.message;
    expect(assistant.model, 'my-model');
  });

  test('switchModel stops the running turn first', () async {
    t.engine.rounds.add(const ScriptedRound(untilCancelled: true));
    await t.session.send('go');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await t.session.switchModel('other');

    final assistant = (await t.store.messages(openId())).last.message;
    expect(assistant.state, AiMessageState.stopped);
    expect(t.session.state.turnState, TurnState.idle);
  });

  test('switchPlugin refuses a plugin that is not installed', () async {
    await t.session.newConversation();
    expect(await t.session.switchPlugin('plugin-${'0' * 32}'), isFalse);
  });

  test('switching to the plugin the chat already has writes no line', () async {
    await t.session.newConversation();
    expect(await t.session.switchPlugin(t.installId), isTrue);
    expect(await t.store.latestSeq(openId()), 0);
  });

  test('rename sets the title for good; a blank title is ignored', () async {
    final id = await t.session.newConversation();
    await t.session.rename(id, '   ');
    expect((await t.store.conversation(id))!.title, '');

    await t.session.rename(id, ' Road trip ');
    await t.sendAndWait('a very different first message');

    final c = (await t.store.conversation(id))!;
    expect(c.title, 'Road trip');
    expect(c.titleAuto, isFalse);
  });

  test('read-only denies the pending write at once', () async {
    await t.session.newConversation();
    t.engine.rounds.add(
      ScriptedRound.calls([
        {
          'name': 'create_playlist',
          'args': {'name': 'Trip', 'trackIds': <int>[]},
        },
      ]),
    );
    await t.sendAndWait('make it');
    expect(t.session.state.turnState, TurnState.awaitingConfirm);

    await t.session.setPermission(AiPermission.readOnly);

    final card = (await t.store.messages(openId())).last.message;
    expect(card.state, AiMessageState.skipped);
    expect(t.session.state.turnState, isNot(TurnState.awaitingConfirm));
    expect(
      (await t.store.conversation(openId()))!.permission,
      AiPermission.readOnly,
    );
  });
}
