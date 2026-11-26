import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/conversation/parts_codec.dart';
import 'package:kanaru/src/ai/domain/conversation/track_ref_snapshot.dart';
import 'package:kanaru/src/ai/domain/loop/card_results.dart';
import 'package:kanaru/src/ai/domain/loop/loop_driver.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/loop/may_execute.dart';
import 'package:kanaru/src/ai/domain/output/chat_outcome.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/item_caps.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import 'loop_fixtures.dart';

FakeTool _write(
  String name, {
  Future<ToolOutcome> Function(Map<String, Object?>, ToolEnv)? onRun,
}) => FakeTool(
  name,
  risk: ToolRisk.write,
  group: AiToolGroup.queueEdit,
  onRun: onRun,
);

void main() {
  late Rig rig;
  tearDown(() => rig.dispose());

  Future<void> rewriteCall(AiMessage card, Map<String, Object?> args) async {
    final parts = [
      for (final p in card.parts)
        p is ToolCallPart
            ? ToolCallPart.parsed(id: p.id, name: p.name, args: args)
            : p,
    ];
    await (rig.db.update(rig.db.aiMessages)..where((m) => m.id.equals(card.id)))
        .write(AiMessagesCompanion(partsJson: Value(encodeParts(parts))));
  }

  group('Allow bound to the call the user saw', () {
    test('Allow stores the hash of the call with the card', () async {
      rig = await Rig.create();
      final card = (await rig.seedRound(['write_a'], confirm: true)).single;
      final call = callOf(card)!;
      expect(await rig.driver.allow(call.id), CardAnswer.accepted);
      await rig.driver.inFlight;

      final done = (await rig.cards()).single;
      expect(done.state, AiMessageState.done);
      expect(confirmOf(done)!.approvalHash, callHash(call));
      expect(rig.tool('write_a').runs, hasLength(1));
    });

    test('a call changed after Allow does not run after a restart', () async {
      rig = await Rig.create(script: [replies('ok')]);
      final card = (await rig.seedRound(['write_a'], confirm: true)).single;
      // The user allowed it; the app died before it ran, and the stored call
      // was changed meanwhile.
      await rig.store.resolveConfirm(
        card.id,
        ConfirmStatus.allowed,
        approvalHash: callHash(callOf(card)!),
      );
      await rewriteCall((await rig.store.message(card.id))!.message, {
        'tag': 'other',
      });

      final restarted = rig.newDriver();
      await ((await restarted.retry()) as DriverStarted).done;

      final after = (await rig.cards()).single;
      expect(after.state, AiMessageState.skipped);
      expect(
        resultText(after),
        contains('the call changed after it was allowed'),
      );
      expect(rig.tool('write_a').runs, isEmpty);
      await restarted.dispose();
    });

    test('the same stored call runs after a restart', () async {
      rig = await Rig.create(script: [replies('ok')]);
      final card = (await rig.seedRound(['write_a'], confirm: true)).single;
      await rig.store.resolveConfirm(
        card.id,
        ConfirmStatus.allowed,
        approvalHash: callHash(callOf(card)!),
      );
      final restarted = rig.newDriver();
      await ((await restarted.retry()) as DriverStarted).done;
      expect((await rig.cards()).single.state, AiMessageState.done);
      expect(rig.tool('write_a').runs, hasLength(1));
      await restarted.dispose();
    });
  });

  group('a blob over its cap', () {
    Step bigBlobReply(String tool) =>
        (ctl) async => RunOk(
          jsonEncode({
            'finish': 'tool_calls',
            'text': 'looking',
            'toolCalls': [toolCall(tool)],
            'provider': {'blob': 'x' * (300 * 1024)},
          }),
          pluginVersion: '3',
        );

    test(
      'ends the turn: the calls do not run and the turn is flattened',
      () async {
        rig = await Rig.create(
          permission: AiPermission.auto,
          script: [bigBlobReply('read_a'), replies('never asked')],
        );
        await rig.send('go');

        expect(rig.runner.runs, 1);
        expect(rig.tool('read_a').runs, isEmpty);
        expect(rig.driver.turnState, TurnState.error);
        expect(rig.driver.lastView?.card, ChatCardKind.tooLarge);
        final stored = await rig.store.messages(rig.conv.id, limit: 100);
        expect(stored.every((m) => m.providerJson == null), isTrue);
        expect(
          stored.expand((m) => m.message.parts).whereType<ToolCallPart>(),
          isEmpty,
        );
        expect(rig.errors, isEmpty);
      },
    );

    test('a call that waited for Allow is denied and keeps its card', () async {
      rig = await Rig.create(script: [bigBlobReply('write_a')]);
      await rig.send('go');

      expect(rig.tool('write_a').runs, isEmpty);
      final card = (await rig.cards()).single;
      expect(card.state, AiMessageState.skipped);
      final confirm = confirmOf(card)!;
      expect(confirm.status, ConfirmStatus.denied);
      expect(confirm.reason, 'too_large');
    });
  });

  group('a new message', () {
    test('resolves the open cards of every earlier turn so they can be '
        'flattened', () async {
      rig = await Rig.create(script: [replies('fine')]);
      // Two turns whose cards were never answered.
      await rig.seedRound(['write_a'], confirm: true);
      await rig.seedRound(['write_b'], confirm: true);
      final firstTurn = (await rig.rows()).first.id;
      expect(await rig.store.flattenTurn(firstTurn), isFalse);

      await rig.send('never mind');

      final cards = await rig.cards();
      expect(cardStates(cards), ['write_a:skipped', 'write_b:skipped']);
      for (final c in cards) {
        expect(confirmOf(c)!.status, ConfirmStatus.deniedByNewMessage);
      }
      expect(await rig.store.flattenTurn(firstTurn), isTrue);
    });
  });

  test('retry after a reinstall keeps the item usage of the turn', () async {
    TurnItemUsage? seen;
    rig = await Rig.create(
      permission: AiPermission.auto,
      tools: [
        _write(
          'write_a',
          onRun: (_, _) async => ToolOutcome.ok(
            '{}',
            done: ToolDone(
              removed: [
                for (var i = 0; i < 45; i++)
                  TrackRefSnapshot(trackId: i, title: 't$i'),
              ],
            ),
          ),
        ),
        _write(
          'write_b',
          onRun: (_, env) async {
            seen = await env.turnUsage();
            return ToolOutcome.ok('{}');
          },
        ),
      ],
      script: [
        replies('', calls: [toolCall('write_a')]),
        (ctl) async => const RunFailed(RunFailReason.internal),
        replies('', calls: [toolCall('write_b')]),
        replies('end'),
      ],
    );
    await rig.send('go');
    expect(rig.driver.turnState, TurnState.error);

    // The plugin is reinstalled: the stored turn is flattened.
    expect(await rig.store.clearProviderBlobs(installId: 'plug'), 1);
    await ((await rig.driver.retry()) as DriverStarted).done;

    expect(seen, isNotNull);
    expect(seen!.removed, 45);
    expect(seen!.canRemove(6), isFalse);
  });

  group('stored error codes', () {
    Future<String> storedCode(Step failure) async {
      rig = await Rig.create(script: [failure]);
      await rig.send('go');
      final assistant = (await rig.rows())
          .where((m) => m.role == AiMessageRole.assistant)
          .single;
      return assistant.parts.whereType<ErrorPart>().single.code;
    }

    test('a failing network is stored as network', () async {
      final code = await storedCode(
        (ctl) async => const RunFailed(
          RunFailReason.internal,
          fetchFailure: FetchFailureInfo(kind: FetchFailureKind.network),
        ),
      );
      expect(code, 'network');
    });

    test('a blocked host is stored as host_not_allowed', () async {
      final code = await storedCode(
        (ctl) async => const RunFailed(
          RunFailReason.internal,
          fetchFailure: FetchFailureInfo(kind: FetchFailureKind.blockedHost),
        ),
      );
      expect(code, 'host_not_allowed');
    });
  });
}
