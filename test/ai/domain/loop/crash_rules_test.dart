import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_driver.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';

import 'loop_fixtures.dart';

void main() {
  late Rig rig;
  tearDown(() => rig.dispose());

  test(
    'write killed after running persisted → unknown after restart, not re-run',
    () async {
      rig = await Rig.create(permission: AiPermission.auto);
      final cards = await rig.seedRound(['write_a', 'write_b']);
      // write_a was persisted as running when the app died.
      await rig.store.transition(
        cards[0].id,
        from: AiMessageState.allowed,
        to: AiMessageState.running,
      );
      final swept = await rig.store.sweepAfterCrash();
      expect(swept.unknown, 1);
      expect(cardStates(await rig.cards()), [
        'write_a:unknown',
        'write_b:allowed',
      ]);

      final restarted = rig.newDriver();
      expect(await restarted.inspect(), isA<NeedsUserTap>());
      expect(rig.tool('write_a').runs, isEmpty);

      // Continuing runs the untouched call and never the unknown one.
      rig.runner.script.add(replies('done'));
      await ((await restarted.retry()) as DriverStarted).done;
      expect(rig.tool('write_a').runs, isEmpty);
      expect(rig.tool('write_b').runs, hasLength(1));
      expect(cardStates(await rig.cards()), [
        'write_a:unknown',
        'write_b:done',
      ]);
      // The model reads that the first result is unknown.
      expect(
        rig.runner.requests.single.input.toString(),
        contains('The result is unknown'),
      );
      await restarted.dispose();
    },
  );

  test('a write is stored as running before it runs', () async {
    AiMessageState? seen;
    late Rig local;
    final probe = FakeTool(
      'write_a',
      risk: ToolRisk.write,
      group: AiToolGroup.queueEdit,
      onRun: (_, _) async {
        seen = (await local.cards()).single.state;
        return ToolOutcome.ok('{}');
      },
    );
    rig = local = await Rig.create(
      permission: AiPermission.auto,
      tools: [probe],
      script: [
        replies('', calls: [toolCall('write_a')]),
        replies('ok'),
      ],
    );
    await rig.send('go');
    expect(seen, AiMessageState.running);
    expect(cardStates(await rig.cards()), ['write_a:done']);
  });

  group('no model run at launch, NeedsUserTap instead', () {
    test('a reply cut off while streaming', () async {
      rig = await Rig.create(script: [replies('after the tap')]);
      await rig.store.append(
        NewAiMessage(
          conversationId: rig.conv.id,
          role: AiMessageRole.user,
          parts: const [TextPart('hi')],
        ),
      );
      await rig.store.append(
        NewAiMessage(
          conversationId: rig.conv.id,
          role: AiMessageRole.assistant,
          state: AiMessageState.streaming,
          liveText: 'partial',
          installId: 'plug',
          installGeneration: 1,
          pluginVersion: 3,
          model: 'm1',
        ),
      );
      await rig.store.sweepAfterCrash();

      final restarted = rig.newDriver();
      final action = await restarted.inspect();
      expect(
        action,
        isA<NeedsUserTap>().having(
          (a) => a.reason,
          'reason',
          TapReason.modelRound,
        ),
      );
      expect(rig.runner.runs, 0);

      // Only the user's tap starts the round.
      await ((await restarted.retry()) as DriverStarted).done;
      expect(rig.runner.runs, 1);
      await restarted.dispose();
    });

    test('a message that never got a reply', () async {
      rig = await Rig.create(script: [replies('after the tap')]);
      await rig.store.append(
        NewAiMessage(
          conversationId: rig.conv.id,
          role: AiMessageRole.user,
          parts: const [TextPart('hi')],
        ),
      );
      final restarted = rig.newDriver();
      expect(await restarted.inspect(), isA<NeedsUserTap>());
      expect(restarted.turnState, TurnState.idle);
      expect(rig.runner.runs, 0);
      await restarted.dispose();
    });
  });

  test('pending card after restart acts only on tap', () async {
    rig = await Rig.create(script: [replies('done')]);
    final cards = await rig.seedRound(['write_a'], confirm: true);
    expect(cardStates(cards), ['write_a:pending']);
    final callId = cards.single.parts.whereType<ToolCallPart>().single.id;

    final restarted = rig.newDriver();
    expect(await restarted.inspect(), isA<AwaitConfirms>());
    expect(restarted.turnState, TurnState.awaitingConfirm);
    expect(rig.tool('write_a').runs, isEmpty);
    expect(rig.runner.runs, 0);

    // A Retry does not answer the card for the user.
    await ((await restarted.retry()) as DriverStarted).done;
    expect(cardStates(await rig.cards()), ['write_a:pending']);
    expect(rig.tool('write_a').runs, isEmpty);

    expect(await restarted.allow(callId), CardAnswer.accepted);
    await restarted.inFlight;
    expect(rig.tool('write_a').runs, hasLength(1));
    expect(rig.runner.runs, 1);
    await restarted.dispose();
  });
}
