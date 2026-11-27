import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/driver_results.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/state/chat_attachments.dart';
import 'package:kanaru/src/ai/state/chat_flush.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/library/domain/ask_ai_target.dart';
import 'package:kanaru/src/plugins/data/install/remover.dart';

import '../data/conversation_store_fixtures.dart';
import 'chat_harness.dart';

/// A read tool that waits for the test.
class GateTool extends AiTool {
  GateTool();

  final gate = Completer<void>();
  final started = Completer<void>();

  @override
  String get name => 'gate_tool';
  @override
  String get description => 'Waits.';
  @override
  AiToolGroup get group => AiToolGroup.librarySearch;
  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': <String, Object?>{},
  };

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, env) async {
    started.complete();
    await gate.future;
    return const ToolOutcome.ok('done');
  }
}

/// A read tool whose result says it replaced the queue 1, 2, 3 (playing 2).
class SwapQueueTool extends AiTool {
  const SwapQueueTool();

  @override
  String get name => 'swap_queue';
  @override
  String get description => 'Swaps.';
  @override
  AiToolGroup get group => AiToolGroup.librarySearch;
  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': <String, Object?>{},
  };

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, env) async =>
      const ToolOutcome.ok(
        'ok',
        done: ToolDone(
          replacedQueue: ReplacedQueueSnapshot(
            tracks: [1, 2, 3],
            userOrder: [1, 2, 3],
            shuffled: false,
            previousIndex: 1,
          ),
        ),
      );
}

Future<void> until(bool Function() done) async {
  for (var i = 0; i < 600 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue, reason: 'the condition was never met');
}

Future<void> untilAsync(Future<bool> Function() done) async {
  for (var i = 0; i < 600; i++) {
    if (await done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('the condition was never met');
}

void main() {
  late ChatHarness t;
  late GateTool gateTool;

  Future<void> start({bool ready = true}) async {
    gateTool = GateTool();
    t = await ChatHarness.create(
      ready: ready,
      tools: [gateTool, const SwapQueueTool()],
    );
  }

  tearDown(() async => t.dispose());

  int openId() => t.session.state.conversationId!;
  Future<List<AiMessage>> transcript() async => [
    for (final m in await t.store.messages(openId(), limit: 100)) m.message,
  ];
  ToolCallPart? callOf(AiMessage m) =>
      m.parts.whereType<ToolCallPart>().firstOrNull;

  test('send streams the reply and persists the turn', () async {
    await start();
    t.engine.rounds.add(
      ScriptedRound.reply('Hello there', chunks: ['Hello', ' there']),
    );
    final live = <String>[];
    final sub = t.session.liveText.listen((e) => live.add(e.text));

    final sent = await t.sendAndWait('hi');
    await sub.cancel();

    expect(sent.userMessageId, isNotNull);
    expect(live, ['Hello', 'Hello there']);
    final rows = await transcript();
    expect(rows.map((m) => (m.role, m.state)), [
      (AiMessageRole.user, AiMessageState.complete),
      (AiMessageRole.assistant, AiMessageState.complete),
    ]);
    expect(rows.last.parts, [const TextPart('Hello there')]);
    expect(rows.last.model, 'gemini-2.5-flash');
    expect(t.session.state.turnState, TurnState.idle);
    final input = t.engine.inputs.single;
    expect(input['model'], 'gemini-2.5-flash');
    expect(jsonEncode(input['messages']), contains('hi'));
    expect((await t.store.conversation(openId()))!.title, 'hi');
  });

  test('send with missing data returns missingData and keeps chips', () async {
    await start();
    const chip = ChipPart(kind: ChipKind.playlist, ref: 'gone', label: 'Old');
    t.container.read(chatAttachmentsProvider.notifier).attach(chip);

    final result = await t.session.send('what is in it?');

    expect(result, isA<SendMissingData>());
    final issue = (result as SendMissingData).issues.single;
    expect(issue, isA<ChipUnavailable>());
    expect(t.container.read(chatAttachmentsProvider).attached, [chip]);
    expect(t.engine.streamRequests, isEmpty);
    expect(await t.store.latestSeq(openId()), 0);
  });

  test('an accepted send clears the attached chips', () async {
    await start();
    final attachments = t.container.read(chatAttachmentsProvider.notifier);
    attachments.attachTarget(
      const AskAiTarget.songs([AskAiTrack(id: 7, title: 'Song')]),
    );
    await t.sendAndWait('tell me');
    expect(t.container.read(chatAttachmentsProvider).attached, isEmpty);
    final user = (await transcript()).first;
    expect(user.parts.whereType<ChipPart>().single.kind, ChipKind.songs);
    expect(user.parts.whereType<DataPart>(), isNotEmpty);
  });

  test('send is blocked while the plugin has no key', () async {
    await start(ready: false);
    final result = await t.session.send('hi');
    expect(result, isA<SendBlocked>());
    expect((result as SendBlocked).readiness, isA<ChatNeedsKey>());
    expect(t.engine.streamRequests, isEmpty);
  });

  test('stop keeps the partial text', () async {
    await start();
    t.engine.rounds.add(
      const ScriptedRound(
        events: ['{"t":"text","d":"Par"}'],
        untilCancelled: true,
      ),
    );
    final live = <String>[];
    t.session.liveText.listen((e) => live.add(e.text));
    final sent = await t.session.send('go') as SendSent;
    await until(() => live.isNotEmpty);

    await t.session.stop();
    await sent.done;

    final assistant = (await transcript()).last;
    expect(assistant.state, AiMessageState.stopped);
    expect(assistant.liveText, 'Par');
    expect(t.session.state.turnState, TurnState.idle);
  });

  test('opening another conversation stops the turn', () async {
    await start();
    t.engine.rounds.add(const ScriptedRound(untilCancelled: true));
    await t.session.send('go');
    final first = openId();
    await until(() => t.engine.streamRequests.isNotEmpty);
    final other = await t.store.create(
      title: 'o',
      permission: AiPermission.ask,
    );

    expect(await t.session.open(other.id), isTrue);

    expect(openId(), other.id);
    expect(t.engine.cancelled, isNotEmpty);
    final rows = await t.store.messages(first, limit: 10);
    expect(rows.last.message.state, AiMessageState.stopped);
  });

  test('open refuses a conversation that does not exist', () async {
    await start();
    await t.session.newConversation();
    expect(await t.session.open(9999), isFalse);
  });

  test('delete during a stream stops, then deletes', () async {
    await start();
    t.engine.rounds.add(const ScriptedRound(untilCancelled: true));
    await t.session.send('go');
    final id = openId();
    await until(() => t.engine.streamRequests.isNotEmpty);

    await t.session.delete(id);

    expect(await t.store.conversation(id), isNull);
    expect(t.engine.cancelled, isNotEmpty);
  });

  test('delete during a running tool waits, then deletes', () async {
    await start();
    t.engine.rounds.add(
      ScriptedRound.calls([
        {'name': 'gate_tool', 'args': <String, Object?>{}},
      ]),
    );
    await t.session.send('go');
    final id = openId();
    await gateTool.started.future;

    var deleted = false;
    final deleting = t.session.delete(id).then((_) => deleted = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(deleted, isFalse, reason: 'the tool is still running');
    expect(await t.store.conversation(id), isNotNull);

    gateTool.gate.complete();
    await deleting;
    expect(await t.store.conversation(id), isNull);
  });

  test('deleting the open conversation opens a new empty one', () async {
    await start();
    await t.sendAndWait('hi');
    final id = openId();

    await t.session.delete(id);

    expect(openId(), isNot(id));
    expect(await t.store.latestSeq(openId()), 0);
    expect(t.session.state.turnState, TurnState.idle);
  });

  test('deleteAll with an active turn clears the chat plugin logs', () async {
    await start();
    t.engine.rounds.add(const ScriptedRound(untilCancelled: true));
    await t.session.send('go');
    await until(() => t.engine.streamRequests.isNotEmpty);

    await t.session.deleteAll();

    expect(t.logs.cleared, [t.installId]);
    final all = await t.store.list();
    expect(all, hasLength(1), reason: 'only the new empty chat is left');
    expect(await t.store.latestSeq(all.single.id), 0);
  });

  test('flushChat writes the live text', () async {
    await start();
    t.engine.rounds.add(
      const ScriptedRound(
        events: ['{"t":"text","d":"abc"}'],
        untilCancelled: true,
      ),
    );
    final live = <String>[];
    t.session.liveText.listen((e) => live.add(e.text));
    await t.session.send('go');
    await until(() => live.isNotEmpty);
    t.engine.lastOnEvent!('{"t":"text","d":"def"}');
    await until(() => live.length == 2);

    await flushChat(t.container);

    expect((await transcript()).last.liveText, 'abcdef');
  });

  test(
    'the first streamed text is written without waiting for a flush',
    () async {
      await start();
      t.engine.rounds.add(
        const ScriptedRound(
          events: ['{"t":"text","d":"abc"}'],
          untilCancelled: true,
        ),
      );
      final live = <String>[];
      t.session.liveText.listen((e) => live.add(e.text));
      await t.session.send('go');
      await until(() => live.isNotEmpty);

      // No flushChat and no interval elapsed: a kill now still keeps it.
      final swept = await t.store.sweepAfterCrash();

      expect(swept.stopped, 1);
      expect((await transcript()).last.liveText, 'abc');
    },
  );

  test('kill after some deltas keeps the flushed prefix', () async {
    await start();
    t.engine.rounds.add(
      const ScriptedRound(
        events: ['{"t":"text","d":"abc"}'],
        untilCancelled: true,
      ),
    );
    final live = <String>[];
    t.session.liveText.listen((e) => live.add(e.text));
    await t.session.send('go');
    await until(() => live.isNotEmpty);
    await flushChat(t.container);
    // More text arrives that no flush wrote before the process dies.
    t.engine.lastOnEvent!('{"t":"text","d":"def"}');
    await until(() => live.length == 2);

    final swept = await t.store.sweepAfterCrash();

    expect(swept.stopped, 1);
    final assistant = (await transcript()).last;
    expect(assistant.state, AiMessageState.stopped);
    expect(assistant.liveText, 'abc');
  });

  test('disposing the container mid-run cancels the runner', () async {
    await start();
    t.engine.rounds.add(const ScriptedRound(untilCancelled: true));
    await t.session.send('go');
    await until(() => t.engine.streamRequests.isNotEmpty);

    t.disposeContainer();

    await until(() => t.engine.cancelled.isNotEmpty);
  });

  test('removing a plugin clears its provider blobs', () async {
    await start();
    final chat = await t.session.newConversation();
    await addUser(t.store, chat);
    final round = await toolRound(
      t.store,
      chat,
      callId: 't1-r1-0',
      install: t.installId,
    );
    await finishCard(t.store, round.card, 't1-r1-0');
    expect(
      (await t.store.messages(chat)).any((m) => m.providerJson != null),
      isTrue,
    );

    expect(await t.h.actions.remover.remove(t.installId), RemoveResult.removed);

    await untilAsync(() async {
      final rows = await t.store.messages(chat, limit: 100);
      return rows.every((m) => m.providerJson == null);
    });
  });

  test(
    'a version change keeps blobs; the next send flattens older turns',
    () async {
      await start();
      final chat = await t.session.newConversation();
      await t.store.bind(
        chat,
        installId: t.installId,
        installGeneration: (await t.h.rows.liveById(t.installId))!.installedAt,
        model: 'gemini-2.5-flash',
      );
      await addUser(t.store, chat, 'earlier question');
      // A round that an older version of the plugin made (version 0).
      final a = await addStreaming(t.store, chat, install: t.installId);
      final r = await t.store.completeRound(
        messageId: a,
        finalParts: [const TextPart('earlier answer'), call('t1-r1-0')],
        blob: '{"b":1}',
        calls: [ToolCardDraft(call: call('t1-r1-0'), needsConfirm: false)],
      );
      await finishCard(t.store, r.cardIds.single, 't1-r1-0');
      await t.store.stampPluginVersion(a, 0);

      await t.sendAndWait('next question');

      final sent = jsonEncode(t.engine.inputs.single['messages']);
      expect(sent, contains('earlier answer'));
      expect(sent, isNot(contains('tool_call')));
      expect(sent, isNot(contains('"provider"')));
      expect(
        (await t.store.messages(
          chat,
          limit: 100,
        )).any((m) => m.providerJson == '{"b":1}'),
        isTrue,
        reason: 'the blob stays stored',
      );
    },
  );

  test(
    'replayQueue plays the replaced queue; older turns are refused',
    () async {
      await start();
      t.engine.rounds
        ..add(
          ScriptedRound.calls([
            {'name': 'swap_queue', 'args': <String, Object?>{}},
          ]),
        )
        ..add(ScriptedRound.reply('swapped'));
      await t.sendAndWait('swap');
      final tool = (await transcript()).firstWhere(
        (m) => m.role == AiMessageRole.tool,
      );

      expect(await t.session.replayQueue(tool.id), ReplayResult.played);
      expect(t.playbackWrite.plays.single.ids, [1, 2, 3]);
      expect(t.playbackWrite.plays.single.startIndex, 1);

      await t.sendAndWait('another');
      expect(await t.session.replayQueue(tool.id), ReplayResult.notLatestTurn);
      expect(t.playbackWrite.plays, hasLength(1));
    },
  );

  test('turn state follows streaming, tools, confirm and idle', () async {
    await start();
    final seen = <TurnState>[];
    t.container.listen(
      chatSessionProvider.select((s) => s.turnState),
      (_, s) => seen.add(s),
    );
    await t.session.newConversation();
    t.engine.rounds
      ..add(
        ScriptedRound.calls([
          {
            'name': 'create_playlist',
            'args': {'name': 'Trip', 'trackIds': <int>[]},
          },
        ]),
      )
      ..add(ScriptedRound.reply('Made it'));

    await t.sendAndWait('make a playlist');
    expect(t.session.state.turnState, TurnState.awaitingConfirm);
    final card = (await transcript()).lastWhere(
      (m) => m.role == AiMessageRole.tool,
    );
    expect(card.state, AiMessageState.pending);

    await t.session.allow(callOf(card)!.id);
    await until(() => t.session.state.turnState == TurnState.idle);

    expect(seen, [
      TurnState.streaming,
      TurnState.awaitingConfirm,
      TurnState.runningTools,
      TurnState.streaming,
      TurnState.idle,
    ]);
    expect((await transcript()).last.parts, [const TextPart('Made it')]);
  });

  for (final mode in [AiPermission.auto, AiPermission.ask]) {
    test(
      'two tool rounds then the answer in ${mode.name} mode, replayed after reopening',
      () async {
        await start();
        await t.session.newConversation();
        await t.session.setPermission(mode);
        t.engine.rounds
          ..add(
            ScriptedRound.calls([
              {'name': 'list_playlists', 'args': <String, Object?>{}},
            ]),
          )
          ..add(
            ScriptedRound.calls([
              {
                'name': 'create_playlist',
                'args': {'name': 'Trip', 'trackIds': <int>[]},
              },
            ]),
          )
          ..add(ScriptedRound.reply('All done'));

        await t.sendAndWait('plan it');
        if (mode == AiPermission.ask) {
          final card = (await transcript()).lastWhere(
            (m) => m.role == AiMessageRole.tool,
          );
          expect(await t.session.allow(callOf(card)!.id), CardAnswer.accepted);
          await until(() => t.session.state.turnState == TurnState.idle);
        }

        final id = openId();
        await t.session.newConversation(); // leaves a non-empty chat behind
        await t.session.open(id);
        final rows = await transcript();
        expect(rows.where((m) => m.role == AiMessageRole.tool), hasLength(2));
        expect(rows.last.parts, [const TextPart('All done')]);
        expect(rows.last.state, AiMessageState.complete);
        expect(t.engine.streamRequests, hasLength(3));
      },
    );
  }
}
