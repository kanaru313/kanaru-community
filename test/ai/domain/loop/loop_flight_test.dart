import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
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

/// Runs [onOpenCards] once, right after the open cards were read (the stop
/// branch of the pump), and still returns what was read before it.
class _AnswerAfterRead extends LoopStoreAdapter {
  _AnswerAfterRead(super.store);

  Future<void> Function()? onOpenCards;

  @override
  Future<List<AiMessage>> openCards(int conversationId) async {
    final rows = await super.openCards(conversationId);
    final hook = onOpenCards;
    onOpenCards = null;
    await hook?.call();
    return rows;
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

  group('an answer that lands while runExclusive holds the gate', () {
    test('Allow runs the call after the release', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a')]),
          replies('done'),
        ],
      );
      await rig.send('go');
      final id = callIdOf((await rig.cards()).single);
      final entered = Completer<void>();
      final release = Completer<void>();
      final run = rig.driver.runExclusive(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;

      expect(await rig.driver.allow(id), CardAnswer.accepted);
      expect(rig.tool('write_a').runs, isEmpty);
      release.complete();
      await run;
      await rig.driver.inFlight;

      expect(rig.tool('write_a').runs, hasLength(1));
      expect(cardStates(await rig.cards()), ['write_a:done']);
      expect(rig.runner.runs, 2);
      expect(rig.driver.turnState, TurnState.idle);
    });

    test('Deny tells the model after the release', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a')]),
          replies('understood'),
        ],
      );
      await rig.send('go');
      final id = callIdOf((await rig.cards()).single);
      final entered = Completer<void>();
      final release = Completer<void>();
      final run = rig.driver.runExclusive(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;

      expect(await rig.driver.deny(id), CardAnswer.accepted);
      release.complete();
      await run;
      await rig.driver.inFlight;

      expect(rig.tool('write_a').runs, isEmpty);
      expect(cardStates(await rig.cards()), ['write_a:skipped']);
      expect(rig.runner.runs, 2);
      expect(rig.driver.turnState, TurnState.idle);
    });
  });

  group('a flight started by one answer, then a stop', () {
    // Two cards; Allow on the first starts a flight, held where it reads the
    // plugin, before it parks or runs. The stop lands there.
    Future<Future<void> Function()> held() async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
        ],
      );
      await rig.send('go');
      final id = callIdOf((await rig.cards()).first);
      final reached = Completer<void>();
      final release = Completer<void>();
      rig.env.onPlugin = () async {
        rig.env.onPlugin = null;
        reached.complete();
        await release.future;
      };
      expect(await rig.driver.allow(id), CardAnswer.accepted);
      await reached.future;
      return () async => release.complete();
    }

    test('from a switch leaves the other cards pending', () async {
      final release = await held();
      final exclusive = rig.driver.runExclusive(() async {});
      await release();
      await exclusive;

      expect(cardStates(await rig.cards()), [
        'write_a:skipped',
        'write_b:pending',
      ]);
      expect(rig.tool('write_a').runs, isEmpty);
      expect(rig.driver.turnState, TurnState.awaitingConfirm);
    });

    for (final deny in [false, true]) {
      test('from a switch, ${deny ? 'a Deny' : 'an Allow'} that lands in the '
          'stop branch is not lost', () async {
        rig = await Rig.create(
          script: [
            replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
            replies('understood'),
          ],
        );
        final spy = _AnswerAfterRead(rig.store);
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
        final cards = await rig.cards();
        final first = callIdOf(cards.first);
        final second = callIdOf(cards.last);
        final reached = Completer<void>();
        final release = Completer<void>();
        rig.env.onPlugin = () async {
          rig.env.onPlugin = null;
          reached.complete();
          await release.future;
        };
        expect(await rig.driver.allow(first), CardAnswer.accepted);
        await reached.future;
        spy.onOpenCards = () async {
          final answer = deny
              ? await rig.driver.deny(second)
              : await rig.driver.allow(second);
          expect(answer, CardAnswer.accepted);
        };

        final exclusive = rig.driver.runExclusive(() async {});
        release.complete();
        await exclusive;
        await rig.driver.inFlight;

        expect(rig.tool('write_a').runs, isEmpty);
        if (deny) {
          expect(rig.tool('write_b').runs, isEmpty);
          expect(cardStates(await rig.cards()), [
            'write_a:skipped',
            'write_b:skipped',
          ]);
          expect(rig.runner.runs, 2);
        } else {
          expect(rig.tool('write_b').runs, hasLength(1));
          expect(cardStates(await rig.cards()), [
            'write_a:skipped',
            'write_b:done',
          ]);
        }
        expect(rig.errors, isEmpty);
      });
    }

    test('from the user denies them', () async {
      final release = await held();
      final stopped = rig.driver.stop();
      await release();
      await stopped;

      expect(cardStates(await rig.cards()), [
        'write_a:skipped',
        'write_b:skipped',
      ]);
      expect(rig.driver.turnState, TurnState.idle);
    });
  });

  group('an answer recorded around a stop', () {
    Future<(String, String, Future<void> Function())> twoCardsHeld() async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
          replies('unexpected second round'),
        ],
      );
      await rig.send('go');
      final cards = await rig.cards();
      final reached = Completer<void>();
      final release = Completer<void>();
      rig.env.onPlugin = () async {
        rig.env.onPlugin = null;
        reached.complete();
        await release.future;
      };
      final a = callIdOf(cards.first);
      final b = callIdOf(cards.last);
      expect(await rig.driver.allow(a), CardAnswer.accepted);
      await reached.future;
      return (a, b, () async => release.complete());
    }

    test(
      'a user Stop drops an Allow that landed while the flight ran',
      () async {
        final (_, b, release) = await twoCardsHeld();
        expect(await rig.driver.allow(b), CardAnswer.accepted);
        final stopped = rig.driver.stop();
        await release();
        await stopped;
        await rig.driver.inFlight;
        await settle();

        expect(rig.runner.runs, 1);
        expect(rig.tool('write_b').runs, isEmpty);
        expect(cardStates(await rig.cards()), [
          'write_a:skipped',
          'write_b:skipped',
        ]);
        expect(rig.driver.turnState, TurnState.idle);
      },
    );

    test(
      'the parked stop starts no round for a Deny that lands in it',
      () async {
        rig = await Rig.create(
          script: [
            replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
            replies('unexpected second round'),
          ],
        );
        final spy = _AnswerAfterRead(rig.store);
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
        final second = callIdOf((await rig.cards()).last);
        spy.onOpenCards = () async {
          expect(await rig.driver.deny(second), CardAnswer.accepted);
        };

        await rig.driver.stop();
        await rig.driver.inFlight;
        await settle();

        expect(rig.runner.runs, 1);
        expect(rig.driver.turnState, TurnState.idle);
        expect(rig.errors, isEmpty);
      },
    );

    test(
      'a switch that ends the turn starts no round for an earlier Allow',
      () async {
        final (_, b, release) = await twoCardsHeld();
        expect(await rig.driver.allow(b), CardAnswer.accepted);
        final exclusive = rig.driver.runExclusive(() async {});
        await release();
        await exclusive;
        await rig.driver.inFlight;
        await settle();

        expect(rig.runner.runs, 1);
        expect(rig.tool('write_b').runs, isEmpty);
        expect(rig.driver.turnState, TurnState.idle);
      },
    );

    test('two queued switches: the Allow runs after the last one', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a'), toolCall('write_b')]),
          replies('done'),
        ],
      );
      final spy = _AnswerAfterRead(rig.store);
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
      final cards = await rig.cards();
      final reached = Completer<void>();
      final release = Completer<void>();
      rig.env.onPlugin = () async {
        rig.env.onPlugin = null;
        reached.complete();
        await release.future;
      };
      expect(
        await rig.driver.allow(callIdOf(cards.first)),
        CardAnswer.accepted,
      );
      await reached.future;
      final second = callIdOf(cards.last);
      spy.onOpenCards = () async {
        expect(await rig.driver.allow(second), CardAnswer.accepted);
      };

      final first = rig.driver.runExclusive(() async {});
      final next = rig.driver.runExclusive(() async {});
      release.complete();
      await first;
      await next;
      await rig.driver.inFlight;
      await settle();

      expect(rig.tool('write_b').runs, hasLength(1));
      expect(cardStates(await rig.cards()), [
        'write_a:skipped',
        'write_b:done',
      ]);
      expect(rig.errors, isEmpty);
    });

    test('stop after dispose leaves the pending cards pending', () async {
      rig = await Rig.create(
        script: [
          replies('', calls: [toolCall('write_a')]),
        ],
      );
      await rig.send('go');
      await rig.driver.dispose();
      await rig.driver.stop();

      expect(cardStates(await rig.cards()), ['write_a:pending']);
    });
  });

  test('a lost start before a stop does not count in the next turn', () async {
    rig = await Rig.create(script: [replies('second turn')]);
    Future<void>? stopped;
    // Turn one: a row lands before the first round (a lost start), then the
    // user stops. Turn two: one more lost start must be retried once and end
    // in a reply, not in the error card the earlier loss would have caused.
    var racing = false;
    // Reads left before the stop: the lost start is retried once first.
    var readsBeforeStop = 0;
    Future<void> race() => rig.store.append(
      NewAiMessage(
        conversationId: rig.conv.id,
        role: AiMessageRole.user,
        parts: const [TextPart('raced')],
      ),
    );
    rig.env.onPlugin = () async {
      if (racing) {
        racing = false;
        await race();
      } else if (readsBeforeStop > 0 && --readsBeforeStop == 0) {
        stopped = rig.driver.stop();
      }
    };

    racing = true;
    readsBeforeStop = 3;
    await rig.send('one');
    await stopped;
    expect(rig.runner.runs, 0);
    racing = true;
    await rig.send('two');

    expect(rig.runner.runs, 1);
    expect(rig.driver.turnState, TurnState.idle);
    expect(rig.driver.lastView, isNull);
    expect((await rig.rows()).last.state, AiMessageState.complete);
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
