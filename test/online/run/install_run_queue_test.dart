import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/data/run/install_run_queue.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';

void main() {
  late InstallRunQueue queue;
  setUp(() => queue = InstallRunQueue());

  test('bodies of one install never overlap', () async {
    var active = 0;
    var most = 0;
    final gates = [Completer<void>(), Completer<void>(), Completer<void>()];
    final results = [
      for (var i = 0; i < 3; i++)
        queue.run('a', () async {
          active++;
          if (active > most) most = active;
          await gates[i].future;
          active--;
          return i;
        }),
    ];
    for (final g in gates) {
      await pumpEventQueue();
      expect(active, 1);
      g.complete();
    }
    expect(await Future.wait(results), [0, 1, 2]);
    expect(most, 1);
  });

  test('two installs run at once', () async {
    final gate = Completer<void>();
    var started = 0;
    final a = queue.run('a', () async {
      started++;
      await gate.future;
    });
    final b = queue.run('b', () async {
      started++;
      await gate.future;
    });
    await pumpEventQueue();
    expect(started, 2);
    gate.complete();
    await Future.wait([a, b]);
  });

  test(
    'priority goes ahead of normal waiters, behind the body in flight',
    () async {
      final order = <String>[];
      final gate = Completer<void>();
      final first = queue.run('a', () async {
        order.add('first');
        await gate.future;
      });
      final normal = queue.run('a', () async => order.add('normal'));
      final p1 = queue.run('a', () async => order.add('p1'), priority: true);
      final p2 = queue.run('a', () async => order.add('p2'), priority: true);
      await pumpEventQueue();
      expect(order, ['first']);
      gate.complete();
      await Future.wait([first, normal, p1, p2]);
      expect(order, ['first', 'p1', 'p2', 'normal']);
    },
  );

  test(
    'cancel while waiting: null, body never called, queue moves on',
    () async {
      final gate = Completer<void>();
      final first = queue.run('a', () => gate.future);
      final cancel = RunCancel();
      var ran = false;
      final waiting = queue.run('a', () async => ran = true, cancel: cancel);
      var third = false;
      final next = queue.run('a', () async => third = true);
      await pumpEventQueue();
      cancel.cancel();
      expect(await waiting, isNull);
      gate.complete();
      await Future.wait([first, next]);
      expect(ran, isFalse);
      expect(third, isTrue);
      expect(cancel.listenerCount, 0);
    },
  );

  test('an already cancelled token never runs', () async {
    final cancel = RunCancel()..cancel();
    var ran = false;
    expect(
      await queue.run('a', () async => ran = true, cancel: cancel),
      isNull,
    );
    expect(ran, isFalse);
    expect(queue.isIdle('a'), isTrue);
  });

  test('a throwing body rethrows and frees the slot', () async {
    final failing = queue.run<int>('a', () async => throw StateError('x'));
    final after = queue.run('a', () async => 7);
    await expectLater(failing, throwsStateError);
    expect(await after, 7);
  });

  test('map is empty after everything finished', () async {
    expect(queue.isIdle('a'), isTrue);
    final f = queue.run('a', () async => 1);
    expect(queue.isIdle('a'), isFalse);
    await f;
    expect(queue.isIdle('a'), isTrue);
    final c = RunCancel();
    final gate = Completer<void>();
    final held = queue.run('a', () => gate.future);
    final w = queue.run('a', () async {}, cancel: c);
    c.cancel();
    await w;
    gate.complete();
    await held;
    expect(queue.isIdle('a'), isTrue);
  });
}
