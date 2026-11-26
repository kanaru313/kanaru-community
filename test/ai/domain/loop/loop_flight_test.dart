import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/loop_store_adapter.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/input/history_turns.dart';
import 'package:kanaru/src/ai/domain/loop/loop_driver.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_outcome.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import 'loop_fixtures.dart';

/// A store that counts the reads of whole transcripts (the ones with blobs).
class _SpyStore extends LoopStoreAdapter {
  _SpyStore(super.store);

  int historyReads = 0;

  @override
  Future<List<HistoryRow>> history(int conversationId) {
    historyReads++;
    return super.history(conversationId);
  }
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late Rig rig;
  tearDown(() => rig.dispose());

  String callIdOf(AiMessage card) =>
      card.parts.whereType<ToolCallPart>().first.id;

  group('stop during the set-up of a round', () {
    test('starts no run and stores no reply', () async {
      rig = await Rig.create(script: [replies('never run')]);
      final reached = Completer<void>();
      final release = Completer<void>();
      var calls = 0;
      // The loop asks for the plugin once to decide and once more to run the
      // round: hold the second read, where the round is being set up.
      rig.env.onPlugin = () async {
        if (++calls == 2) {
          reached.complete();
          await release.future;
        }
      };
      final start =
          await rig.driver.send([const TextPart('go')]) as DriverStarted;
      await reached.future;

      final stopped = rig.driver.stop();
      release.complete();
      await stopped;
      await start.done;

      expect(rig.runner.runs, 0);
      final rows = await rig.rows();
      expect(rows.where((m) => m.role == AiMessageRole.assistant), isEmpty);
      expect(rig.driver.turnState, TurnState.idle);
    });
  });

  group('dispose', () {
    test('refuses a trigger that lands as the flight is released', () async {
      rig = await Rig.create(
        script: [
          streamThenHang(['hi']),
        ],
      );
      final start =
          await rig.driver.send([const TextPart('go')]) as DriverStarted;
      await settle();

      final disposing = rig.driver.dispose();
      // Runs right after the flight completes, before dispose returns.
      final late = start.done.then(
        (_) => rig.driver.send([const TextPart('x')]),
      );

      expect(await late, isA<DriverClosed>());
      await disposing;
      expect(rig.runner.runs, 1);
    });

    test('leaves the cards waiting for an answer pending', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a')]),
          replies('done'),
        ],
      );
      await rig.send('go');
      expect(rig.driver.turnState, TurnState.awaitingConfirm);

      await rig.driver.dispose();
      expect(cardStates(await rig.cards()), ['write_a:pending']);

      // The chat opens again later and the card can still be answered.
      final again = rig.newDriver();
      await again.inspect();
      expect(again.turnState, TurnState.awaitingConfirm);
      final id = callIdOf((await rig.cards()).single);
      expect(await again.allow(id), CardAnswer.accepted);
      await again.inFlight;
      expect(cardStates(await rig.cards()), ['write_a:done']);
      await again.dispose();
    });
  });

  group('runExclusive', () {
    test('refuses every trigger while the body runs', () async {
      rig = await Rig.create(script: [replies('later')]);
      final entered = Completer<void>();
      final release = Completer<void>();
      final run = rig.driver.runExclusive(() async {
        entered.complete();
        await release.future;
        return 7;
      });
      await entered.future;

      expect(await rig.driver.send([const TextPart('hi')]), isA<DriverBusy>());
      expect(await rig.driver.retry(), isA<DriverBusy>());
      release.complete();

      expect(await run, 7);
      expect(rig.runner.runs, 0);
      expect(await rig.rows(), isEmpty);
      // The gate is free again.
      await rig.send('hi');
      expect(rig.runner.runs, 1);
    });

    test('stops a round in flight and runs the body after it', () async {
      rig = await Rig.create(
        script: [
          streamThenHang(['partial']),
        ],
      );
      await rig.driver.send([const TextPart('go')]);
      await settle();
      expect(rig.driver.turnState, TurnState.streaming);

      final seen = <AiMessageState>[];
      await rig.driver.runExclusive(() async {
        seen.add((await rig.rows()).last.state);
      });

      expect(seen, [AiMessageState.stopped]);
      expect(rig.driver.turnState, TurnState.idle);
    });

    test('leaves the cards of a turn that only waits pending', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
        ],
      );
      await rig.send('go');

      await rig.driver.runExclusive(() async {});

      expect(cardStates(await rig.cards()), [
        'write_a:pending',
        'write_b:pending',
      ]);
      expect(rig.driver.turnState, TurnState.awaitingConfirm);
    });
  });

  test('the loop reads whole transcripts only to build a round', () async {
    rig = await Rig.create(
      script: [
        replies('', calls: [toolCall('read_a'), toolCall('read_b')]),
        replies('done'),
      ],
    );
    final spy = _SpyStore(rig.store);
    await rig.driver.dispose();
    rig.driver = LoopDriver(
      conversationId: rig.conv.id,
      store: spy,
      runner: rig.runner,
      env: rig.env,
      newBoundary: () => 'kfixedbound',
      onInternalError: (e, s) => rig.errors.add(e),
    );

    await rig.send('go');

    expect(rig.runner.runs, 2);
    // Every pump step, tool run and card read uses the blob-free latest turn.
    expect(spy.historyReads, 2);
    expect(rig.errors, isEmpty);
  });

  test('read-only that lands just before a write starts wins', () async {
    rig = await Rig.create(
      permission: AiPermission.auto,
      script: [
        replies('', calls: [toolCall('write_a')]),
        replies('done'),
      ],
    );
    var reads = 0;
    // Read twice per step once the card exists: the pump's decision, then the
    // batch's own read, which comes after the batch took its snapshot.
    rig.env.onPlugin = () async {
      if ((await rig.cards()).isEmpty) return;
      if (++reads == 2) {
        await rig.store.setPermission(rig.conv.id, AiPermission.readOnly);
      }
    };

    await rig.send('go');

    expect(rig.tool('write_a').runs, isEmpty);
    final cards = await rig.cards();
    expect(cardStates(cards), ['write_a:skipped']);
    expect(resultText(cards.single), contains('not run'));
  });

  group('the last error card', () {
    test('goes when a retry starts', () async {
      rig = await Rig.create(
        script: [
          (_) async => const RunFailed(RunFailReason.internal),
          replies('fine'),
        ],
      );
      await rig.send('go');
      expect(rig.driver.turnState, TurnState.error);
      expect(rig.driver.lastView, isNotNull);

      final r = await rig.driver.retry() as DriverStarted;
      await r.done;

      expect(rig.driver.turnState, TurnState.idle);
      expect(rig.driver.lastView, isNull);
    });

    test('is the app error card when the flight itself failed', () async {
      rig = await Rig.create();
      rig.env.onPlugin = () async => throw StateError('boom');

      await rig.send('go');

      expect(rig.driver.turnState, TurnState.error);
      expect(rig.driver.lastView?.card, ChatCardKind.server);
      expect(rig.errors.single, isA<StateError>());
    });
  });

  test(
    'an Allow on a card past 24 hours expires it and the turn goes on',
    () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a')]),
          replies('after expiry'),
        ],
      );
      await rig.send('go');
      final id = callIdOf((await rig.cards()).single);
      rig.clock = () => DateTime.now().add(const Duration(hours: 25));

      expect(await rig.driver.allow(id), CardAnswer.expired);
      await rig.driver.inFlight;

      expect(rig.tool('write_a').runs, isEmpty);
      expect(cardStates(await rig.cards()), ['write_a:skipped']);
      expect(rig.runner.runs, 2);
      expect(rig.driver.turnState, TurnState.idle);
    },
  );

  test(
    'a call left running in this session becomes unknown on retry',
    () async {
      rig = await Rig.create(script: [replies('carry on')]);
      final cards = await rig.seedRound(['read_a']);
      await rig.store.transition(
        cards.single.id,
        from: AiMessageState.allowed,
        to: AiMessageState.running,
      );

      final r = await rig.driver.retry() as DriverStarted;
      await r.done;

      expect(cardStates(await rig.cards()), ['read_a:unknown']);
      expect(rig.runner.runs, 1);
      expect(rig.driver.turnState, TurnState.idle);
    },
  );
}
