import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/data/run/run_gate.dart';

import '../data/install_test_support.dart' show turns;

void main() {
  late RunGate gate;
  setUp(() => gate = RunGate(exclusiveWait: const Duration(milliseconds: 150)));

  test('shared leases of one plugin run together', () async {
    final a = (await gate.enter('p'))!;
    final b = (await gate.enter('p'))!;
    expect(gate.isClosed('p'), isFalse);
    a.release();
    b.release();
  });

  test('exclusive cancels the runs in flight and waits for them', () async {
    final lease = (await gate.enter('p'))!;
    var changed = false;
    lease.changed.listen(() => changed = true);
    var ran = false;
    final exclusive = gate.exclusive('p', () async => ran = true);
    await turns();
    expect(changed, isTrue);
    expect(ran, isFalse, reason: 'the run has not ended yet');

    lease.release();
    await exclusive;
    expect(ran, isTrue);
  });

  test('exclusive goes on after the bounded wait', () async {
    final stuck = (await gate.enter('p'))!;
    final watch = Stopwatch()..start();
    await gate.exclusive('p', () async {});
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(140));
    expect(watch.elapsedMilliseconds, lessThan(1000));
    stuck.release();
    expect(gate.isClosed('p'), isFalse);
  });

  test('a shared lease asked during exclusive waits for the reopen', () async {
    final hold = Completer<void>();
    final started = Completer<void>();
    final exclusive = gate.exclusive('p', () async {
      started.complete();
      await hold.future;
    });
    await started.future;
    final order = <String>[];
    final lease = gate.enter('p').then((l) {
      order.add('lease');
      return l!;
    });
    await turns();
    expect(order, isEmpty);

    order.add('switch done');
    hold.complete();
    await exclusive;
    (await lease).release();
    expect(order, ['switch done', 'lease']);
  });

  test('a waiting run is freed by its own cancel', () async {
    final hold = Completer<void>();
    final exclusive = gate.exclusive('p', () => hold.future);
    await turns();
    final cancel = RunCancel();
    final waiting = gate.enter('p', cancel: cancel);
    await turns();
    cancel.cancel();
    expect(await waiting, isNull);
    hold.complete();
    await exclusive;
    expect(gate.isClosed('p'), isFalse);
  });

  test('other plugins are unaffected', () async {
    final mine = (await gate.enter('p'))!;
    final other = (await gate.enter('q'))!;
    final hold = Completer<void>();
    final exclusive = gate.exclusive('p', () => hold.future);
    await turns();

    expect(mine.changed.isCancelled, isTrue);
    expect(other.changed.isCancelled, isFalse);
    expect(gate.isClosed('q'), isFalse);
    expect(await gate.enter('q'), isNotNull);
    mine.release();
    hold.complete();
    await exclusive;
    other.release();
  });

  test('a listener that throws does not stop the other runs', () async {
    final first = (await gate.enter('p'))!;
    final second = (await gate.enter('p'))!;
    first.changed.listen(() => throw StateError('bad listener'));
    var stopped = false;
    second.changed.listen(() => stopped = true);
    final exclusive = gate.exclusive('p', () async {});
    await turns();
    first.release();
    second.release();
    await exclusive;
    expect(stopped, isTrue);
    expect(gate.isClosed('p'), isFalse);
  });

  test('the gate reopens when the action throws', () async {
    await expectLater(
      gate.exclusive<void>('p', () async => throw StateError('x')),
      throwsStateError,
    );
    expect(gate.isClosed('p'), isFalse);
    expect(await gate.enter('p'), isNotNull);
  });

  test('two exclusive leases keep the id closed until both end', () async {
    final h1 = Completer<void>();
    final h2 = Completer<void>();
    final first = gate.exclusive('p', () => h1.future);
    final second = gate.exclusive('p', () => h2.future);
    await turns();
    h1.complete();
    await first;
    expect(gate.isClosed('p'), isTrue);
    h2.complete();
    await second;
    expect(gate.isClosed('p'), isFalse);
  });
}
