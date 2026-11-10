import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/state/command_chain.dart';

void main() {
  test('tasks run one after another in call order', () async {
    final chain = SerialChain();
    final log = <String>[];
    final gate = Completer<void>();
    final a = chain.run(() async {
      log.add('a start');
      await gate.future;
      log.add('a end');
    });
    final b = chain.run(() async => log.add('b'));
    await pumpEventQueue();
    expect(log, ['a start']);
    gate.complete();
    await Future.wait([a, b]);
    expect(log, ['a start', 'a end', 'b']);
  });

  test('an error fails only its own task', () async {
    final chain = SerialChain();
    final bad = chain.run<void>(() async => throw StateError('x'));
    final ok = chain.run(() async => 7);
    await expectLater(bad, throwsStateError);
    expect(await ok, 7);
  });

  test(
    'the drain runs once after a burst, after the results complete',
    () async {
      var drains = 0;
      final chain = SerialChain(onDrain: () async => drains++);
      final done = <int>[];
      final futures = [
        for (var i = 0; i < 10; i++) chain.run(() async => i).then(done.add),
      ];
      await Future.wait(futures);
      await chain.whenIdle();
      expect(done, hasLength(10));
      expect(drains, 1);
      await chain.run(() async {});
      await chain.whenIdle();
      expect(drains, 2);
    },
  );

  test('a command future completes while the drain is still busy', () async {
    final gate = Completer<void>();
    final chain = SerialChain(onDrain: () => gate.future);
    await chain.run(() async {}); // completes although the drain waits
    final later = chain.run(() async => 1);
    var done = false;
    unawaited(later.then((_) => done = true));
    await pumpEventQueue();
    expect(done, isFalse, reason: 'queued behind the drain');
    gate.complete();
    expect(await later, 1);
  });

  test('running a task from inside a task asserts', () async {
    final chain = SerialChain();
    await expectLater(
      chain.run(() async {
        chain.run(() async {});
      }),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a closed chain refuses tasks but finishes queued ones', () async {
    final chain = SerialChain();
    final first = chain.run(() async => 1);
    final closing = chain.close();
    await expectLater(chain.run(() async => 2), throwsStateError);
    expect(await first, 1);
    await closing;
  });
}
