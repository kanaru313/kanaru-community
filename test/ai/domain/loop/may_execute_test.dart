import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_driver.dart';
import 'package:kanaru/src/ai/domain/loop/loop_ports.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/loop/may_execute.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';

import 'loop_fixtures.dart';

const _round = RoundBinding(
  installId: 'plug',
  installGeneration: 1,
  model: 'm1',
);
final _read = FakeTool('read_a');
final _write = FakeTool(
  'write_a',
  risk: ToolRisk.write,
  group: AiToolGroup.queueEdit,
);
final _call = ToolCallPart.parsed(
  id: 't1-r1-0',
  name: 'write_a',
  args: const {'tag': 'x', 'n': 2},
);

ExecDecision _gate({
  AiTool? tool,
  AiPermission permission = AiPermission.auto,
  bool Function(AiToolGroup)? groups,
  RoundBinding? current = _round,
  String? hash,
  ToolCallPart? call,
}) => mayExecute(
  call: call ?? _call,
  tool: tool ?? _write,
  permission: permission,
  groupEnabled: groups ?? (_) => true,
  round: _round,
  current: current,
  approvedHash: hash,
);

Matcher _refusedWith(ExecRefusal r) =>
    isA<ExecRefused>().having((d) => d.reason, 'reason', r);

void main() {
  group('mayExecute', () {
    test('allowed card refused at execution after switching to read-only', () {
      expect(_gate(), isA<ExecAllowed>());
      expect(
        _gate(permission: AiPermission.readOnly),
        _refusedWith(ExecRefusal.readOnly),
      );
      // Reads keep working in a read-only chat.
      expect(
        _gate(tool: _read, permission: AiPermission.readOnly),
        isA<ExecAllowed>(),
      );
    });

    test('allowed read refused after its group is turned off', () {
      expect(
        _gate(tool: _read, groups: (g) => g != AiToolGroup.librarySearch),
        _refusedWith(ExecRefusal.groupOff),
      );
    });

    test('refused after a plugin switch or reinstall', () {
      expect(
        _gate(
          current: const RoundBinding(
            installId: 'other',
            installGeneration: 1,
            model: 'm1',
          ),
        ),
        _refusedWith(ExecRefusal.pluginChanged),
      );
      expect(
        _gate(
          current: const RoundBinding(
            installId: 'plug',
            installGeneration: 2,
            model: 'm1',
          ),
        ),
        _refusedWith(ExecRefusal.pluginChanged),
      );
      expect(_gate(current: null), _refusedWith(ExecRefusal.pluginChanged));
      expect(
        _gate(
          current: const RoundBinding(
            installId: 'plug',
            installGeneration: 1,
            model: 'm2',
          ),
        ),
        _refusedWith(ExecRefusal.modelChanged),
      );
    });

    test('Allow refused when the stored args hash differs', () {
      final approved = callHash(_call);
      expect(_gate(hash: approved), isA<ExecAllowed>());
      final edited = ToolCallPart.parsed(
        id: 't1-r1-0',
        name: 'write_a',
        args: const {'tag': 'x', 'n': 3},
      );
      expect(
        _gate(hash: approved, call: edited),
        _refusedWith(ExecRefusal.hashMismatch),
      );
      final renamed = ToolCallPart.parsed(
        id: 't1-r1-0',
        name: 'write_b',
        args: const {'tag': 'x', 'n': 2},
      );
      expect(
        _gate(hash: approved, call: renamed),
        _refusedWith(ExecRefusal.hashMismatch),
      );
    });

    test('the hash ignores key order but not values', () {
      final a = ToolCallPart.parsed(
        id: 'a',
        name: 'x',
        args: const {
          'b': [1, 2],
          'a': {'y': 1, 'z': 2},
        },
      );
      final b = ToolCallPart.parsed(
        id: 'other id',
        name: 'x',
        args: const {
          'a': {'z': 2, 'y': 1},
          'b': [1, 2],
        },
      );
      final c = ToolCallPart.parsed(
        id: 'a',
        name: 'x',
        args: const {
          'b': [2, 1],
          'a': {'y': 1, 'z': 2},
        },
      );
      expect(callHash(a), callHash(b));
      expect(callHash(a), isNot(callHash(c)));
    });

    test('external tools never run', () {
      expect(
        _gate(tool: FakeTool('ext', risk: ToolRisk.external)),
        _refusedWith(ExecRefusal.external),
      );
      expect(_gate(tool: null), isA<ExecAllowed>());
    });
  });

  test('pending card expires after 24 h', () {
    final at = DateTime(2026, 11, 26, 10);
    expect(
      cardExpired(at, at.add(const Duration(hours: 23, minutes: 59))),
      isFalse,
    );
    expect(cardExpired(at, at.add(const Duration(hours: 24))), isTrue);
  });

  group('with a stored turn', () {
    late Rig rig;
    tearDown(() => rig.dispose());

    test('an Allow after 24 h expires the card instead', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a')]),
        ],
      );
      await rig.send('go');
      final id = (await rig.cards()).single.parts
          .whereType<ToolCallPart>()
          .single
          .id;
      rig.clock = () => DateTime.now().add(const Duration(hours: 25));

      expect(await rig.driver.allow(id), CardAnswer.expired);
      final card = (await rig.cards()).single;
      expect(card.state, AiMessageState.skipped);
      expect(
        card.parts.whereType<ConfirmPart>().single.status,
        ConfirmStatus.expired,
      );
      expect(rig.tool('write_a').runs, isEmpty);
    });

    test('inspect expires cards left for a day', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a')]),
        ],
      );
      await rig.send('go');
      rig.clock = () => DateTime.now().add(const Duration(hours: 30));
      final restarted = rig.newDriver();
      final action = await restarted.inspect();

      expect(action, isA<NeedsUserTap>());
      final card = (await rig.cards()).single;
      expect(
        card.parts.whereType<ConfirmPart>().single.status,
        ConfirmStatus.expired,
      );
      await restarted.dispose();
    });

    test(
      'switching to read-only denies pending and allowed-not-run calls',
      () async {
        rig = await Rig.create(
          script: [
            replies(
              '',
              calls: [
                toolCall('write_a'),
                toolCall('write_b'),
                toolCall('read_a'),
              ],
            ),
          ],
        );
        await rig.send('go');
        final cards = await rig.cards();
        final idA = cards[0].parts.whereType<ToolCallPart>().single.id;
        // write_a was allowed by the user, write_b is still pending.
        await rig.store.resolveConfirm(cards[0].id, ConfirmStatus.allowed);
        expect(idA, isNotEmpty);

        await rig.store.setPermission(rig.conv.id, AiPermission.readOnly);
        await rig.driver.applyPermission();

        final after = await rig.cards();
        expect(cardStates(after), [
          'write_a:skipped',
          'write_b:skipped',
          // The read is not a write: it stays as it was.
          'read_a:allowed',
        ]);
        expect(resultText(after[0]), contains('not allowed now'));
        expect(
          after[1].parts.whereType<ConfirmPart>().single.status,
          ConfirmStatus.denied,
        );
        expect(rig.tool('write_a').runs, isEmpty);
      },
    );

    test(
      'allowed card after restart re-checked when the round resolves',
      () async {
        rig = await Rig.create(
          permission: AiPermission.auto,
          script: [replies('then')],
        );
        // The app died after the round was stored, before the calls ran.
        await rig.seedRound(['read_a', 'write_a']);
        // While it was closed the user turned the read group off.
        rig.env.current = LoopSettings(
          groupEnabled: (g) => g != AiToolGroup.librarySearch,
        );

        final restarted = rig.newDriver();
        expect(
          await restarted.inspect(),
          isA<NeedsUserTap>().having(
            (a) => a.reason,
            'reason',
            TapReason.toolsWaiting,
          ),
        );
        expect(rig.runner.runs, 0);
        await ((await restarted.retry()) as DriverStarted).done;

        final cards = await rig.cards();
        expect(cardStates(cards), ['read_a:skipped', 'write_a:done']);
        expect(resultText(cards[0]), contains('not allowed now'));
        expect(rig.tool('read_a').runs, isEmpty);
        expect(rig.tool('write_a').runs, hasLength(1));
        expect(rig.runner.runs, 1);
        await restarted.dispose();
      },
    );
  });
}
