import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/loop_store_adapter.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_driver.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';

import 'loop_fixtures.dart';

/// A store whose open-cards read can be held (the set-up of a send) and
/// whose user-message write can fail.
class _HookedStore extends LoopStoreAdapter {
  _HookedStore(super.store);

  Completer<void>? holdOpenCards;
  Completer<void>? reachedOpenCards;
  bool failAppendUser = false;

  @override
  Future<List<AiMessage>> openCards(int conversationId) async {
    final hold = holdOpenCards;
    if (hold != null) {
      holdOpenCards = null;
      reachedOpenCards?.complete();
      await hold.future;
    }
    return super.openCards(conversationId);
  }

  @override
  Future<int> appendUser(int conversationId, List<AiPart> parts) {
    if (failAppendUser) throw StateError('write failed');
    return super.appendUser(conversationId, parts);
  }
}

void main() {
  late Rig rig;
  tearDown(() => rig.dispose());

  /// Calls the driver from outside any switch body, the way the UI does.
  Future<void> stopFromOutside() => rig.driver.stop();

  Future<_HookedStore> hooked() async {
    final spy = _HookedStore(rig.store);
    await rig.driver.dispose();
    rig.driver = LoopDriver(
      conversationId: rig.conv.id,
      store: spy,
      runner: rig.runner,
      env: rig.env,
      newBoundary: () => 'kfixedbound',
      onInternalError: (e, s) => rig.errors.add(e),
    );
    return spy;
  }

  test(
    'Stop during a switch with no turn leaves the next send normal',
    () async {
      rig = await Rig.create(script: [replies('hello')]);
      late Future<void> stopped;
      await rig.driver.runExclusive(() async {
        stopped = stopFromOutside();
      });
      await stopped;
      expect(rig.driver.turnState, TurnState.idle);

      await rig.send('hi');

      expect(rig.runner.runs, 1);
      expect(rig.driver.turnState, TurnState.idle);
      expect(rig.errors, isEmpty);
    },
  );

  group('Stop while a send sets up', () {
    test('starts no round and the next send runs', () async {
      rig = await Rig.create(script: [replies('first'), replies('second')]);
      final spy = await hooked();
      final hold = Completer<void>();
      spy
        ..holdOpenCards = hold
        ..reachedOpenCards = Completer<void>();

      final start = rig.driver.send([const TextPart('one')]);
      await spy.reachedOpenCards!.future;
      final stopped = rig.driver.stop();
      hold.complete();
      final result = await start;
      await stopped;
      if (result is DriverStarted) await result.done;

      expect(rig.runner.runs, 0);
      expect(rig.driver.turnState, TurnState.idle);

      await rig.send('two');
      expect(rig.runner.runs, 1);
      expect(rig.errors, isEmpty);
    });

    test('with a failing user-message write, stop returns and the next '
        'send runs', () async {
      rig = await Rig.create(script: [replies('after')]);
      final spy = await hooked();
      final hold = Completer<void>();
      spy
        ..holdOpenCards = hold
        ..reachedOpenCards = Completer<void>()
        ..failAppendUser = true;

      final start = rig.driver.send([const TextPart('one')]);
      await spy.reachedOpenCards!.future;
      final stopped = rig.driver.stop();
      hold.complete();

      expect(await start, isA<DriverFailed>());
      await stopped;
      expect(rig.driver.turnState, TurnState.idle);

      spy.failAppendUser = false;
      await rig.send('two');
      expect(rig.runner.runs, 1);
      expect(rig.driver.turnState, TurnState.idle);
    });
  });

  test('Stop and dispose inside a switch body leave the cards pending and '
      'hang nothing', () async {
    rig = await Rig.create(
      script: [
        replies('', calls: [toolCall('write_a')]),
      ],
    );
    await rig.send('go');
    late Future<void> stopped;
    late Future<void> disposed;
    await rig.driver.runExclusive(() async {
      stopped = stopFromOutside();
      disposed = rig.driver.dispose();
    });
    await stopped;
    await disposed;

    expect(cardStates(await rig.cards()), ['write_a:pending']);
    expect(rig.runner.runs, 1);
    expect(rig.errors, isEmpty);
  });

  test('Allow, Stop, then an exception in the switch body: the Stop wins and '
      'the exception reaches the caller', () async {
    rig = await Rig.create(
      script: [
        replies('', calls: [toolCall('write_a')]),
        replies('unexpected second round'),
      ],
    );
    await rig.send('go');
    final id = (await rig.cards()).single.parts
        .whereType<ToolCallPart>()
        .first
        .id;
    late Future<void> stopped;

    await expectLater(
      rig.driver.runExclusive<void>(() async {
        expect(await rig.driver.allow(id), CardAnswer.accepted);
        stopped = stopFromOutside();
        throw StateError('body failed');
      }),
      throwsA(isA<StateError>()),
    );
    await stopped;
    await rig.driver.inFlight;

    expect(rig.runner.runs, 1);
    expect(rig.tool('write_a').runs, isEmpty);
    expect(cardStates(await rig.cards()), ['write_a:skipped']);
    expect(rig.driver.turnState, TurnState.idle);
  });
}
