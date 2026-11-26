import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/conversation/track_ref_snapshot.dart';
import 'package:kanaru/src/ai/domain/tools/item_caps.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';
import 'package:kanaru/src/ai/domain/loop/loop_driver.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import 'loop_fixtures.dart';

FakeTool writeTool(
  String name, {
  Future<ToolOutcome> Function(Map<String, Object?>, ToolEnv)? onRun,
}) => FakeTool(
  name,
  risk: ToolRisk.write,
  group: AiToolGroup.queueEdit,
  onRun: onRun,
);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late Rig rig;
  tearDown(() => rig.dispose());

  String callIdOf(AiMessage card) =>
      card.parts.whereType<ToolCallPart>().first.id;

  test('two concurrent Allows run the tool once', () async {
    rig = await Rig.create(
      script: [
        replies('', calls: [toolCall('write_a')]),
        replies('done'),
      ],
    );
    await rig.send('go');
    expect(rig.driver.turnState, TurnState.awaitingConfirm);
    final id = callIdOf((await rig.cards()).single);

    final answers = await Future.wait([
      rig.driver.allow(id),
      rig.driver.allow(id),
    ]);
    await rig.driver.inFlight;

    expect(answers, containsAll([CardAnswer.accepted, CardAnswer.notPending]));
    expect(rig.tool('write_a').runs, hasLength(1));
    expect(rig.runner.runs, 2);
    expect(rig.driver.turnState, TurnState.idle);
    expect(cardStates(await rig.cards()), ['write_a:done']);
    expect(rig.errors, isEmpty);
  });

  test('Retry tapped as a round ends starts one round', () async {
    rig = await Rig.create(
      script: [
        (_) async => const RunFailed(RunFailReason.internal),
        replies('hello'),
      ],
    );
    await rig.send('go');
    expect(rig.driver.turnState, TurnState.error);

    final starts = await Future.wait([rig.driver.retry(), rig.driver.retry()]);
    await rig.driver.inFlight;

    expect(starts.whereType<DriverStarted>(), hasLength(1));
    expect(starts.whereType<DriverBusy>(), hasLength(1));
    expect(rig.runner.runs, 2);
    expect(rig.driver.turnState, TurnState.idle);
  });

  test('send during a round is refused', () async {
    rig = await Rig.create(
      script: [
        streamThenHang(['par']),
      ],
    );
    final first = await rig.driver.send([const TextPart('one')]);
    expect(first, isA<DriverStarted>());
    await settle();
    expect(rig.driver.turnState, TurnState.streaming);

    final second = await rig.driver.send([const TextPart('two')]);
    expect(second, isA<DriverBusy>());
    await rig.driver.stop();

    final users = (await rig.rows()).where((m) => m.role == AiMessageRole.user);
    expect(users, hasLength(1));
    expect(rig.runner.runs, 1);
  });

  test(
    'tools run in model order: play_tracks before remove_from_queue',
    () async {
      final order = <String>[];
      rig = await Rig.create(
        permission: AiPermission.auto,
        tools: [
          writeTool(
            'play_tracks',
            onRun: (_, _) async {
              await Future<void>.delayed(const Duration(milliseconds: 30));
              order.add('play_tracks');
              return ToolOutcome.ok('{}');
            },
          ),
          writeTool(
            'remove_from_queue',
            onRun: (_, _) async {
              order.add('remove_from_queue');
              return ToolOutcome.ok('{}');
            },
          ),
        ],
        script: [
          replies(
            '',
            calls: [toolCall('play_tracks'), toolCall('remove_from_queue')],
          ),
          replies('ok'),
        ],
      );
      await rig.send('go');
      expect(order, ['play_tracks', 'remove_from_queue']);
      expect(rig.runner.runs, 2);
    },
  );

  test('next round starts only after all cards resolved', () async {
    rig = await Rig.create(
      script: [
        replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
        replies('done'),
      ],
    );
    await rig.send('go');
    final ids = [for (final c in await rig.cards()) callIdOf(c)];

    expect(await rig.driver.allow(ids[0]), CardAnswer.accepted);
    await rig.driver.inFlight;
    // The other card is still pending: nothing ran, no new round.
    expect(rig.tool('write_a').runs, isEmpty);
    expect(rig.runner.runs, 1);
    expect(rig.driver.turnState, TurnState.awaitingConfirm);

    expect(await rig.driver.deny(ids[1]), CardAnswer.accepted);
    await rig.driver.inFlight;
    expect(rig.tool('write_a').runs, hasLength(1));
    expect(rig.tool('write_b').runs, isEmpty);
    expect(rig.runner.runs, 2);
    expect(cardStates(await rig.cards()), ['write_a:done', 'write_b:skipped']);
    // The model reads that the user declined.
    final input = rig.runner.requests.last.input.toString();
    expect(input, contains(deniedByUserText));
  });

  test(
    'switch during tool batch runs no further write and no next round',
    () async {
      final gate = Completer<void>();
      rig = await Rig.create(
        permission: AiPermission.auto,
        tools: [
          writeTool(
            'write_a',
            onRun: (_, _) async {
              await gate.future;
              return ToolOutcome.ok('{}');
            },
          ),
          writeTool('write_b'),
        ],
        script: [
          replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
          replies('never'),
        ],
      );
      final started = await rig.driver.send([const TextPart('go')]);
      await settle();
      expect(rig.driver.turnState, TurnState.runningTools);

      // A plugin or model switch stops the turn first.
      final stopping = rig.driver.stop();
      gate.complete();
      await stopping;
      await (started as DriverStarted).done;

      expect(rig.tool('write_b').runs, isEmpty);
      expect(rig.runner.runs, 1);
      expect(cardStates(await rig.cards()), [
        'write_a:done',
        'write_b:skipped',
      ]);
      expect(rig.driver.turnState, TurnState.idle);
    },
  );

  test('a model change mid batch refuses the later write', () async {
    final gate = Completer<void>();
    rig = await Rig.create(
      permission: AiPermission.auto,
      tools: [
        writeTool(
          'write_a',
          onRun: (_, _) async {
            await gate.future;
            return ToolOutcome.ok('{}');
          },
        ),
        writeTool('write_b'),
      ],
      script: [
        replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
        replies('after'),
      ],
    );
    final started = await rig.driver.send([const TextPart('go')]);
    await settle();
    rig.env.installed = pluginOf(model: 'm2');
    gate.complete();
    await (started as DriverStarted).done;

    expect(rig.tool('write_b').runs, isEmpty);
    final cards = await rig.cards();
    expect(cardStates(cards), ['write_a:done', 'write_b:skipped']);
    expect(resultText(cards[1]), contains('not allowed now'));
  });

  test('stopped batch produces a result for every call', () async {
    final gate = Completer<void>();
    rig = await Rig.create(
      permission: AiPermission.auto,
      tools: [
        writeTool(
          'write_a',
          onRun: (_, _) async {
            await gate.future;
            return ToolOutcome.ok('{"x":1}');
          },
        ),
        writeTool('write_b'),
      ],
      script: [
        replies(
          '',
          calls: [
            toolCall('write_a'),
            toolCall('write_b'),
            toolCall('write_b'),
          ],
        ),
      ],
    );
    final started = await rig.driver.send([const TextPart('go')]);
    await settle();
    final stopping = rig.driver.stop();
    gate.complete();
    await stopping;
    await (started as DriverStarted).done;

    final cards = await rig.cards();
    expect(cardStates(cards), [
      'write_a:done',
      'write_b:skipped',
      'write_b:skipped',
    ]);
    expect(resultText(cards[0]), '{"x":1}');
    expect(resultText(cards[1]), stoppedByUserText);
    expect(resultText(cards[2]), stoppedByUserText);
    expect(rig.runner.runs, 1);
  });

  test('stop keeps the streamed text and starts no new round', () async {
    rig = await Rig.create(
      script: [
        streamThenHang(['Hel', 'lo']),
      ],
    );
    final started = await rig.driver.send([const TextPart('hi')]);
    await settle();
    await rig.driver.stop();
    await (started as DriverStarted).done;

    final assistant = (await rig.rows()).last;
    expect(assistant.state, AiMessageState.stopped);
    expect(assistant.liveText, 'Hello');
    expect(rig.driver.turnState, TurnState.idle);
    expect(rig.runner.runs, 1);
  });

  test('stop while awaiting confirmation skips the pending cards', () async {
    rig = await Rig.create(
      script: [
        replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
      ],
    );
    await rig.send('go');
    await rig.driver.stop();

    final cards = await rig.cards();
    expect(cardStates(cards), ['write_a:skipped', 'write_b:skipped']);
    expect(resultText(cards[0]), stoppedByUserText);
    expect(rig.driver.turnState, TurnState.idle);
    expect(rig.runner.runs, 1);
  });

  test('a new message denies the pending cards', () async {
    rig = await Rig.create(
      script: [
        replies('', calls: [toolCall('write_a')]),
        replies('fine'),
      ],
    );
    await rig.send('go');
    await rig.send('never mind');

    final cards = await rig.cards();
    expect(cardStates(cards), ['write_a:skipped']);
    final confirm = cards.single.parts.whereType<ConfirmPart>().single;
    expect(confirm.status, ConfirmStatus.deniedByNewMessage);
    expect(rig.tool('write_a').runs, isEmpty);
  });

  test('rounds stop at six, then one final round without tools', () async {
    rig = await Rig.create(
      script: [
        for (var i = 0; i < 6; i++) replies('', calls: [toolCall('read_a')]),
        replies('summary'),
      ],
    );
    await rig.send('go');

    expect(rig.runner.runs, 7);
    expect(rig.runner.requests.last.input['toolChoice'], 'none');
    expect(rig.runner.requests.first.input['toolChoice'], 'auto');
    expect(rig.tool('read_a').runs, hasLength(6));
    expect(rig.driver.turnState, TurnState.idle);
  });

  test(
    'a call in the final round is answered with an error, no eighth round',
    () async {
      rig = await Rig.create(
        script: [
          for (var i = 0; i < 6; i++) replies('', calls: [toolCall('read_a')]),
          replies('', calls: [toolCall('read_a')]),
        ],
      );
      await rig.send('go');

      expect(rig.runner.runs, 7);
      final last = (await rig.cards()).last;
      expect(last.state, AiMessageState.skipped);
      expect(resultText(last), contains('tools are not available'));
      expect(rig.tool('read_a').runs, hasLength(6));
    },
  );

  test('a call to an unknown tool gets an error result', () async {
    rig = await Rig.create(
      permission: AiPermission.auto,
      script: [
        replies('', calls: [toolCall('nope')]),
        replies('ok'),
      ],
    );
    await rig.send('go');
    final card = (await rig.cards()).single;
    expect(card.state, AiMessageState.skipped);
    expect(resultText(card), contains('unknown tool'));
    expect(rig.runner.runs, 2);
  });

  test('a tool that hangs fails after the timeout', () async {
    rig = await Rig.create(
      tools: [
        FakeTool('read_a', onRun: (_, _) => Completer<ToolOutcome>().future),
      ],
      script: [
        replies('', calls: [toolCall('read_a')]),
        replies('ok'),
      ],
    );
    rig.driver = rig.newDriver(toolTimeout: const Duration(milliseconds: 50));
    await rig.send('go');
    final card = (await rig.cards()).single;
    expect(card.state, AiMessageState.error);
    expect(resultText(card), toolTimedOutText);
    expect(rig.runner.runs, 2);
  });

  test('a write that times out is unknown, never failed', () async {
    rig = await Rig.create(
      permission: AiPermission.auto,
      tools: [
        writeTool('write_a', onRun: (_, _) => Completer<ToolOutcome>().future),
      ],
      script: [
        replies('', calls: [toolCall('write_a')]),
        replies('ok'),
      ],
    );
    rig.driver = rig.newDriver(toolTimeout: const Duration(milliseconds: 50));
    await rig.send('go');
    final card = (await rig.cards()).single;
    expect(card.state, AiMessageState.unknown);
    expect(resultText(card), writeTimedOutText);
  });

  test('item usage of the turn reaches the next tool', () async {
    TurnItemUsage? seen;
    rig = await Rig.create(
      permission: AiPermission.auto,
      tools: [
        writeTool(
          'write_a',
          onRun: (_, _) async => ToolOutcome.ok(
            '{}',
            done: const ToolDone(added: [_snap1, _snap2]),
          ),
        ),
        writeTool(
          'write_b',
          onRun: (_, env) async {
            seen = await env.turnUsage();
            return ToolOutcome.ok('{}');
          },
        ),
      ],
      script: [
        replies('', calls: [toolCall('write_a')]),
        replies('', calls: [toolCall('write_b')]),
        replies('end'),
      ],
    );
    await rig.send('go');
    expect(seen?.added, 2);
    expect(seen?.removed, 0);
  });

  test('the limit outcome ends the turn with the limit card', () async {
    rig = await Rig.create(
      permission: AiPermission.auto,
      tools: [
        writeTool(
          'write_a',
          onRun: (_, _) async => const ToolOutcome.limit('limit reached: 200'),
        ),
        writeTool('write_b'),
      ],
      script: [
        replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
        replies('never'),
      ],
    );
    await rig.send('go');

    final cards = await rig.cards();
    expect(cardStates(cards), ['write_a:error', 'write_b:skipped']);
    expect(cards[0].parts.whereType<ErrorPart>().single.code, limitReachedCode);
    expect(resultText(cards[1]), limitSkippedText);
    expect(rig.runner.runs, 1);
    expect(rig.driver.turnState, TurnState.error);
  });

  test(
    'a reply over the call cap stores the limit code and no calls',
    () async {
      rig = await Rig.create(
        permission: AiPermission.auto,
        script: [
          for (var i = 0; i < 3; i++)
            replies(
              '',
              calls: [for (var j = 0; j < 8; j++) toolCall('read_a')],
            ),
          replies('', calls: [toolCall('read_a')]),
        ],
      );
      await rig.send('go');

      final assistant = (await rig.rows())
          .where((m) => m.role == AiMessageRole.assistant)
          .last;
      expect(assistant.state, AiMessageState.error);
      expect(
        assistant.parts.whereType<ErrorPart>().single.code,
        limitReachedCode,
      );
      expect(rig.driver.turnState, TurnState.error);
      expect(rig.tool('read_a').runs, hasLength(24));
    },
  );

  test('a row written after the input was built stops the round', () async {
    rig = await Rig.create(script: [replies('never run')]);
    rig.env.onPlugin = () async {
      rig.env.onPlugin = null;
      await rig.store.append(
        NewAiMessage(
          conversationId: rig.conv.id,
          role: AiMessageRole.user,
          parts: const [TextPart('raced')],
        ),
      );
    };
    await rig.send('go');
    expect(rig.runner.runs, 0);
    final rows = await rig.rows();
    expect(rows.where((m) => m.role == AiMessageRole.assistant), isEmpty);
  });

  test('a missing plugin ends the turn without a stored round', () async {
    rig = await Rig.create();
    rig.env.installed = null;
    await rig.send('go');
    expect(rig.runner.runs, 0);
    expect(rig.driver.turnState, TurnState.error);
    expect(rig.driver.lastView?.card, isNotNull);
  });

  test(
    'streamed text is flushed to the store and the round is stamped',
    () async {
      rig = await Rig.create(
        script: [
          (ctl) async {
            ctl.onDelta('a');
            await Future<void>.delayed(const Duration(milliseconds: 5));
            ctl.onDelta('b');
            return RunOk(replyJson('ab'), pluginVersion: '4');
          },
        ],
      );
      final seen = <String>[];
      final sub = rig.driver.liveText.listen((e) => seen.add(e.text));
      await rig.send('go');
      await sub.cancel();

      expect(seen, ['a', 'ab']);
      final assistant = (await rig.rows()).last;
      expect(assistant.state, AiMessageState.complete);
      expect(assistant.parts.whereType<TextPart>().single.text, 'ab');
      expect(assistant.pluginVersion, 4);
    },
  );

  test('events after the outcome are dropped', () async {
    void Function(String)? emit;
    rig = await Rig.create(
      script: [
        (ctl) async {
          emit = ctl.onDelta;
          return RunOk(replyJson('x'));
        },
      ],
    );
    final seen = <String>[];
    final sub = rig.driver.liveText.listen((e) => seen.add(e.text));
    await rig.send('go');
    emit!('too late');
    await settle();
    await sub.cancel();
    expect(seen, isEmpty);
  });
}

const _snap1 = TrackRefSnapshot(trackId: 1, title: 'A', artist: 'X');
const _snap2 = TrackRefSnapshot(trackId: 2, title: 'B', artist: 'X');
